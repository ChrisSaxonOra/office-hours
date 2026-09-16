/* Basic org chart */
with org_chart ( 
  employee_id, first_name, last_name, manager_id
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id 
  from   hr.employees e
  where  manager_id is null
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id  
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
)
  select * from org_chart;  
  
  
  
  
/* Add level */  
with org_chart ( 
  employee_id, first_name, last_name, manager_id,
  tree_level
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         1
  from   hr.employees e
  where  manager_id is null
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         tree_level + 1
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) 
  select o.*
  from   org_chart o;
  
  
  
/* Add path from root to current node */
with org_chart ( 
  employee_id, first_name, last_name, manager_id,
  hiearchy
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         to_char ( e.employee_id )
  from   hr.employees e
  where  manager_id is null
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         o.hiearchy || ',' || e.employee_id 
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) 
  select o.*
  from   org_chart o;

/* ********************************




******************************** */
  
    
/* Breadth-first output */ 
with org_chart ( 
  employee_id, first_name, last_name, manager_id,
  hiearchy
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         to_char ( e.employee_id )
  from   hr.employees e
  where  manager_id is null
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         o.hiearchy || ',' || e.employee_id 
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) search breadth first by manager_id, employee_id 
    set sort_id
  select o.*
  from   org_chart o;
  
  
  
/* depth-first output by name */ 
with org_chart ( 
  employee_id, first_name, last_name, manager_id,
  hiearchy
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         to_char ( e.employee_id )
  from   hr.employees e
  where  manager_id is null
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         o.hiearchy || ',' || e.employee_id 
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) search depth first by first_name, last_name 
    set sort_id
  select o.*
  from   org_chart o;
  
  
  



/* Get the root and the leaves */
with org_chart ( 
  employee_id, first_name, last_name, manager_id, 
  tree_level, ceo
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         1, e.employee_id
  from   hr.employees e
  where  manager_id is null
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         tree_level + 1, o.employee_id
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) search depth first by employee_id set sort_id,
  leaves as (
  select o.*,
         case
           /* Check if next node is below this
              Need to specify null value! */
           when lead ( tree_level, 1, 1 ) 
             over ( order by sort_id ) <= tree_level 
           then 1
           else 0
         end has_no_reports
  from   org_chart o
)
  select * from leaves
  where  has_no_reports = 1 or
         ceo = employee_id;
  
/* ********************************




******************************** */ 
  
  
  
  
/* Create a loop! */
with org_chart ( 
  employee_id, first_name, last_name, manager_id
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id 
  from   hr.employees e
  where  e.employee_id = 100
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id  
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) 
  select * from org_chart;
  
  
 
/* Stop loop error */ 
with org_chart ( 
  employee_id, first_name, last_name, manager_id
) as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id 
  from   hr.employees e
  where  e.employee_id = 100
  union  all
  select e.employee_id, e.first_name, e.last_name, e.manager_id  
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) cycle employee_id 
    set is_loop to 'Y' default 'N'
  select * from org_chart
--  where  is_loop = 'Y'
  ;
  
  
  
/* "Loop" on department_id */
with org_chart ( 
  employee_id, first_name, last_name, department_id
) as (
  select e.employee_id, e.first_name, e.last_name, e.department_id 
  from   hr.employees e
  where  e.employee_id = 100
  union  all
  select e.employee_id, e.first_name, e.last_name, e.department_id  
  from   org_chart o
  join   hr.employees e
  on     o.employee_id = e.manager_id
) search depth first by employee_id set sort_id
   cycle department_id 
    set is_loop to 'Y' default 'N'
  select * from org_chart;
  

/* ********************************

   Other uses  

******************************** */  
   
/* Date generator */
with dates ( dt ) as (
  select trunc ( sysdate, 'y' ) dt
  from   dual 
  union  all
  select dt + 1
  from   dates
  where  dt < add_months ( trunc ( sysdate, 'y' ), 12 ) - 1
)
  select * from dates;
  
  
  
/* This takes a while... */
with numbers ( n ) as (
  select 1 n
  from   dual 
  union  all
  select n + 1
  from   numbers
  where  n < 10000000
)
  select count(*) from numbers;
  
  
  
  
/* Factorials */
with products ( lvl, n ) as (
  select 1 lvl, 1 n
  from   dual 
  union  all
  select lvl + 1, n * ( lvl + 1 )
  from   products
  where  lvl < 40
)
  select * from products;