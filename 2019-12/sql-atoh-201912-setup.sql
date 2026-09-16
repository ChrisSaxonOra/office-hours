cl scr
set echo off
set verify off
set feed off
set serveroutput off
alter session set statistics_level = all;

drop table bricks
  cascade constraints purge;
drop table colours
  cascade constraints purge;
drop table pens
  cascade constraints purge;
drop table toys
  cascade constraints purge;
  
create table bricks ( 
  colour   varchar2(10), 
  shape    varchar2(10) 
);

create table colours ( 
  colour        varchar2(10), 
  rgb_hex_value varchar2(6) 
);

create table toys ( 
  toy_name varchar2(20), 
  colour   varchar2(10) 
);

create table pens ( 
  colour   varchar2(10), 
  pen_type varchar2(10) 
);

begin 
 
  insert into toys values ( 'Miss Snuggles', 'pink' ) ; 
  insert into toys values ( 'Cuteasaurus', 'blue' ) ; 
  insert into toys values ( 'Baby Turtle', 'green' ) ; 
  insert into toys values ( 'Green Rabbit', 'green' ) ; 
  insert into toys values ( 'White Rabbit', 'white' ) ; 
   
  insert into colours values ( 'red' , 'FF0000' );  
  insert into colours values ( 'blue' , '0000FF' );  
  insert into colours values ( 'green' , '00FF00' );  
   
  insert into bricks values ( 'red', 'cylinder' ); 
  insert into bricks values ( 'blue', 'cube' ); 
  insert into bricks values ( 'green', 'cube' ); 
   
  insert into bricks 
    select * from bricks; 
     
  insert into bricks 
    select * from bricks; 
     
  insert into bricks 
    select * from bricks; 
   
  insert into pens values ( 'black', 'ball point' ); 
  insert into pens values ( 'black', 'permanent' ); 
  insert into pens values ( 'blue', 'ball point' ); 
  insert into pens values ( 'green', 'permanent' ); 
  insert into pens values ( 'green', 'dry-wipe' ); 
  insert into pens values ( 'red', 'permanent' ); 
  insert into pens values ( 'red', 'dry-wipe' ); 
  insert into pens values ( 'blue', 'permanent' ); 
  insert into pens values ( 'blue', 'dry-wipe' ); 
   
  commit; 
end; 
/


alter table bricks 
  add brick_id int  
  generated as identity;

begin  
  dbms_stats.gather_table_stats ( null, 'pens' ) ; 
  dbms_stats.gather_table_stats ( null, 'colours' ) ; 
  dbms_stats.gather_table_stats ( null, 'bricks' ) ; 
  dbms_stats.gather_table_stats ( null, 'toys' ) ; 
end; 
/


begin 
  dbms_stats.set_table_stats ( null, 'colours', numrows => 100 ); 
  dbms_stats.set_table_stats ( null, 'bricks', numrows => 1 ); 
end; 
/

set echo on
set verify on
set feed on