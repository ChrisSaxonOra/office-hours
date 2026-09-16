@sql-atoh-202305-setup

/* Release timestamp table */
create table app_version_deployments (
  major_version     int not null,
  minor_version     int not null,
  release_timestamp timestamp(0) not null,
  notes             varchar2(1000),
  primary key ( major_version, minor_version )
);

/* Virtualize start-end dates */
create or replace view app_version_history_v as 
  select major_version, minor_version, 
         release_timestamp start_timestamp,
         lead ( release_timestamp ) 
           over ( order by release_timestamp ) end_timestamp,
         notes
  from   app_version_deployments;





/* Store start-end dates */
create table app_version_history (
  major_version   int not null,
  minor_version   int not null,
  start_timestamp timestamp(0) not null,
  end_timestamp   timestamp(0),
  notes           varchar2(1000),
  primary key ( major_version, minor_version ),
  constraint apvh_start_end_c 
    check ( start_timestamp < end_timestamp )
);





/* Load the data */
insert into app_version_deployments
with rws as (
  select level x 
  from   dual
  connect by level <= 10
)
 select major, minor, 
    timestamp'2023-02-01 00:00:00' +
      numtodsinterval ( rn, 'day' ) +
      numtodsinterval ( dbms_random.value ( 0, 1440 ), 'minute' ),
       rpad ( 'notes', 500, 's' )
 from (
  select r1.x major, r2.x minor,
    row_number () over ( order by r1.x, r2.x ) rn 
  from rws r1 cross join rws r2
 ) 
 order by 1, 2;

insert into app_version_history
  select * from app_version_history_v;

commit;



/* Check the data */
select * from app_version_deployments
order  by release_timestamp desc;  

select * from app_version_history_v
order  by start_timestamp desc;

select * from app_version_history
order  by start_timestamp desc;







/* Changes - new version */
insert into app_version_deployments 
values ( 11, 1, systimestamp, 'latest release' );

select * from app_version_deployments
order  by release_timestamp desc;  

select * from app_version_history_v
order  by start_timestamp desc;  




/* Start-end dates; update & insert */
declare
  --to ensure end = start
  end_ts timestamp := systimestamp;
begin 
  update app_version_history
  set    end_timestamp = end_ts
  where  end_timestamp is null;

  insert into app_version_history 
  values ( 11, 1, end_ts, null, 'latest release' );
end;
/


select * from app_version_history
order  by start_timestamp desc;






/* Changes - missed previous version */
insert into app_version_deployments 
values ( 10, 11, systimestamp - 1, 'missing release' );

select * from app_version_deployments
order  by release_timestamp desc;  

select * from app_version_history_v
order  by start_timestamp desc;  



declare
  --to ensure end = start
  release_ts timestamp := systimestamp - 1;
  end_ts timestamp;
begin 
  select end_timestamp
  into   end_ts
  from   app_version_history
  where  release_ts >= start_timestamp 
  and    release_ts < end_timestamp
  for update; --nowait

  update app_version_history
  set    end_timestamp = release_ts
  where  release_ts >= start_timestamp 
  and    release_ts < end_timestamp;
  
  insert into app_version_history 
  values ( 10, 11, release_ts, end_ts, 'missing release' );
end;
/

/* Check data */
select * from app_version_history
order  by start_timestamp desc;







/* We know the current release will end in the future
   Just not what's coming next! */
update app_version_history
set    end_timestamp = systimestamp + 1
where  end_timestamp is null;

select * from app_version_history
order  by start_timestamp desc
fetch  first 2 rows only;

insert into app_version_deployments 
values ( 99, 99, systimestamp + 1, 'FINAL' );

select * from app_version_history_v
order  by start_timestamp desc
fetch  first 3 rows only;



rollback;



/***********************************




***********************************/

/* Current dates NULL vs magic value */
create or replace view app_version_history_v as 
  select major_version, minor_version, 
         release_timestamp start_timestamp,
         lead ( release_timestamp ) 
           over ( order by release_timestamp ) end_timestamp_null,
         lead ( release_timestamp, 1, timestamp'9999-12-31 23:59:59' ) 
           over ( order by release_timestamp ) end_timestamp_date,
         notes
  from   app_version_deployments;


/* Get the current release */
select * from app_version_history_v
where  end_timestamp_null is null;

select * from app_version_history_v
where  cast ( systimestamp as timestamp ) >= start_timestamp 
and    cast ( systimestamp as timestamp ) < end_timestamp_date;



/* Get the release N days ago */
select * from app_version_history_v
where  cast ( systimestamp as timestamp ) - 30 >= start_timestamp 
and    cast ( systimestamp as timestamp ) - 30 < nvl ( end_timestamp_null, systimestamp + interval '1' day );

select * from app_version_history_v
where  cast ( systimestamp as timestamp ) - 30 >= start_timestamp 
and    cast ( systimestamp as timestamp ) - 30 < end_timestamp_date;






/* Are there releases scheduled to end in the future? */
select * from app_version_history_v
where  end_timestamp_null > sysdate;

select * from app_version_history_v
where  end_timestamp_date > sysdate;








/* Get latest end date & duration */ 
select max ( end_timestamp_null ) en_ts_nulls, 
       max ( end_timestamp_date ) en_ts_magic, 
       max ( end_timestamp_null ) - min ( start_timestamp ) time_active_nulls,
       max ( end_timestamp_date ) - min ( start_timestamp ) time_active_magic
