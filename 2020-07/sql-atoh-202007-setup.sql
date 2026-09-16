set echo off
--EXEC DBMS_AUTO_INDEX.CONFIGURE('AUTO_INDEX_MODE','OFF');

cl scr
drop table orders
  cascade constraints purge;
create table orders (
  order_id primary key,
  customer_id not null,
  order_datetime not null,
  order_status not null,
  store_id not null,
  notes  not null
) as 
  select level,
         mod ( level, 135531 ),
         date'2000-01-01' + ( level / 132 ) + numtodsinterval ( abs ( sin ( level ) ), 'hour' ),
         case mod ( level, 10000 )
           when 1 then 'CANCELLED'
           when 11 then 'REFUNDED'
           when 37 then 'REFUNDED'
           else 'COMPLETE'
         end,
         mod ( level, 131 ),
         rpad ( 'notes', 20, 's' )
  from   dual             
  connect by level <= 1000000;
  /*
select to_char ( count (*), 'fm999,999,990' )
from   orders;

select * 
from orders
where  customer_id = 1;

select * 
from orders
where  customer_id = 1
and    order_datetime = to_date ( '2019-09-05 07:01:26', 'yyyy-mm-dd hh24:mi:ss' );

select * 
from orders
where  order_status = 'CANCELLED'
and    store_id = 10;

select * 
from orders
where  order_status = 'CANCELLED'
and    customer_id = 1;
  */
exec dbms_stats.gather_table_stats ( user, 'orders' ) ;

drop table t 
  cascade constraints purge;
create table t (
  c1 int, c2 int
);

insert into t 
with rws as (
  select level x, mod ( level, 100 ) y from dual
  connect by level <= 1000
)
  select * from rws;
commit;

select * from t
where  c1 = 1;

--EXEC DBMS_AUTO_INDEX.CONFIGURE('AUTO_INDEX_MODE','IMPLEMENT');
set echo on