@C:\Users\csaxon\Documents\Scripts\sql-atoh-202007-setup

select to_char ( count (*), 'fm999,999,990' )
from   orders;

select * 
from   orders
where  customer_id = 1;


select * 
from   orders
where  customer_id = 1
and    order_datetime = to_date ( '2019-09-05 07:01:26', 'yyyy-mm-dd hh24:mi:ss' );


select * 
from   orders
where  order_status = 'CANCELLED'
and    store_id = 10;


select * 
from   orders
where  order_status = 'CANCELLED'
and    customer_id = 1;



cl scr
set serveroutput off
alter session set statistics_level = all;
select /* perf */* 
from   orders
where  customer_id = 1;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'IOSTATS LAST'));

select /* perf */* 
from   orders
where  customer_id = 1
and    order_datetime = to_date ( '2019-09-05 07:01:26', 'yyyy-mm-dd hh24:mi:ss' );

select * 
from   table(dbms_xplan.display_cursor(null, null, 'IOSTATS LAST'));

select /* perf */* 
from   orders
where  order_status = 'CANCELLED'
and    store_id = 10;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'IOSTATS LAST'));

select /* perf */* 
from   orders
where  order_status = 'CANCELLED'
and    customer_id = 1;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'IOSTATS LAST'));












select ui.index_name, ui.table_name, visibility, segment_created, 
       listagg ( uic.column_name, ',' )
         within group ( order by column_position ) cols
from   user_indexes ui
join   user_ind_columns uic
on     ui.index_name = uic.index_name
where  ui.table_name = 'ORDERS'
group  by ui.index_name, ui.table_name, visibility, segment_created;




-- default text report for the latest activity.
select dbms_auto_index.report_last_activity(section => 'ALL', "LEVEL" => 'ALL') from dual;


select dbms_auto_index.report_activity(section => 'ALL', "LEVEL" => 'ALL') from dual;

/********

Wait for AI to create the indexes

**********/



select * 
from   orders
where  order_status = 'CANCELLED'
and    customer_id = 1
and    store_id = 1;

