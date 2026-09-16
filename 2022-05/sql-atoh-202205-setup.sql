cl scr
col table_name format a30
col column_name format a30
col partition_name format a30
col object_name format a30
col subobject_name format a30
drop table order_items_stage
  cascade constraints purge;
drop table order_items_archive 
  cascade constraints purge;
drop table order_items 
  cascade constraints purge;
  
drop table orders 
  cascade constraints purge;
drop table orders_archive 
  cascade constraints purge;
drop table orders_stage
  cascade constraints purge;
  
cl scr