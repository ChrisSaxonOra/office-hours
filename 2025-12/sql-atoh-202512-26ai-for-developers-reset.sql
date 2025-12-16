set  timing on
exec dbms_stats.set_global_plsql_prefs ( 'dynamic_stats', 'CHOOSE' );
exec dbms_stats.set_plsql_prefs ( user, null, 'generate_sensor_readings','dynamic_stats','OFF');
alter session set nls_timestamp_format = 'DD-MON-YYYY HH24:MI';
drop package test_data ;
create or replace package test_data as 
  function get_test_date return timestamp;
end;
/
create or replace package body test_data 
as 
  test_date timestamp;

  function get_test_date return timestamp as
  begin
    return test_date;
  end;

begin
  test_date := timestamp'2025-01-01 00:00:00';
end;
/

create or replace type sensor_row force as object (
  reading_timestamp timestamp, 
  temperature_in_c  number
);
/

create or replace type sensor_array is table of sensor_row;
/

create or replace function generate_sensor_readings (
  row_count integer
) return sensor_array pipelined as 
begin
  for i in 1 .. row_count loop
    pipe row ( sensor_row (
      test_data.get_test_date + ( i / row_count ) + ( dbms_random.value ( 0, 5 ) / 1440 )
    , round ( 5 + 10 * sin ( i / row_count * 3.14159 )
        + dbms_random.value ( -1, 1 ), 3 )
    ) );
  end loop;
end;
/

drop table if exists sensor_readings cascade constraints purge;
drop table if exists sensors cascade constraints purge;

create table sensors ( 
  sensor_id raw(16) default sys_guid()
    primary key, 
  latitude  number(8, 6)
    constraint sens_lat_c check (
      latitude between -90 and 90
    ),
  longitude number(9, 6),
    constraint sens_long_c check (
      longitude between -180 and 180
    )
);

create table sensor_readings ( 
  sensor_id        references sensors,
  reading_ts timestamp, 
  temperature_in_c number 
);