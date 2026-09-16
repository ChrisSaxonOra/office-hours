--@"C:\Users\csaxon\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202107-setup"



select * from orders
where  order_id = 1403;

delete orders
where  order_id = 1403;

select * from orders
where  order_id = 1403;

/* Not committed - still visible in session 2 */


/* Get it back! */
rollback;

select * from orders
where  order_id = 1403;







/* Capture deleted row details */
declare
  type id_arr 
    is table of orders.order_id%type
    index by pls_integer;
  ids id_arr;
begin
  delete orders o
  where  o.json_data.customerId.number() = 1
  returning o.order_id
  bulk collect into ids;
  
  for v in values of ids loop
    dbms_output.put_line ( 'Deleted order_id = ' || v );
  end loop;
  rollback;
end;
/




/* Deleted wrong row! */
delete orders
where  order_id = 1403;
commit;



select * from orders
where  order_id = 1403;




/* View deleted row */
select * from orders 
  as of timestamp sysdate - interval '5' minute old
where  order_id = 1403;






/* What was deleted?! Compare old and current */
select order_id from orders 
  as of timestamp sysdate - interval '5' minute old
minus
select order_id from orders now;




/* Exactly when was the order deleted? */
select versions_operation,
       versions_startscn,
       versions_starttime,
       versions_endscn,
       versions_xid,
       o.*
from   orders 
  versions between scn minvalue 
           and maxvalue o
where  versions_operation = 'D';


/* versions_startscn is when it was removed... */
select * from orders 
  as of scn :scn past
where  order_id = 1403;




/* ...need to look just before this */
select * from orders 
  as of scn :scn - 1 past
where  order_id = 1403;



insert into orders
  select * from orders 
    as of scn :scn - 1 past
  where not exists ( 
    select null from orders now
    where  past.order_id = now.order_id
  );
  
select * from orders 
where  order_id = 1403;

commit;



/************************************





************************************/
  
/* Space considerations */
select count (*)
from   orders o;

select bytes/1024 kb 
from   user_segments
where  segment_name = 'ORDERS';

delete orders o
where  mod ( order_id, 5 ) = 0;

commit;



/* Allocated space remains the same */
select bytes/1024 from user_segments
where  segment_name = 'ORDERS';

select dbms_rowid.rowid_block_number ( rowid ) blk,
       count (*) row_per_block,
       count (*) over () total_blocks
from   orders
group  by dbms_rowid.rowid_block_number ( rowid ) ;




/* Try to recover it */
alter table orders
  shrink space compact;
  
/* Row movement is necessary to shrink */
alter table orders
  enable row movement;
  
/* insert in session 2 */
  
/* Defrags table  */
alter table orders
  shrink space compact;
  

/* We have reclaimed blocks */
select dbms_rowid.rowid_block_number ( rowid ) blk,
       count (*) row_per_block,
       count (*) over () total_blocks
from   orders
group  by dbms_rowid.rowid_block_number ( rowid ) ;
  
  
/* ...but HWM remains the same */
select bytes/1024 from user_segments
where  segment_name = 'ORDERS';





/* Deallocates space and resets HWM - needs brief X lock to complete */
alter table orders
  shrink space;
  
  
  
/* session 2 - rollback */

/* Now the HWM is reset */
select bytes/1024 from user_segments
where  segment_name = 'ORDERS';




delete orders
where  mod ( order_id, 5 ) = 1;
commit;

/* session 2 */




/* Deallocates space and resets HWM - also needs brief lock to finish */
alter table orders
  move online; -- online 12.2 EE option
  
  
/* session 2 rollback */
  
select bytes/1024 from user_segments
where  segment_name = 'ORDERS';





/* Truncate vs delete */
create table orders_stage as 
  select * from orders;
  
  
select bytes/1024 from user_segments
where  segment_name = 'ORDERS_STAGE';
  
  
  
delete orders_stage;

select count(*) from orders_stage;




/* All space is still allocated */
select bytes/1024 from user_segments
where  segment_name = 'ORDERS_STAGE';



rollback;

/* Rows restored */
select count(*) from orders_stage;






truncate table orders_stage;

select count(*) from orders_stage;

