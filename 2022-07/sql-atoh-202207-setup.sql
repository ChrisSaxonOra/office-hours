/*
http://www.oracle-developer.net/display.php?id=220
http://www.oracle-developer.net/display.php?id=203
*/
drop table updated_customers
  cascade constraints purge;
drop table inserted_customers 
  cascade constraints purge;
drop table customers_dim
  cascade constraints purge;
drop table customers_stage
  cascade constraints purge;
drop sequence customer_merge_id;
create sequence customer_merge_id;
create table customers_dim (
  customer_id integer
    not null primary key,
  full_name   varchar2(100)
    not null,
  birth_date  date
    not null,
  insert_datetime timestamp
    default systimestamp not null,
  update_datetime timestamp
    default systimestamp not null,
  merge_run_id    integer
    default on null customer_merge_id.nextval not null
);

create table customers_stage (
  customer_id integer
    not null primary key,
  full_name   varchar2(100)
    not null,
  birth_date  date
    not null
);

exec dbms_random.seed ( 0 );

insert into customers_stage
with rws as (
  select level id from dual
  connect by level <= 100
)
  select id, 
         initcap ( 
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) || ' ' ||
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) 
         ) nm,
         date'1920-01-01' +
           numtoyminterval ( dbms_random.value ( 2, 1200 ), 'month' ) +
           numtodsinterval ( round ( dbms_random.value ( 1, 31 ) ), 'day' ) dt
  from   rws;
  
commit;