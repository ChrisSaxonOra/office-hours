alter index ques_create_date_i invisible;
alter index qure_result_date_i invisible;
alter index quiz_status_i invisible;
alter index mvre_quiz_i invisible;
set pages 1000
set lines 800
set timing on 
set serveroutput off 
alter session set statistics_level = all;
var quiz number;
exec :quiz := 11914744;
var start_date varchar2(10);
var end_date varchar2(10);

exec :start_date := '2023-01-01';
exec :end_date := '2024-01-01';
cl scr