/* Space deallocated */
select bytes/1024 from user_segments
where  segment_name = 'ORDERS_STAGE';



/* but we can't rollback */
rollback;

select count(*) from orders_stage;




/* reload */
insert into orders_stage 
  select * from orders;
commit;

/* Preserve space allocated to table */
truncate table orders_stage
  reuse storage;
  
select bytes/1024 from user_segments
where  segment_name = 'ORDERS_STAGE';

select count(*) from orders_stage;




/* Temp tables for staging data */
create global temporary table orders_gtt 
  on commit preserve rows
as
  select * from orders
  where  1 = 0;
  
insert into orders_gtt
  select * from orders;
  
select count(*) from orders_gtt;
  
  
  
  
/* It uses no space?! */
select bytes/1024 from user_segments
where  segment_name = 'ORDERS_GTT';





/* GTTs use temp to store data */
select blocks * 8192 / 1024 KB, segtype, sql_text
from   v$tempseg_usage teus
join   v$sqlarea sqla
on     sqla.sql_id = teus.sql_id_tempseg;



commit;

select * from orders_gtt;

/* session 2 */





truncate table orders_gtt;



/************************************





************************************/

select table_name, to_char ( num_rows, '999G999G990' ) num_rows
from   user_tables
where  table_name like 'BIG_T%';

set timing on
/* Delete 0.5% of the rows */
delete big_table1
where  tab_id <= 5e5;
rollback;





/* CTAS keep to "delete" 99.5% of the rows */
create table big_table_keep ( 
  tab_id, insert_date, stuff 
) as
  select * from big_table1
  where  tab_id > 99.5e6;
  

truncate table big_table1;

insert into big_table1
  select * from big_table_keep;
  
commit;

select count(*) from big_table1;

--OR
/*
copy constraints, indexes, triggers, etc to big_table_keep then:

rename big_table1 to big_table_old;
rename big_table_keep to big_table1;
*/
  
  
  
/* CTAS to "delete" the data with partition exchange */
create table big_table_part ( 
  tab_id primary key, insert_date, stuff 
)
  partition by range ( insert_date ) (
    partition pmax values less than ( maxvalue )
  ) as
  select * from big_table2
  where  tab_id > 99.5e6;
  
/* Exchange partition  */
alter table big_table_part
  exchange partition pmax
  with table big_table2
  without validation;
  
select count(*) from big_table2;




/* Note the indexes are unusable... */
select index_name, status from user_indexes
where  table_name = 'BIG_TABLE2';

/* ...so you can't insert new data */
insert into big_table2 values ( 0, sysdate, 'test' );

alter table big_table2
  move online;
  
select index_name, status from user_indexes
where  table_name = 'BIG_TABLE2';

insert into big_table2 values ( 0, sysdate, 'test' );
rollback;

  


/* Filtered table move (12.2) to "delete" 99.5% of the data */
alter table big_table3
  move including rows
  where tab_id > 99.5e6
  online;
  
select count(*) from big_table3;


/* No subqueries/joins/etc. */
alter table big_table3
  move including rows
  where tab_id > ( select 99.5e6 from dual )
  online;
  
  

/* No enabled FKs */
create table big_child ( 
  tab_fk 
) as 
  select tab_id from big_table3
  where  1 = 0;
  
alter table big_child
  add constraint fk 
  foreign key ( tab_fk )
  references big_table3 ( tab_id ); 
  
alter table big_table3
  move including rows
  where tab_id > 99.5e6
  online;





/* Partition drop */
select count(*) from user_tab_partitions
where  table_name = 'BIG_TABLE4';

declare
  stmt varchar2(1000);
begin
  for i in 0 .. 226 loop
    stmt := 'alter table big_table4 
         drop partition for ( date''' || 
         to_char ( add_months ( date'2002-01-01', i ), 'YYYY-MM-DD' ) ||
         ''' ) update indexes '; --async from 12.1
    dbms_output.put_line ( stmt );
    execute immediate stmt;
  end loop;
end;
/


select count(*) from big_table4;

select * from user_tab_partitions
where  table_name = 'BIG_TABLE4';





alter table big_table4
  move partition for ( date '2020-12-31' )
  including rows
  where tab_id > 99.5e6;
  
  
select count(*) from big_table4;