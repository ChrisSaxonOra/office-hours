/* Wrong way to build hierarchy */
select ceo.employee_id || '; ' || ceo.first_name || ' ' || ceo.last_name ceo, 
       board.employee_id || '; ' || board.first_name || ' ' || board.last_name cxo, 
       vps.employee_id || '; ' || vps.first_name || ' ' || vps.last_name vps, 
       dir.employee_id || '; ' || dir.first_name || ' ' || dir.last_name dir
from   hr.employees ceo
join   hr.employees board
on     ceo.employee_id = board.manager_id
join   hr.employees vps
on     board.employee_id = vps.manager_id
join   hr.employees dir
on     vps.employee_id = dir.manager_id
where  ceo.employee_id = 100;








/* Basic org chart */
select e.employee_id, e.first_name, e.last_name, e.manager_id  
from   hr.employees e
start with manager_id is null
connect by prior employee_id = manager_id;



/* Omit root */
select e.employee_id, e.first_name, e.last_name, e.manager_id  
from   hr.employees e
connect by prior employee_id = manager_id;










/* Add depth */
select e.employee_id, e.first_name, e.last_name, e.manager_id,
       level tree_depth
from   hr.employees e
start with manager_id is null
connect by prior employee_id = manager_id;









/* Add path from root to current node */
select e.employee_id, e.first_name, e.last_name, e.manager_id,
       sys_connect_by_path ( e.employee_id, ',' ) hiearchy
from   hr.employees e
start with manager_id is null
connect by prior employee_id = manager_id;

/* ********************************




******************************** */



select e.employee_id, e.first_name, e.last_name, e.manager_id,
       sys_connect_by_path ( e.employee_id, ',' ) hiearchy
from   hr.employees e
start with manager_id is null
connect by prior employee_id = manager_id;





/* Sorting loses hierarchy */
select e.employee_id, e.first_name, e.last_name, e.manager_id,
       sys_connect_by_path ( e.employee_id, ',' ) hiearchy
from   hr.employees e
start with manager_id is null
connect by prior employee_id = manager_id
order by first_name, last_name;




/* Depth-first output by name */
select e.employee_id, e.first_name, e.last_name, e.manager_id,
       sys_connect_by_path ( e.employee_id, ',' ) hiearchy
from   hr.employees e
start with manager_id is null
connect by prior employee_id = manager_id
order siblings by first_name, last_name;







/* Sorting breadth-first output */
select e.employee_id, e.first_name, e.last_name, e.manager_id,
       sys_connect_by_path ( e.employee_id, ',' ) hiearchy
from   hr.employees e
start with manager_id is null
connect by prior employee_id = manager_id
order by level, manager_id, employee_id;























/* Get the root and the leaves */
select e.employee_id, e.first_name, e.last_name, e.manager_id,
       connect_by_root e.employee_id ceo,
       connect_by_isleaf has_no_reports
from   hr.employees e
where  connect_by_isleaf = 1 or 
       connect_by_root e.employee_id = employee_id
start with manager_id is null
connect by prior employee_id = manager_id;




with org_chart as (
  select e.employee_id, e.first_name, e.last_name, e.manager_id,
         connect_by_root e.employee_id ceo,
         connect_by_isleaf has_no_reports
  from   hr.employees e
  start with manager_id is null
  connect by prior employee_id = manager_id
)
  select * from org_chart
  where  has_no_reports = 1 or 
         ceo = employee_id;

/* ********************************




******************************** */



  
/* Create a loop! */
update hr.employees
set    manager_id = 202
where  employee_id = 100;
  
select e.employee_id, e.first_name, e.last_name, e.manager_id  
from   hr.employees e
start with e.employee_id = 100
connect by prior employee_id = manager_id;





/* nocycle - stop when next row is an ancestor */
select e.employee_id, e.first_name, e.last_name, e.manager_id,
       connect_by_iscycle is_loop
from   hr.employees e
start with e.employee_id = 100
connect by nocycle prior employee_id = manager_id;


/* Find the loop! */
select s.employee_id, s.first_name, s.last_name, s.manager_id
from   hr.employees s
where  s.manager_id in (
  select e.employee_id
  from   hr.employees e
  where  connect_by_iscycle = 1
  start with e.employee_id = 100
  connect by nocycle prior employee_id = manager_id
);


update hr.employees
set    manager_id = null
where  employee_id = 100;


/* ********************************

   Other uses  

******************************** */

/* Date generator */
select trunc ( sysdate, 'y' ) - 1 + level dt
from   dual
connect by level <= 365;





/* Beware! */
select count (*)
from   dual
connect by level <= 10000000;


/* Fixed it! */
with rws as (
  select level x from dual
  connect by level <= 10000
)
  select count (*) 
  from   rws
  cross  join rws
  where  rownum <= 10000000;
  
  
  
  
  
/* Factorials */
select level, 
       exp ( 
         sum ( ln ( level ) ) 
           over ( order by level ) 
       ) n
from   dual
connect by level <= 40;