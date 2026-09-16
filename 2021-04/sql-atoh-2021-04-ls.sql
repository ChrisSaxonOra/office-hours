drop table t 
  cascade constraints purge;
drop table tchild1
  cascade constraints purge;
drop table tchild2
  cascade constraints purge;

exec dbms_random.seed ( 0 );
  
create table t pctfree 0 as  
  select level c1, lpad ( 'x', 10, 'x' ) stuff from dual 
  connect by level <= 1000;
  
  
create table tchild1 pctfree 0 enable row movement as 
  select c1, c2, round ( dbms_random.value ( 0, 100 ) ) c3, 
         trunc ( sysdate, 'y' ) + ( rownum / 240 ) c4,
         lpad ( 'x', 10, 'x' ) stuff  
  from   t  
  cross join (  
    select mod ( level, 17 ) c2
    from   dual 
    connect by level <= 100
  ) 
  order by dbms_random.value;
  
create table tchild2 pctfree 0 enable row movement as 
  select c1, c2, round ( dbms_random.value ( 0, 100 ) ) c3, 
         trunc ( sysdate, 'y' ) + ( rownum / 240 ) c4,
         lpad ( 'x', 10, 'x' ) stuff  
  from   t  
  cross join (  
    select mod ( level, 17 ) c2
    from   dual 
    connect by level <= 100 
  ) 
  order by dbms_random.value;
  
alter table tchild2 shrink space;
alter table tchild1 shrink space;
  
select count(*) from tchild1;
select count(*) from tchild2;

select count(*) from t;

select *
from   t  
where  c1 <= 100;
  
  
  

/* Add in the scalar subqueries */
begin 
  for rws in ( 
    select /*+ gather_plan_statistics */c1, rownum, 
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
    where  c1 <= 100
  ) loop
    null;
  end loop;
end;
/

select * 
from   dbms_xplan.display_cursor ( '2wgmsabxdbhby', null, 'IOSTATS LAST');



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
) o
order by store_name
fetch first 20 rows only;


/* Lateral and cross apply are the same; This is the same as the previous */
select store_name, o.* 
from   co.stores s,
lateral (
  select * from co.orders o
  where  s.store_id = o.store_id
  order by o.order_datetime desc
  fetch first 3 rows only
) o
order by store_name
fetch first 20 rows only;


select store_name, o.* 
from   co.stores s
cross join lateral (
  select * from co.orders o
  where  s.store_id = o.store_id
  order by o.order_datetime desc
  fetch first 3 rows only
) o 
order by store_name
fetch first 20 rows only;



/* Filtering outer table */
select store_name, o.* 
from   co.stores s
cross apply (
  select * from co.orders o
  where  s.store_id = o.store_id
  order by o.order_datetime desc
  fetch first 3 rows only
) o
where  store_name like 'M%'
order by store_name
fetch first 20 rows only;





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
) o
order by store_name
fetch first 20 rows only;


/* To include all stores, make this an outer apply */
select store_name, o.* 
from   co.stores s
outer apply (
  select * from co.orders o
  where  s.store_id = o.store_id
  and    o.order_datetime >= timestamp '2019-04-01 00:00:00'
  order by o.order_datetime desc
  fetch first 3 rows only
) o
order by store_name
fetch first 20 rows only;


/* Back to tuning scalar subqueries */
/* Cross apply solution */
begin 
  for rws in ( 
    select /*+ gather_plan_statistics */c1, 
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
    order  by c1
  ) loop
    null;
  end loop;
end;
/

select * 
from   dbms_xplan.display_cursor ( '1hvsah50dxbk9', null, 'IOSTATS LAST');

/* Convert to (outer) joins */
begin 
  for rws in ( 
    select /*+ gather_plan_statistics */c1, min_c4, mean_c3, 
           count ( distinct c1.c2 ) cd, max ( c1.c4 ) mx  
    from  (
      select c1, 
             min ( c2.c4 ) min_c4, avg ( c2.c3 ) mean_c3
      from   t
      left   join tchild2 c2  
      using  ( c1 ) 
      where  c1 <= 100
      group  by c1
    ) s
    left   join tchild1 c1  
    using  ( c1 ) 
    group  by c1, min_c4, mean_c3
  ) loop
    null;
  end loop;
