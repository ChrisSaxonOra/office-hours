drop table if exists sensor_readings cascade constraints purge;
drop table if exists sensor_rain_readings cascade constraints purge;
drop table if exists sensor_heat_readings cascade constraints purge;
drop table if exists sensor_wind_readings cascade constraints purge;
drop table if exists sensors cascade constraints purge;


create or replace function rand_poisson(lambda in number)
  return number
is
  k number := 0;
  p number := 1;
  l number;
begin
  if lambda <= 0 then
    return 0;
  end if; 

  l := exp(-lambda);
  loop
    k := k + 0.1;
    p := p * dbms_random.value; -- uniform(0,1)
    exit when p <= l;
  end loop; 

  return k - 0.1;
end;
/ 

create or replace type sensor_row force as object (
  reading_datetime    timestamp, 
  temperature_in_c    number,
  pressure_in_mbar    number,
  relative_humidity   number,
  wind_speed_m_per_s  number, 
  wind_direction      number,
  rainfall_mm_per_min number
);
/

create or replace type sensor_array is table of sensor_row;
/

create or replace function generate_sensor_readings (
  row_count integer, sensor_id integer
) return sensor_array pipelined as 
  mod_sensor pls_integer := mod ( sensor_id, 4 );
begin
  for i in 1 .. row_count loop
    pipe row ( sensor_row (
      trunc ( sysdate ) + ( ( i * 10 ) / 1440 ) + ( dbms_random.value ( -1, 1 ) / 1440 )
    , case when mod_sensor in ( 2, 3 ) then null else round ( 5 + 10 * sin ( i / 144 * 3.14159 )
        + dbms_random.value ( -1, 1 ), 3 ) end
    , case when mod_sensor in ( 2, 3 ) then null else round ( ( dbms_random.normal () * 50 ) + 1000 ) end
    , case when mod_sensor in ( 2, 3 ) then null else least ( round ( ( dbms_random.normal () * 7 ) + 78, 2 ), 100 ) end
    , case when mod_sensor in ( 3, 0 ) then null else greatest ( round ( ( dbms_random.normal () * 5 ) + 12, 2 ), 0 ) end
    , case when mod_sensor in ( 3, 0 ) then null else round ( dbms_random.value ( 0, 360 ) ) end
    , case when mod_sensor in ( 0, 2 ) then null else rand_poisson ( 2 ) end
    )
    );
  end loop;
end;
/


select * from ( select level l connect by level <= 5 ), 
  lateral ( select * from generate_sensor_readings ( 144, l ) )