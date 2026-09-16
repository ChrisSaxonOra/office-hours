@C:\Users\csaxon\Documents\Scripts\sql-atoh-202009-setup-2

select to_char ( num_rows, '999,999,990' ) rws,
       bytes/1024/1024/1024 size_in_gb
from   user_segments us
join   user_tables ut
on     ut.table_name = us.segment_name
where  ut.table_name = 'BRICKS';


/* Slow query */
select trunc ( insert_datetime ), 
       colour, 
       count (*),
       sum ( weight )
from   bricks
where  trunc ( insert_datetime ) >= trunc ( sysdate ) - 7
group  by trunc ( insert_datetime ), colour;



/*
create index bric_date_i
  on bricks ( trunc ( insert_datetime ) )
*/
alter index bric_date_i
  visible;
  
  
  
  
select trunc ( insert_datetime ), 
       colour, 
       count (*),
       sum ( weight )
from   bricks
where  trunc ( insert_datetime ) >= trunc ( sysdate ) - 600
group  by trunc ( insert_datetime ), colour;


alter index bric_date_i
  invisible;
  
  
  
  
  
  
  
/*
create materialized view daily_brick_summary
as 
  select trunc ( insert_datetime ) insert_date, 
         colour,
         count (*) num_bricks,
         sum ( weight ) total_weight
  from   bricks
  group  by trunc ( insert_datetime ), colour;
*/
  
  
select * from daily_brick_summary
where  insert_date >= trunc ( sysdate ) - 7;




create index dabs_insert_date_i 
  on daily_brick_summary (
    insert_date
  );
  
select * from daily_brick_summary
where  insert_date >= trunc ( sysdate ) - 7;







/* How does this help this query? */
select trunc ( insert_datetime ), 
       colour, 
       count (*),
       sum ( weight )
from   bricks
where  trunc ( insert_datetime ) >= trunc ( sysdate ) - 7
group  by trunc ( insert_datetime ), colour;





/* The database can rewrite it for us! */
alter materialized view daily_brick_summary
  enable query rewrite;
  
select trunc ( insert_datetime ), 
       colour, 
       count (*),
       sum ( weight )
from   bricks
where  trunc ( insert_datetime ) >= trunc ( sysdate ) - 7
group  by trunc ( insert_datetime ), colour;





/* These all benefit from query rewrite */
select trunc ( insert_datetime ), 
       count (*)
from   bricks
group  by trunc ( insert_datetime );

select colour, 
       count (*)
from   bricks
group  by colour;

select count (*)
from   bricks;




/* Can also rewrite joins */
select trunc ( insert_datetime ), colour, count (*)
from   bricks b
join   colours c
on     b.colour = c.colour_name
where  trunc ( insert_datetime ) = trunc ( sysdate )
group  by trunc ( insert_datetime ), colour;





/* ...if it doesn't put MV query in a subquery */
with brick_summary as (
  select trunc ( insert_datetime ) ins_date, colour, count (*) c
  from   bricks b
  where  trunc ( insert_datetime ) = trunc ( sysdate )
  group  by trunc ( insert_datetime ), colour
)
select ins_date, colour, c
from   brick_summary b
join   colours c
on     b.colour = c.colour_name
where  ins_date = trunc ( sysdate );





/* But this doesn't */
select trunc ( insert_datetime ), 
       colour, 
       count (*),
       sum ( weight )
from   bricks
where  insert_datetime >= trunc ( sysdate ) - 7
group  by trunc ( insert_datetime ), colour;



/* Why the **** didn't it rewrite?! */




/* Check the explanation */
truncate table rewrite_table;
declare
  querytxt varchar2(1500) := q'|
select trunc ( insert_datetime ), 
       colour, 
       count (*),
       sum ( weight )
from   bricks
where  insert_datetime >= trunc ( sysdate ) - 7
group  by trunc ( insert_datetime ), colour|';
begin
  dbms_mview.explain_rewrite ( querytxt, 'daily_brick_summary' );
end;
/

select message
from   rewrite_table
order by sequence desc;






/* What happens when we change data? */
insert into bricks 
  values ( 0, sysdate, 'red', 'cylinder', 100 );
commit;
  
select count (*)
from   bricks;


truncate table rewrite_table;
declare
  querytxt varchar2(1500) := q'|
select count (*)
from   bricks|';
begin
  dbms_mview.explain_rewrite ( querytxt, 'daily_brick_summary' );
end;
/

select message
from   rewrite_table
order by sequence desc;


select staleness
from   user_mviews
where  mview_name = 'DAILY_BRICK_SUMMARY';






/* Allow the query to use out-of-date data */
alter session set query_rewrite_integrity = stale_tolerated;

select count (*)
from   bricks;






/* Reset to continue */
alter session set query_rewrite_integrity = enforced;





/* Bring MV back up-to-date */
exec dbms_mview.refresh ( 'daily_brick_summary' );

select count (*)
from   bricks;






