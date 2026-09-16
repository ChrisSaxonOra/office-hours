@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202205-setup"

  
create table orders (
  order_id       int 
    primary key
    not null, 
  order_datetime date
    not null,
  customer_id    int 
    not null
);

create table order_items (
  order_id 
    constraint order_fk 
    references orders ( order_id ) 
    on delete cascade -- we'll need this!
    not null,
  product_id integer
    not null,
  deprecated_column integer,
  primary key ( 
    order_id, product_id 
  ) 
);

/* Deprecate a column */
alter table order_items
  set unused column deprecated_column;




/* Add partitioning to the tables */
alter table orders 
  modify partition by range ( order_datetime )
  interval ( interval '1' month ) (
    partition p0 values less than ( date'2022-01-01' )
  );

alter table order_items
  modify partition by reference ( order_fk );
 
select table_name, partition_name 
from   user_tab_partitions
where  table_name like 'ORDER%';






/* Can't exchange after CTAS :( */
create table order_items_stage as
  select * from order_items
  where  1 = 0;

alter table order_items
  exchange partition p0
  with table order_items_stage;





/* Unused column is hidden */
select table_name, column_name, hidden_column
from   user_tab_cols
where  table_name like 'ORDER_ITEM%'
order  by column_name;




/* Reset & create exchange tables */
drop table order_items_stage 
  cascade constraints purge;
 
create table orders_stage
  for exchange with table orders;
  
create table order_items_stage 
  for exchange with table order_items; 
  
/* Add the constraints */
alter table orders_stage
  add primary key ( order_id );
  
alter table order_items_stage 
  add foreign key ( order_id )
  references orders_stage ( order_id )
  on delete cascade;




/* Load some data! */
insert into orders values ( 1, sysdate, 1 );
insert into order_items values ( 1, 1 );
commit;

/* This created the partitions */
select table_name, partition_name 
from   user_tab_partitions
where  table_name like 'ORDER%';


/* Child table => can't exchange */
alter table orders
  exchange partition for ( date'2022-05-01' )
  with table orders_stage;






/* ...until we add the cascade option! */
alter table orders
  exchange partition for ( date'2022-05-01' )
  with table orders_stage
  cascade;

select * from order_items;  
select * from order_items_stage;  






/* Create archive tables - exchange with original table */
create table orders_archive 
  partition by range ( order_datetime )
  interval ( interval '1' month ) (
    partition p0 values less than ( date'2022-01-01' )
  )
  for exchange with table orders;
  
create table order_items_archive 
  for exchange with table order_items;
  
  
/* Add the constraints */
alter table orders_archive 
  add primary key ( order_id );
  
alter table order_items_archive 
  add constraint order_archive_fk
  foreign key ( order_id )
  references orders_archive ( order_id )
  on delete cascade;
  
/* Partition the child */
alter table order_items_archive
  modify partition by reference ( order_archive_fk );
 
  
    
    
    
    
    


/* Move to archive table */  
alter table orders_archive
  exchange partition for ( date'2022-05-01' )
  with table orders_stage
  cascade;

select * from order_items_stage;  
select * from order_items_archive;




/* How is it so fast?! */
select object_name, subobject_name, object_id, data_object_id 
from   user_objects
where  object_name like 'ORDER%'
and    data_object_id is not null
and    ( 
  object_type = 'TABLE' or 
  object_type = 'TABLE PARTITION' and subobject_name like 'SYS%'
)
order  by substr ( object_name, 1, 6 ), object_id;





/* Finally - clean up archived partitions */
select table_name, partition_name 
from   user_tab_partitions
where  table_name like 'ORDER%';

/* No need to cascade! */
alter table orders
  drop partition for ( date'2022-05-01' );
  
select table_name, partition_name 
from   user_tab_partitions
where  table_name like 'ORDER%';