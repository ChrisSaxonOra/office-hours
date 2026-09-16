alter session set optimizer_adaptive_plans = false;
set serveroutput off
alter system flush buffer_cache;
alter system flush shared_pool;
alter session set statistics_level = all;