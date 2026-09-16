drop table big_child
  cascade constraints purge;
drop table big_table1
  cascade constraints purge;
drop table big_table2
  cascade constraints purge;
drop table big_table3
  cascade constraints purge;
drop table big_table4
  cascade constraints purge;

drop table big_table_keep
  cascade constraints purge;
drop table big_table_part 
  purge;
drop table orders_stage
  cascade constraints purge;  
drop table orders_gtt;
drop table orders
  cascade constraints purge;

create table orders ( 
  order_id primary key, json_data not null
) as 
with rws as (
  select level x from dual
  connect by level <= 10000
)
  select rownum order_id,
         json_object (
           'customerId' value mod ( rownum, 119 ),
           'insertDate' value to_char ( date'2020-01-01' + ( rownum / 14 ), 'YYYY-MM-DD"T"HH24:MI:SS' ),
           'notes' value rpad ( 'notes', 500, 's' )
           returning json
         ) json_data
  from   rws;
  
create table big_table1 ( tab_id primary key, insert_date, stuff ) as 
with rws as (
  select level x from dual
  connect by level <= 10000
)
  select rownum tab_id,
         date'2002-01-01' + ( rownum / 14400 ) insert_date,
         rpad ( 'stuff', 100, 'f' ) stuff
  from   rws cross join rws;
  
create table big_table2 ( tab_id primary key, insert_date, stuff ) as 
  select * from big_table1;
  
create table big_table3 ( tab_id primary key, insert_date, stuff ) as
  select * from big_table1;
  
create table big_table4 ( tab_id primary key, insert_date, stuff ) 
  partition by range ( insert_date ) 
  interval ( interval '1' month ) (
    partition p0 values less than ( date'2000-01-01' )
  ) as 
  select * from big_table1;

