create table left_t (	
  join_column number, 
  left_c2     varchar2(10), 
  left_c3     integer
);
create table right_t  (	
  join_column number, 
  right_c2    varchar2(10), 
  right_c3    integer
);
begin
  delete left_t;
  delete right_t;
  insert into left_t (join_column,left_c2,left_c3) 
    values (1,'LEFT',1);
  insert into left_t (join_column,left_c2,left_c3) 
    values (2,'LEFT',2);
  insert into right_t (join_column,right_c2,right_c3) 
    values (2,'RIGHT',1);
  insert into right_t (join_column,right_c2,right_c3) 
    values (2,'RIGHT',2);
  insert into right_t (join_column,right_c2,right_c3) 
    values (3,'RIGHT',3);
  commit;
end;
/

/* Cross join - Cartesian product */
select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
cross  join right_t rt
order  by left_c3, right_c3
/







/* Inner join - rows matching join criteria in both tables */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
inner  join right_t rt
on     lt.join_column = rt.join_column
order  by left_c3, right_c3
/
 
 
 





/* Inner join - matching in both tables */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
inner  join right_t rt
on     lt.join_column = rt.join_column
and    lt.left_c3 = rt.right_c3
order  by left_c3, right_c3
/
 
 
 
 
 
/* Band  join - non-matching in both tables */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
inner  join right_t rt
on     lt.join_column between rt.right_c3 and rt.join_column
order  by left_c3, right_c3
/






 
 
/* Non-equijoin - non-matching in both tables */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
inner  join right_t rt
on     lt.join_column <> rt.join_column
order  by left_c3, right_c3
/




 
 
/* Left outer join - return all rows from outer (left) table */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
left   join right_t rt
on     lt.join_column = rt.join_column
order  by left_c3, right_c3
/








/* Right outer join - return all rows from outer (right) table */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
right  join right_t rt
on     lt.join_column = rt.join_column
order  by left_c3, right_c3
/







/* Outer join - be careful when filtering inner table */
select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
left   join right_t rt
on     lt.join_column = rt.join_column
where  right_c3 > 1
order  by left_c3, right_c3
/




/* Outer join - to filter the inner table this must be in join clause */
select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
left   join right_t rt
on     lt.join_column = rt.join_column
and    right_c3 > 1
order  by left_c3, right_c3
/






/* Partitioned outer join - return all rows from outer table 
    with every value for the partition columns */
select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
left join right_t rt
  partition by ( right_c3 )
on     lt.join_column = rt.join_column
order  by left_c3, right_c3
/







/* Full outer join - every row from both tables */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
full   join right_t rt
on     lt.join_column = rt.join_column
order  by left_c3, right_c3
/







/* Cross apply - join in subquery */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
cross  apply ( 
  select * from right_t rt
  where  lt.join_column = rt.join_column
  order  by right_c3
  fetch first 1 rows only
) rt
order  by left_c3, right_c3
/






/* Outer apply - join in subquery preserving outer (left) table */

select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
outer  apply ( 
  select * from right_t rt
  where  lt.join_column = rt.join_column
  order  by right_c3
  fetch first 1 rows only
) rt
order  by left_c3, right_c3
/




/* Outer apply - join in subquery preserving outer (left) table */
select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
outer  apply ( 
  select * from right_t rt
  where  lt.join_column = rt.join_column
  order  by right_c3
  fetch first 1 rows only
) rt
order  by left_c3, right_c3
/


/* ON vs USING 
Key differences:
 - USING de-duplicates join column
 - Join columns must have same name in both tables with USING
 - Equality only for USING
*/
select lt.join_column left_join_c, left_c2, left_c3,
       rt.join_column right_join_c, right_c2, right_c3
from   left_t lt
join   right_t rt
on     lt.join_column = rt.join_column
order  by left_c3, right_c3
/


select join_column, 
       left_c2, left_c3,
       right_c2, right_c3
from   left_t lt
join   right_t rt
using  ( join_column ) 
/

/* Deduplicates join columns */
select join_column, 
       left_c2, left_c3,
       right_c2, right_c3
              
              
from   left_t lt
join   right_t rt

/* Columns must have same name */
using  ( join_column ) 

join t

/* Only join_column = join_column */
using  ( join_column ) 

order  by left_c3, right_c3
/




/* Returns both join columns
   Add aliases to separate
*/
select lt.join_column left_join_c, 
       rt.join_column right_join_c, 
       left_c2, left_c3, 
       right_c2, right_c3
       
from   left_t lt
join   right_t rt

/* Can join on columns with different names */
on     lt.left_c3 = rt.right_c3

join t

/* Can use range comparisons */
on     lt.left_c3 < rt.right_c3

order  by left_c3, right_c3
/
 
 
select *
from   left_t lt
natural join right_t rt
order  by left_c3, right_c3
/


/* Compare tables with natural full outer join */
select *
from   
  ( select 'LT' lt, lt.* from left_t lt ) lt
natural full outer join 
  ( select 'RT' rt, rt.* from right_t rt ) rt
where  lt is null or rt is null
order  by left_c3, right_c3