from   app_version_history_v;







/* Temporal validity handles nulls! */ 
alter table app_version_history
  add period for active_release 
  ( start_timestamp, end_timestamp );

select * from app_version_history
  as of period for active_release cast ( systimestamp as timestamp );
/* Check plan */


select * from app_version_history
  as of period for active_release cast ( systimestamp as timestamp ) - 30;
  
/* Find the changes between dates */
select * from app_version_history
  versions period for active_release between 
  cast ( systimestamp as timestamp ) - 30 and cast ( systimestamp as timestamp );





/* Temporal validity only on tables, not views */
alter table app_version_history_v
  add period for active_release 
  ( start_timestamp, end_timestamp_null );




/************************************




************************************/

/* Performance comparisons */
/* Reset view */
create or replace view app_version_history_v as 
  select major_version, minor_version, 
         release_timestamp start_timestamp,
         lead ( release_timestamp ) 
           over ( order by release_timestamp ) end_timestamp,
         notes
  from   app_version_deployments;


/* Load more (past) data to test performance */
insert into app_version_deployments
with rws as (
  select level x 
  from   dual
  connect by level <= 100
)
 select -major, -minor, 
    timestamp'2023-01-01 00:00:00' -
      numtodsinterval ( rn, 'day' ) -
      numtodsinterval ( dbms_random.value ( 0, 1440 ), 'minute' ),
       rpad ( 'notes', 500, 's' )
 from (
  select r1.x major, r2.x minor,
    row_number () over ( order by r1.x desc, r2.x desc ) rn 
  from rws r1 cross join rws r2
 ) 
 order by 1 desc, 2 desc;

insert into app_version_history
  select * from app_version_history_v
  where  major_version < 1;
  
create index apvd_release_ts_i
  on app_version_deployments ( release_timestamp );

create index apvh_release_start_end_i
  on app_version_history ( start_timestamp, end_timestamp );

exec dbms_stats.gather_table_stats ( user, 'app_version_deployments' ) ;
exec dbms_stats.gather_table_stats ( user, 'app_version_history' ) ;



/* Basic query performance - get execution plans */
select * from app_version_history
  as of period for active_release cast ( systimestamp as timestamp );
  
select * from app_version_history_v
where  cast ( systimestamp as timestamp ) >= start_timestamp 
and    cast ( systimestamp as timestamp ) < end_timestamp;






/* Compare (start, end) vs (end, start) indexes */
select * from app_version_history 
  as of period for active_release cast ( systimestamp as timestamp ) h;

alter index apvh_release_start_end_i invisible;
create index apvh_release_end_start_i
  on app_version_history ( end_timestamp, start_timestamp );

/* End TS is first; this only finds one entry => more efficient */
select * from app_version_history
  as of period for active_release cast ( systimestamp as timestamp ) h;

/* Less efficient as we search for older dates */
select * from app_version_history
  as of period for active_release cast ( systimestamp - 5050 as timestamp ) h;





/* Improving release date query performance */
select * from app_version_history_v
where  cast ( systimestamp as timestamp ) >= start_timestamp 
and    cast ( systimestamp as timestamp ) < end_timestamp;



/* MV? Can't be fast refreshable! */
create materialized view log 
  on app_version_deployments
  with rowid ( release_timestamp )
  including new values;
  
create materialized view app_version_history_mv
refresh fast on commit
as 
  select * from app_version_history_v;
  
  
create materialized view app_version_history_mv
as 
  select major_version, minor_version, 
         release_timestamp start_timestamp,
         lead ( release_timestamp ) 
           over ( order by release_timestamp ) end_timestamp,
         notes
  from   app_version_deployments;

truncate table mv_capabilities_table;
exec dbms_mview.explain_mview('app_version_history_mv');
select capability_name, possible, msgtxt from mv_capabilities_table
where  capability_name like 'REFRESH%';





/* Subquery is an index-only (min/max) scan */
select * from app_version_deployments
where  release_timestamp = (
  select max ( release_timestamp )
  from   app_version_deployments
  where  cast ( systimestamp as timestamp ) >= release_timestamp 
);







/* Beware! Only helps when NOT fetching end date */
select * from app_version_history_v
where  start_timestamp = (
  select max ( release_timestamp )
  from   app_version_deployments
  where  cast ( systimestamp as timestamp ) >= release_timestamp 
);






/* Can use scalar subquery instead */
select major_version, minor_version,
       release_timestamp st_ts,
       (  select min ( release_timestamp )
          from   app_version_deployments a
          where  a.release_timestamp > d.release_timestamp 
       ) en_ts
from   app_version_deployments d
where  release_timestamp = (
  select max ( release_timestamp )
  from   app_version_deployments
  where  cast ( systimestamp as timestamp ) >= release_timestamp 
);



/* Efficient no matter how far back you look */
select major_version, minor_version,
       release_timestamp st_ts,
       (  select min ( release_timestamp )
          from   app_version_deployments a
          where  a.release_timestamp > d.release_timestamp 
       ) en_ts
from   app_version_deployments d
where  release_timestamp = (
  select max ( release_timestamp )
  from   app_version_deployments
  where  cast ( systimestamp - 5050 as timestamp ) >= release_timestamp 
);


select systimestamp, current_timestamp from dual;
alter session set time_zone = 'Europe/Berlin';



select * from app_version_history;