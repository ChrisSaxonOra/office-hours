alter system flush shared_pool;
set feed off
cl scr
drop table locations
  cascade constraints purge;
drop table appointments
  cascade constraints purge;
drop table periods
  cascade constraints purge;

create table locations (
  location_id integer 
    not null primary key,
  location_name varchar2(100)
    not null unique
);
create table appointments (
  location_id integer
    not null,
  start_date  date
    not null,
  end_date    date
    not null,
  consultant_id integer
    not null
);

create index app_date_i 
  on appointments ( start_date );
create index app_consultant_i 
  on appointments ( consultant_id );

create table periods (
  date_from date 
    not null,
  date_to   date 
    not null,
  period_name varchar2(7)
    not null,
  period_type varchar2(10)
    not null
);

create index period_type_i 
  on periods ( period_type ) ;
  
insert into periods
  with rws as (
    select level rn
    from   dual
    connect by level <= 10
  ), dates as (
    select add_months ( date'2019-01-01', level - 1 ) dt
    from   dual
    connect by level <= 36
  )
    select dt, add_months ( dt, 1 ) - 1, 
           to_char ( dt, 'YYYY/MM' ),
           'P' || lpad ( rn, 2, '0' )
    from   rws
    cross  join dates
    order  by rn, dt;

 
insert into locations
  with rws as (
    select level x from dual
    connect by level <= 10
  )
    select x, 'ROOM' || lpad ( rownum, 3, '0' ) --initcap ( dbms_random.string ( 'a', 10 ) )
    from   rws;
  
insert into appointments
  with rws as (
    select date'2019-01-01' + level x from dual
    connect by level <= 1000
  )
    select location_id, 
           x, x + 9 + ( round ( dbms_random.value ( 1, 6 ) ) / 48 ),
           mod ( rownum, 61 ) c
    from   rws
    cross join locations
    order  by x;
    
commit;

alter table appointments 
  add clustering 
  by interleaved order ( 
    start_date, consultant_id
  );
  
alter table appointments 
  move online;

exec dbms_stats.gather_table_stats ( user, 'locations' ) ;
exec dbms_stats.gather_table_stats ( user, 'appointments' ) ;
exec dbms_stats.gather_table_stats ( user, 'periods' ) ;

set feed on
set serveroutput off
alter session set statistics_level = all;
alter session set optimizer_adaptive_plans = false;
cl scr