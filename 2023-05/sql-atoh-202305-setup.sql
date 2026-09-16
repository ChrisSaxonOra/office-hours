drop table app_version_deployments  
  cascade constraints purge;
drop table app_version_history
  cascade constraints purge;  
drop view app_version_history_v;
drop materialized view app_version_history_mv;

alter session set nls_timestamp_format = 'DD-MON-YYYY HH24:MI:SS';
cl scr