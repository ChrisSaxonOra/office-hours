insert into sensors ( latitude, longitude )
values 
( 51.5074,-0.1278 ), 
( 53.4808,-2.2426 ), 
( 55.9533,-3.1883 ), 
( 52.4862,-1.8904 ), 
( 53.8008,-1.5491 ), 
( 54.9783,-1.6178 ), 
( 51.4545,-2.5879 ), 
( 52.4068,-1.5197 ), 
( 53.4084,-2.9916 ), 
( 55.8609,-4.2518 ); 

insert into sensor_readings 
by name
select sensor_id, reading_timestamp reading_ts, temperature_in_c
from   sensors 
cross  apply ( 
  select * from generate_sensor_readings ( 200 - latitude + latitude ) 
);

commit;