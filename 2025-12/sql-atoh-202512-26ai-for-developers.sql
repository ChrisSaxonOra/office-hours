@sql-atoh-202512-26ai-for-developers-reset.sql
@sql-atoh-202512-26ai-for-developers-load.sql




select * from sensors;

-- Ayr, Scotland?
insert into sensors ( latitude, longitude )
values ( -4.6204, 55.4525 );







-- Let's look at the data
select * from sensors;




-- oopsie, mixed-up lat and long; the new sensor is in the Seychelles!
-- Also: UIDs all very similar. How are they generated?

set long 100000
select dbms_metadata.get_ddl ( 'TABLE', 'SENSORS' );




-- DBMS_metadata can be slow :( 
-- Parse DDL to extract properties :/





-- Add some test data?
insert into sensor_readings 
select sensor_id, temperature_in_c, reading_timestamp
from   sensors 
cross  join generate_sensor_readings ( 200 );





-- Column order mismatch :( 
desc sensor_readings;





-- Also: look at the estimated rows for the table func:
select count (*)
from   generate_sensor_readings ( 200 );






-- Get mean temp in C and F in 15-minute groups?
select trunc ( reading_ts ) + floor ( 
         ( reading_ts - trunc ( reading_ts ) ) / ( 60 / 12 ), 'mi' 
       ) * 15 start_time
     , avg ( temperature_in_c ) avg_in_c
     , avg ( temperature_in_c * 5 / 9 - 32 ) avg_in_f
from   sensor_readings
group  by reading_ts
order  by reading_ts;



-- First start_time should be 00:00
select min ( reading_ts ) from sensor_readings;


-- grouping before select => incorrect results
-- Shows end of time group, not start
-- C => F formula incorrect



select *
from   sensor_readings
having temperature_in_c > 
         avg ( temperature_in_c );

-- Need to GROUP BY temperature


/*****************************/



/*****************************/

@sql-atoh-202512-26ai-for-developers-reset.sql

-- dbms_developer, new in 23.7
select json_query ( json_serialize (
    dbms_developer.get_metadata ( 'SENSORS', level => 'BASIC' )
    pretty 
  ), '$.objectInfo.columns?(@.name == "SENSOR_ID").default' 
  returning varchar2(20) with array wrapper
) default_value, json_serialize (
  dbms_developer.get_metadata ( 'SENSORS', level => 'BASIC' )
  pretty 
);



/* Move to v4 random UUIDs */
alter table sensors 
  modify sensor_id default uuid();

-- Check the new default
select json_query ( json_serialize (
    dbms_developer.get_metadata ( 'SENSORS', level => 'BASIC' )
    pretty 
  ), '$.objectInfo.columns?(@.name == "SENSOR_ID").default' 
  returning varchar2(20) with array wrapper
) default_value;



-- Start transaction 
begin
  dbms_output.put_line ( 
    utl_raw.cast_to_varchar2 (
      dbms_transaction.start_transaction ( 
        utl_raw.cast_to_raw ( 'sessionless_trans_name' ) -- Use unique IDs!
      , dbms_transaction.transaction_type_sessionless
      , 300 -- timeout in seconds; must resume within this or its auto-rolled back
      , dbms_transaction.transaction_new 
      ) 
    )
  );
end;
/



-- Non-positional insert; columns alongside values 
-- Can provide values for different columns in each row
insert into sensors 
set    ( latitude = 55.7209, longitude = -4.3190 ),
       ( sensor_id = uuid(), latitude = 51.5074, longitude = -0.1278 );


-- v4 random UUIDs
select * from sensors;





-- Pause the transaction
exec dbms_transaction.suspend_transaction ();

-- Back to clean slate; can't see sensor just added
select * from sensors;

-- Transaction is still active
select * from v$transaction;


-- Disconnect/reconnect
select sys_context ( 'userenv', 'sid' );



-- The data isn't there...
select * from sensors;

-- ...until we resume transaction
begin
  dbms_output.put_line ( 
    utl_raw.cast_to_varchar2 (
      dbms_transaction.start_transaction ( 
        utl_raw.cast_to_raw ( 'sessionless_trans_name' ) -- Need name/GTRID from before!
      , dbms_transaction.transaction_type_sessionless
      , 300
      , dbms_transaction.transaction_resume
      ) 
    )
  );
end;
/

-- And the transaction state is restored
select * from sensors;




-- Continue the transaction 
desc sensor_readings

insert into sensor_readings 
by name -- Match SELECTed columns/alias to INSERT table columns
  select sensor_id, temperature_in_c, reading_timestamp reading_ts
  from   sensors 
  cross  join generate_sensor_readings ( 200 );

commit;




/* What about changing the test date? */
select * from generate_sensor_readings (10) g;
/* It's based on this package function */
select test_data.get_test_date;





/* Compile package in another session */
select * from generate_sensor_readings (10) g;

/* Ug :( */




/* Let's make the package RESETTABLE! */
select * from generate_sensor_readings (10) g;
/* Compile again => no error! */







-- View the plan: those row estimates :( 
select count (*) from generate_sensor_readings (200) g;






-- Check PL/SQL dynamic stats preferences CHOOSE is default
select dbms_stats.get_plsql_prefs ( 'dynamic_stats' );
exec dbms_stats.set_global_plsql_prefs ( 'dynamic_stats', 'ON' );


-- Check the row estimates now: bang on!
select count (*) from generate_sensor_readings (200) g;




-- Set back to default
exec dbms_stats.set_global_plsql_prefs ( 'dynamic_stats', 'CHOOSE' );

-- Can set for specific packages/functions
exec dbms_stats.set_plsql_prefs ( -
  user, null, 'generate_sensor_readings', 'dynamic_stats', 'ON' -
);
select count (*) from generate_sensor_readings (200) g;


-- Default again
exec dbms_stats.set_plsql_prefs ( -
  user, null, 'generate_sensor_readings', 'dynamic_stats', 'CHOOSE' -
);











-- Get the 15-minute average temp
select sensor_id, 
       time_bucket ( 
         reading_ts, 
         interval '15' minute, 
         timestamp'2025-01-01 12:45:00' 
       ) bucket_start, -- Start of 15-minute slice
       time_bucket ( 
         reading_ts, 
         'PT15M', -- ISO 8601 time interval
         cast ( trunc ( reading_ts ) as timestamp ), -- trunc returns date, cast back to TS
         end -- of bucket
       ) bucket_end, -- End of 15-minute slice
       count (*) readings,
       avg ( temperature_in_c ) mean_temp
from   sensor_readings
group  by all -- autogenerate group by sensor_id, bucket_start, bucket_end
order  by sensor_id, bucket_start;





create or replace function celcius_to_fahrenheit (
  degrees_celcius number
) return number deterministic as
begin
  dbms_session.sleep ( 0.02 ); -- simulate slow function
  return ( degrees_celcius / 5 * 9 ) + 32;
end;
/

create or replace function celcius_to_kelvin (
  degrees_celcius number
) return number deterministic as
begin
  dbms_session.sleep ( 0.02 ); -- simulate slow function
  return degrees_celcius + 274.15;
end;
/



set timing on
-- VIRTUAL (11.1) = calc on read; this is instant
alter table sensor_readings 
  add ( 
    temperature_in_f number as ( 
      celcius_to_fahrenheit ( temperature_in_c )
    ) virtual 
  ); 

-- MATERIALIZED (23.7) = calc on write; this takes a while...
alter table sensor_readings 
  add ( 
    temperature_in_k number as (
      celcius_to_kelvin ( temperature_in_c )
    ) materialized 
  );




-- The reverse is true for queries
-- Selecting the virtual column is slow
select sensor_id, reading_ts, temperature_in_f 
from   sensor_readings;

-- Selecting the materialized column is fast
select sensor_id, reading_ts, temperature_in_k 
from   sensor_readings;







-- Can index both; materialized faster to create because value already calculated
create index sere_temp_f_i 
  on sensor_readings ( temperature_in_f );

create index sere_temp_k_i 
  on sensor_readings ( temperature_in_k );






-- Find all temperatures > mean temp
-- QUALIFY happens after GROUP BY (when present)
select sensor_id, reading_ts, temperature_in_c + 0 c
from   sensor_readings
qualify temperature_in_c > 
          avg ( temperature_in_c ) over () -- filter a window function
and     c > 15; -- column aliases too; happens at end, better in WHERE if possible







-- Query the database using GraphQL
set long 1000000
select json_serialize ( data returning clob pretty ) as data 
from   graphql ( '
  sensors {
    sensor_id 
    sensor_readings [ 
      { reading_ts temperature_in_c }
    ]
  } '
);


/*****************************/






-- See what it converts to
declare
  stmt clob;
begin
  dbms_utility.expand_sql_text ( 
    q'!  select json_serialize ( data returning clob pretty ) as data 
from   graphql ( '
  sensors {
    sensor_id 
    sensor_readings [ 
      { reading_ts temperature_in_c }
    ]
  } '
)!',
    stmt );
  dbms_output.put_line ( stmt );
end;
/
