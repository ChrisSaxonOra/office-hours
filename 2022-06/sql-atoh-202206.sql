



/* There's no employees with zero (no) commission */
select 
  employee_id, first_name, last_name, 
  commission_pct 
from   hr.employees
where  commission_pct = 0;
/* So everyone gets commission? */





/* Nope! */
select
  employee_id, first_name, last_name, 
  commission_pct
from   hr.employees
where  commission_pct is null;






/* Find all the employees who DON'T manage department... */
select * from hr.employees e
where  e.employee_id not in (
  select d.manager_id from hr.departments d
);




/* 
  So... everyone manages a department?! 
  Let's check that...
*/
select count (*) from hr.employees;


/* Find all the managers */
select distinct manager_id from hr.departments;






/* NOT IN is equivalent to */
select * from hr.employees e
where  e.employee_id <> null
and    e.employee_id <> 108
and    e.employee_id <> 200
/* etc. etc. */
; 




/* Fixed it! */
select * from hr.employees e
where  e.employee_id not in (
  select d.manager_id from hr.departments d
  where  d.manager_id is not null
);




/* ...but I prefer this */
select * from hr.employees e
where  not exists (
  select null from hr.departments d
  where  e.employee_id = d.manager_id
);





/* Functions and aggregations */
select 
  count (*) emp#, 
  count ( commission_pct ) commissioned_emp#
from   hr.employees;






/* Performance implications */
-- View indexes on employees
select 
  index_name,  
  listagg ( column_name, ', ' ) 
    within group ( order by column_position ) indexed_cols
from   all_ind_columns
where  index_owner = 'HR'
and    table_name = 'EMPLOYEES'
group  by index_name;




/*
  COUNT (*) => use any (mandatory) index 
*/
select 
  count (*)
from   hr.employees;





/* 
  COUNT ( optional col ) => column must have index
*/
select 
  count ( manager_id )
from   hr.employees;

select 
  count ( commission_pct )
from   hr.employees;






/*
   COUNT ( mandatory_col ) => can use index on different columns!
*/
select 
  count ( hire_date )
from   hr.employees;






/* SUM & AVG with NULLs */
select 
  /* Are these the same? */
  sum ( commission_pct ) total_pct, 
  sum ( commission_pct + null ) total_pct_plus_null, 
  /* or these? */
  avg ( commission_pct ) avg_pct, 
  avg ( commission_pct + null ) avg_pct_plus_null
from   hr.employees;





/* This returns NULL */
select 1 + null from dual;






/* But this doesn't! (in Oracle Database) */
select last_name || null
from   hr.employees;


/* NOTE: The empty string is null in Oracle Database */
select * from dual
where  '' is null;





/* WHERE vs CHECK constraints */
declare
  negative_salary number := -999;
begin
  insert into hr.employees ( 
    employee_id, last_name, email, hire_date, job_id, department_id,
    salary
  ) values ( 
    -99, 'Test', 'test@test.com', sysdate, 'ST_CLERK', 10,
    negative_salary
  );
end;
/

select 
  employee_id, first_name, last_name, 
  salary
from hr.employees
where  employee_id = -99;




select search_condition
from   all_constraints
where  constraint_name = 'EMP_SALARY_MIN';
/* What's the problem with this? */






declare
  null_salary number;
begin
  insert into hr.employees ( 
    employee_id, last_name, email, hire_date, job_id, department_id,
    salary
  ) values ( 
    -99, 'Test', 'test@test.com', sysdate, 'ST_CLERK', 10,
    null_salary
  );
end;
/

select  
  employee_id, first_name, last_name, 
  salary
from hr.employees
where  employee_id = -99;

select 
  employee_id, first_name, last_name, 
  salary
from hr.employees
where  employee_id = -99
and    salary > 0;

rollback;






/* Sorting */
select
  employee_id, first_name, last_name, 
  commission_pct
from   hr.employees
order  by 
  commission_pct; --nulls last
  
  
select
  employee_id, first_name, last_name, 
  commission_pct
from   hr.employees
order  by 
  commission_pct desc; --nulls first
  
  
  
select
  employee_id, first_name, last_name, 
  commission_pct
from   hr.employees
order  by 
  commission_pct desc nulls last;  
 
  
/******************************************





******************************************/


select 
  *
from   hr.departments d
left   join hr.employees e
using  ( department_id )
order  by employee_id desc;




/* Beware counting outer-joined rows */
select 
  department_id, count (*) c
from   hr.departments
left   join hr.employees
using  ( department_id )
group  by department_id
order  by c nulls first;




/* 
  You (almost always) want to count a column from the inner table 
*/
select 
  department_id, count ( e.employee_id ) c
from   hr.departments d
left   join hr.employees e
using  ( department_id )
group  by department_id
order  by c nulls first;




/* Empty offsets => null */
select  
  employee_id, first_name, last_name, salary,
  lag ( salary ) over ( order by hire_date ) prev_sal,
  lead ( salary ) over ( order by hire_date ) next_sal,
  avg ( salary ) over ( 
    order by hire_date 
    rows between 10 preceding and 1 preceding 
  ) avg_prev_10_sals
from   hr.employees
where  department_id = 10;




/* Provide default when beyond start/end of results */
select  
  employee_id, first_name, last_name, salary,
  lag ( salary, 1, 0 ) over ( order by hire_date ) prev_sal,
  lead ( salary, 1, 0 ) over ( order by hire_date ) next_sal,
  avg ( salary ) over ( 
    order by hire_date 
    rows between 10 preceding and 1 preceding 
  ) avg_prev_10_sals
from   hr.employees
where  department_id = 10;






/* Map null -> zero */
with rws as (
  select 
    employee_id, first_name, last_name, 
    nvl ( commission_pct, 0 ) nvl_comm_pct, 
    coalesce ( commission_pct, 0 ) coalesce_comm_pct, 
    nvl2 ( commission_pct, commission_pct, 0 ) nvl2_comm_pct, 
    decode ( commission_pct, null, 0, commission_pct ) decode_comm_pct,
    case 
      when commission_pct is null then 0 
      else commission_pct 
    end case_comm_pct
  from   hr.employees
)
  select * from rws;




/* Coalesce - first non-null */
select 
  employee_id, first_name, last_name, 
  commission_pct, manager_id, salary,
  coalesce ( commission_pct, manager_id, salary ) coal
from   hr.employees;





/* 
  Find matching employee id (if provided) 
  Check the plan!
*/
select * from hr.employees
where  employee_id = coalesce ( to_number ( :emp_id ), employee_id );






/* NVL - plan advantage */
select * from hr.employees
where  employee_id = nvl ( :emp_id, employee_id );






/* COALESCE uses short-circuiting; NVL doesn't */
select coalesce ( 1, 1/0 ) from dual;
select nvl ( 1, 1/0 ) from dual;




/* Find employees with low or no commission? */
select 
  employee_id, first_name, last_name, 
  commission_pct 
from   hr.employees
where  commission_pct < 0.2;




/* Fixed it! */
select 
  employee_id, first_name, last_name, 
  commission_pct 
from   hr.employees
where  ( commission_pct < 0.2 or commission_pct is null );




select 
  employee_id, first_name, last_name, 
  commission_pct 
from   hr.employees
where  nvl ( commission_pct, 0 ) < 0.2;




/* LNNVL! */
select 
  employee_id, first_name, last_name, 
  commission_pct 
from   hr.employees
where  lnnvl ( commission_pct >= 0.2 );

