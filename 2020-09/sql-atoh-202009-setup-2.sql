set timing on
cl scr
set serveroutput off
alter session set statistics_level = all;
alter index bric_date_colour_weight_i
  invisible;
alter index bric_date_i
  invisible;
drop index dabs_insert_date_i ;
alter session set inmemory_query = disable;
alter materialized view daily_brick_summary
  no inmemory
  refresh force on demand
  disable query rewrite ;
  
drop materialized view log on bricks;

delete bricks where brick_id = 0;
commit;
exec dbms_mview.refresh ( 'daily_brick_summary' );