end;
/

select * 
from   dbms_xplan.display_cursor ( '95wm0dfv7j6ar', null, 'IOSTATS LAST');


/* The DB can do this (sometimes) */
begin 
  for rws in ( 
    select /*+ gather_plan_statistics */c1, 
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
    where  c1 <= 100
  ) loop
    null;
  end loop;
end;
/

select * 
from   dbms_xplan.display_cursor ( '9cb7yn0xw1dkx', null, 'IOSTATS LAST');



/***********************************




***********************************/


/* Scalar subquery optimizations */
begin
  for rws in ( 
    select /*+ gather_plan_statistics */c1, c2, c3, c4, 
           count(*) over () rws,
           ( 
             select stuff from t
             where  t1.c1 = t.c1 
           )
    from   tchild1 t1
    where  t1.c1 <= 10
    order  by c1
  ) loop
    null;
  end loop;
end;
/

select * 
from   dbms_xplan.display_cursor ( '9x13dr9yagud0', null, 'IOSTATS LAST');


create index i2 on tchild2 ( c2, c4 )
  compress 1;

begin
  for rws in ( 
    select /*+ gather_plan_statistics */t1.c1, t1.c2, c3, c4, 
           count(*) over () rws,
           case 
             when mod ( c1, 10 ) = 1 then ( 
               select max ( c4 ) from tchild2 t2
               where  t1.c2 = t2.c2
             )
           end 
    from   tchild1 t1
    where  t1.c4 <= date'2021-01-02'
    order  by t1.c1, t1.c2
  ) loop
    null;
  end loop;
end;
/

select * 
from   dbms_xplan.display_cursor ( '6qjzyb51thsaw', null, 'IOSTATS LAST');

begin
  for rws in ( 
    select /*+ gather_plan_statistics */t1.c1, t1.c2, t1.c3, t1.c4, 
           count(*) over () rws,
           max ( t2.c4 ) 
    from   tchild1 t1
    left join tchild2 t2
    on     t2.c2 = t1.c2
    and    mod ( t1.c1, 10 ) = 1
    where  t1.c4 <= date'2021-01-02'
    group  by t1.c1, t1.c2, t1.c3, t1.c4
    order  by t1.c1
  ) loop
    null;
  end loop;
end;
/

select * 
from   dbms_xplan.display_cursor ( 'afr1h188fqznu', null, 'IOSTATS LAST');

create or replace function f ( p int ) 
  return int as
  val number;
begin

  for i in 1 .. 250000 loop
    val := ln ( exp ( i ) );
  end loop;
  
  return p;
  
end f;
/


declare
  start_time pls_integer;
begin
  start_time := dbms_utility.get_time ();
  for rws in ( 
    with rws as (
      select level x, 1 y from dual
      connect by level <= 5
    )
      select /*+ gather_plan_statistics */* from rws
      where  1 = f ( y )
  ) loop
    null;
  end loop;
  dbms_output.put_line ( 
    'Run time ' || to_char ( dbms_utility.get_time () - start_time, '9,990' ) 
  );
  start_time := dbms_utility.get_time ();
  for rws in ( 
    with rws as (
      select level x, 1 y from dual
      connect by level <= 5
    )
      select /*+ gather_plan_statistics */* from rws
      where  1 = ( select f ( y ) from dual )
  ) loop
    null;
  end loop;
  dbms_output.put_line ( 
    'Run time ' || to_char ( dbms_utility.get_time () - start_time, '9,990' ) 
  );
end;
/

select * 
from   dbms_xplan.display_cursor ( 'ags52fggjq5pt', null, 'ROWSTATS LAST +PREDICATE');
select * 
from   dbms_xplan.display_cursor ( '6f7pnwp98qk32', null, 'ROWSTATS LAST +PREDICATE');

