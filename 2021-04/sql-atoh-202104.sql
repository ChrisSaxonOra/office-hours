--@"C:\Users\csaxon\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-2021-04-setup"

select count(*) from tchild1;
select count(*) from tchild2;

select count(*) from t;

select *
from   t  
where  c1 <= 100;
  
  
  

/* Add in the scalar subqueries */
select c1, rownum, 
       ( select count ( distinct c2 ) 
         from   tchild1 c  
         where  t.c1 = c.c1 ) dist_c2,   
       ( select avg ( c3 )   
         from   tchild2 c  
         where  t.c1 = c.c1 ) mean_c3,   
       ( select max ( c4 )   
         from   tchild1 c  
         where  t.c1 = c.c1 ) max_c4,   
       ( select min ( c4 )   
         from   tchild2 c  
         where  t.c1 = c.c1 ) min_c4   
from   t  
where  c1 <= 100;



/***********************************




***********************************/



/* Working with cross apply */

/* Fetch the last three orders for each store */
select store_name, o.* 
from   co.stores s
cross apply (
  select * from co.orders o
  where  s.store_id = o.store_id
  order by o.order_datetime desc
  fetch first 3 rows only
) o;


/* Lateral and cross apply are the same; This is the same as the previous */
select store_name, o.* 
from   co.stores s,
lateral (
  select * from co.orders o
  where  s.store_id = o.store_id
  order by o.order_datetime desc
  fetch first 3 rows only
) o;


select store_name, o.* 
from   co.stores s
cross join lateral (
  select * from co.orders o
  where  s.store_id = o.store_id
  order by o.order_datetime desc
  fetch first 3 rows only
) o ;



/* Filtering outer table */
select store_name, o.* 
from   co.stores s
cross apply (
  select * from co.orders o
  where  s.store_id = o.store_id
  order by o.order_datetime desc
  fetch first 3 rows only
) o
where  store_name like 'M%';





/* Filtering within the subquery;
   Fetch the last three orders placed from 1 Apr for each store */
select store_name, o.* 
from   co.stores s
cross apply (
  select * from co.orders o
  where  s.store_id = o.store_id
  and    o.order_datetime >= timestamp '2019-04-01 00:00:00'
  order by o.order_datetime desc
  fetch first 3 rows only
) o;


/* To include all stores, make this an outer apply */
select store_name, o.* 
from   co.stores s
outer apply (
  select * from co.orders o
  where  s.store_id = o.store_id
  and    o.order_datetime >= timestamp '2019-04-01 00:00:00'
  order by o.order_datetime desc
  fetch first 3 rows only
) o;


/* Back to tuning scalar subqueries */
/* Cross apply solution */
select c1, 
       s1.*, s2.*
from   t  
cross apply (
  select avg ( c3 ), min ( c4 )   
  from   tchild2 c  
  where  t.c1 = c.c1
) s1
cross apply (
  select count ( distinct c2 ), max ( c4 )   
  from   tchild1 c  
  where  t.c1 = c.c1
) s2
where  c1 <= 100
order  by c1;



/* Convert to (outer) joins - need to nested grouping subqueries */
select c1, min_c4, mean_c3, sm_c3, 
       count ( distinct c1.c2 ) cd, max ( c1.c4 ) mx
from  (
  select c1, 
         min ( c2.c4 ) min_c4, avg ( c2.c3 ) mean_c3, sum ( c2.c3 ) sm_c3
  from   t
  left   join tchild2 c2  
  using  ( c1 ) 
  where  c1 <= 100
  group  by c1
) s
left   join tchild1 c1  
using  ( c1 ) 
group  by c1, min_c4, mean_c3, sm_c3
order  by c1;



/* Straight joins gives incorrect results */
select c1,  
       min ( c2.c4 ) min_c4, avg ( c2.c3 ) mean_c3, sum ( c2.c3 ) sm_c3,
       count ( distinct c1.c2 ) cd, max ( c1.c4 ) mx
from   t
left   join tchild2 c2  
using  ( c1 ) 
left   join tchild1 c1  
using  ( c1 ) 
where  c1 <= 100
group  by c1
order  by c1;






/***********************************




***********************************/


/* Scalar subquery optimizations */
/* The DB can convert SSQs to joins (sometimes) */
select c1, 
       ( select count ( distinct c2 )   
         from   tchild1 c  
         where  t.c1 = c.c1 ) dist_c2,   
       ( select avg ( c3 )   
         from   tchild2 c  
         where  t.c1 = c.c1 ) mean_c3,   
       ( select max ( c4 )   
         from   tchild1 c  
         where  t.c1 = c.c1 ) max_c4,   
       ( select min ( c4 )   
         from   tchild2 c  
         where  t.c1 = c.c1 ) min_c4   
from   t  
where  c1 <= 100;



/* Scalar subquery caching */
select c1, c2, c3, c4, 
       count(*) over () rws,
       ( 
         select stuff from t
         where  t1.c1 = t.c1 
       )
from   tchild1 t1
where  c1 <= 10
order  by c1;



create index i2 on tchild2 ( c2, c4 );

/* SSQ caching => highly efficient */
select t1.c1, t1.c2, c3, c4, 
       count(*) over () rws,
       case 
         when mod ( c1, 10 ) = 1 then 
         ( 
           select max ( c4 ) from tchild2 t2
           where  t1.c2 = t2.c2
         )
       end 
from   tchild1 t1
where  t1.c4 <= date'2021-01-02'
order  by t1.c1, t1.c2;


/* Regular join is worse in this case! */
select t1.c1, t1.c2, t1.c3, t1.c4, 
       count(*) over () rws,
       max ( t2.c4 ) 
from   tchild1 t1
left join tchild2 t2
on     t2.c2 = t1.c2
and    mod ( t1.c1, 10 ) = 1
where  t1.c4 <= date'2021-01-02'
group  by t1.c1, t1.c2, t1.c3, t1.c4
order  by t1.c1;

with rws as (
  select /*+ materialize */level x from dual
)
  select * from rws;




create or replace function f ( p int ) 
  return int as
begin

  dbms_session.sleep ( 1 );
  
  return p;
  
end f;
/


/* Database executes function once/row */
with rws as (
  select level x, 1 y from dual
  connect by level <= 5
)
  select * from rws
  where  1 = f ( y );
  
  
  
  
/* Scalar subquery to avoid function calls */
with rws as (
  select level x, 1 y from dual
  connect by level <= 5
)
  select * from rws
  where  1 = ( select f ( y ) from dual );