/* Can capture incremental changes with an MV log */
create materialized view log 
  on bricks
  with primary key, rowid, sequence, commit scn ( 
    colour, shape, weight, insert_datetime
  )
  including new values;
  
exec dbms_mview.refresh ( 'daily_brick_summary' );
  
alter materialized view daily_brick_summary
  refresh fast on commit;

select staleness, refresh_mode, refresh_method
from   user_mviews
where  mview_name = 'DAILY_BRICK_SUMMARY';

select * from daily_brick_summary
where  insert_date = trunc ( sysdate );  


delete bricks
where  brick_id = 0;

select * from mlog$_bricks;

commit;

select staleness, refresh_mode, refresh_method
from   user_mviews
where  mview_name = 'DAILY_BRICK_SUMMARY';


select * from mlog$_bricks;

select * from daily_brick_summary
where  insert_date = trunc ( sysdate );






/* What if MV refresh adds too much overhead?! */
alter materialized view daily_brick_summary
  refresh fast on demand;
  
  
  
  
  

/* Apply log changes at runtime! */  
alter materialized view daily_brick_summary
  enable on query computation;
  
exec dbms_mview.refresh ( 'daily_brick_summary' );


select * from daily_brick_summary
where  insert_date >= trunc ( sysdate ) ;

insert into bricks 
  values ( 0, sysdate, 'red', 'cylinder', 100 );
commit;
  
/* MV unchagned */
select * from daily_brick_summary
where  insert_date >= trunc ( sysdate ) ;  



select trunc ( insert_datetime ), 
       colour, 
       count (*),
       sum ( weight )
from   bricks
where  trunc ( insert_datetime ) >= trunc ( sysdate ) 
group  by trunc ( insert_datetime ), colour;

exec dbms_mview.refresh ( 'daily_brick_summary' );





alter materialized view daily_brick_summary
  disable on query computation;







/* Some queries are impossible to do a fast refresh! */
truncate table mv_capabilities_table;
begin 
  dbms_mview.explain_mview ( q'[
create materialized view daily_brick_summary_distinct
as 
  select trunc ( insert_datetime ) insert_date, 
         count (*) num_bricks,
         count ( distinct weight ) different_weights, 
         sum ( weight ) total_weight
  from   bricks
  group  by trunc ( insert_datetime )]');
end;
/

select capability_name, possible, msgtxt 
from   mv_capabilities_table
where  capability_name like 'REFRESH%';



/* Include distinct column in group by, 
  so this can use the MV */
select count ( distinct colour ) from bricks;
/* ...but not this */
select count ( distinct insert_datetime ) from bricks;






/* 19c -> bitmap-based count distinct */
truncate table mv_capabilities_table;
begin 
  dbms_mview.explain_mview ( q'[
create materialized view daily_brick_summary_distinct
as 
  select trunc ( insert_datetime ) insert_date, 
         count (*) num_bricks,
         count ( weight ) num_weights,
         sum ( weight ) total_weight,
         bitmap_bucket_number ( weight ) bm_bktno,
         bitmap_construct_agg (
           bitmap_bit_position ( weight ), 'RAW'
         ) bm_details
  from   bricks
  group  by trunc ( insert_datetime ), bitmap_bucket_number ( weight )]');
end;
/

select capability_name, possible, msgtxt 
from   mv_capabilities_table
where  capability_name like 'REFRESH%';





/* Some query types it's still impossible to use fast refresh */
truncate table mv_capabilities_table;
begin 
  dbms_mview.explain_mview ( q'[
create materialized view daily_brick_summary_distinct
as 
  select trunc ( insert_datetime ) insert_date, 
         count (*) num_bricks,
         count (*) over (
           order by trunc ( insert_datetime )
         ) running_num_bricks,
         count ( weight ) num_weights,
         sum ( weight ) total_weight
  from   bricks
  group  by trunc ( insert_datetime )]');
end;
/

select capability_name, possible, msgtxt 
from   mv_capabilities_table
where  capability_name like 'REFRESH%';







alter materialized view daily_brick_summary
  disable query rewrite ;

/*
alter table bricks
  inmemory 
  priority high;
*/
alter session set inmemory_query = enable;
select count ( distinct colour ) from bricks;



select count (*)  from bricks
where  insert_datetime >= trunc ( sysdate );

select count ( distinct colour ) from bricks;

select count (*), count ( distinct shape ) from bricks;

select shape, count(*), 
       sum ( count(*) ) over ( order by shape )
from   bricks
group  by shape;

select shape, count(*), 
       sum ( count(*) ) over ( order by shape )
from   bricks
where  shape like 'p%'
group  by shape;

select * from bricks
where  brick_id = 0;








/* So why bother with MVs? */
alter materialized view daily_brick_summary
  enable query rewrite ;


select count (*) from bricks;
select /*+ no_rewrite */count (*) from bricks;









/* Combine MVs and In-Memory! */
alter materialized view daily_brick_summary
  inmemory
  priority high;
  
select * from v$im_segments;

select count(*) from bricks;