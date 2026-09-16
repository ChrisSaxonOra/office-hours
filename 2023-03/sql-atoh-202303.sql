@sql-atoh-202303-setup

/* 
  Try to create new dept with new employee
  Bi-directional FKs => can't insert! 
*/
insert into employees ( employee_id, first_name, last_name, hire_date, department_id, salary, job_id )
values ( 42, 'Tess', 'Ting', sysdate, 42, 5000, 'IT_PROG' );

insert into departments ( department_id, department_name, manager_id )
values ( 42, 'Test dept', 42 );






/* Can't change constraint to be deferrable; must drop & recreate */
alter table departments
  modify constraint dept_manager_fk
  deferrable;



alter table departments
  drop constraint dept_manager_fk;

alter table departments
  add constraint dept_manager_fk
  foreign key ( manager_id )
  references employees ( employee_id )
  deferrable;




/* By default constraint still checked at the statement level */
insert into departments ( department_id, department_name, manager_id )
values ( 42, 'Test dept', 42 );






/* Delay deferrable constraint validation */
alter session set constraints = deferred;

/* It's only the DEFERRABLE constraints; this is rolled-back */
insert into employees ( employee_id, first_name, last_name, hire_date, department_id, salary, job_id )
values ( 42, 'Tess', 'Ting', sysdate, 42, 5000, 'IT_PROG' );

insert into departments ( department_id, department_name, manager_id )
values ( 42, 'Test dept', 42 );

/* Constraint is validated here - raise error & rollback */
commit;




insert into departments ( department_id, department_name, manager_id )
values ( 42, 'Test dept', 42 );

insert into employees ( employee_id, first_name, last_name, hire_date, department_id, salary, job_id )
values ( 42, 'Tess', 'Ting', sysdate, 42, 5000, 'IT_PROG' );

commit;



/*********************************


 Child for every parent with MVs


*********************************/

create materialized view log on employees
  with rowid, primary key ( department_id, salary ),
  sequence
  including new values;
  
create materialized view log on departments
  with rowid, primary key, 
  sequence
  including new values;

/* 
  Is there a dept with no employees?
  MV outer joining child to parent 
*/
create materialized view department_employees_mv
  refresh fast on commit
as
  select e.rowid empl_rid, d.rowid dept_rid,
         e.employee_id, d.department_id
  from   employees e, departments d
  where  d.department_id = e.department_id (+);
  



/* Check child columns are not null */
alter table department_employees_mv 
  modify employee_id 
    constraint deem_employee_nn
    not null
    deferrable;
    
    

/* Prove MV works - drop dept -> emp FK */
alter table departments
  drop constraint dept_manager_fk;


/* Add new dept with no employees */
insert into departments ( department_id, department_name, manager_id )
values ( 99, 'test', 99 );

/* MV query - note employee_id is null */
select e.employee_id, d.department_id
from   employees e, departments d
where  d.department_id = e.department_id (+)
and    d.department_id = 99;

commit;
/* MV constraint refresh error */

/* Insert rolled back */
select e.employee_id, d.department_id
from   employees e, departments d
where  d.department_id = e.department_id (+)
and    d.department_id = 99;




insert into departments ( department_id, department_name, manager_id )
values ( 99, 'test', 99 );

insert into employees ( employee_id, first_name, last_name, hire_date, department_id, salary, job_id )
values ( 99, 'Tess', 'Ting', sysdate, 99, 5000, 'IT_PROG' );

commit;

select * from department_employees_mv
where  department_id = 99;





/* 
  Jobs have min/max paybands 
  Use MV to ensure salaries are within these
*/
select * from jobs;

create materialized view log on jobs
  with rowid, primary key ( min_salary, max_salary ),
  sequence
  including new values;

create materialized view employee_jobs_mv
  refresh fast on commit
as
  select e.rowid empl_rid, j.rowid job_rid,
         e.salary, j.min_salary, j.max_salary
  from   employees e, jobs j
  where  e.job_id = j.job_id;
  
alter table employee_jobs_mv
  add constraint emjo_salary_c
  check ( salary between min_salary and max_salary )
  deferrable;


/* Increase salaries 10x - beyond limit */
update employees 
set    salary = salary * 10;

commit;




/* 
  Add total salary for dept for employees
  Ensure this equals employee salary sum
*/
alter table departments 
  add ( total_salary number );
  
update departments d
set    total_salary = ( 
  select sum ( salary ) from employees e
  where  d.department_id = e.department_id
);

commit;
  
  
drop materialized view log on departments;

create materialized view log on departments
  with rowid, primary key ( total_salary ), 
  sequence
  including new values;
  
exec dbms_mview.refresh ( 'DEPARTMENT_EMPLOYEES_MV', 'C' );

/* MV joining child to parent */
create materialized view department_salaries_mv
refresh fast on commit as
  select d.department_id, 
         d.total_salary, sum ( e.salary ) emp_salaries, 
         count(*)
  from   employees e, departments d
  where  d.department_id = e.department_id
  group  by d.department_id, d.total_salary;

alter table department_salaries_mv 
  add constraint desa_total_salaries_c 
  check ( total_salary = emp_salaries )
  deferrable;




/* Give 10% raise => need to update dept totals */
update employees
set    salary = salary * 1.1
where  job_id = 'IT_PROG';

commit;


/* Give 10% raise & update department totals */
update employees
set    salary = salary * 1.1
where  job_id = 'IT_PROG';

update departments d
set    total_salary = ( 
  select sum ( salary ) from employees e
  where  d.department_id = e.department_id
)
where  exists (
  select null from employees e
  where  d.department_id = e.department_id
  and    job_id = 'IT_PROG'
);

commit;




/****************************

  Business rules with FKs
  Consecutive start/end dates

****************************/
  
select * from job_history
order  by employee_id, start_date;



/* Ensure no gaps in employment history! */
alter table job_history 
  add constraint johi_start_end_fk
  foreign key ( employee_id, start_date )
  references job_history ( employee_id, end_date )
  novalidate;
  
select * from job_history
where  employee_id = 101
order  by start_date;

/* Can't insert start_date <> prev end date */
insert into job_history ( employee_id, start_date, job_id, department_id )
values ( 101, date'2023-01-01', 'IT_PROG', 20 );

insert into job_history ( employee_id, start_date, job_id, department_id )
values ( 101, date'2005-03-15', 'IT_PROG', 20 );

commit;


/* But how do we add a new employee?! */
insert into job_history ( employee_id, start_date, job_id, department_id )
values ( 999, date'2023-01-01', 'IT_PROG', 20 );

/* Disable the constraint, insert, reenable */
alter table job_history
  modify constraint johi_start_end_fk
  disable;
  
insert into job_history ( employee_id, start_date, job_id, department_id )
values ( 999, date'2023-01-01', 'IT_PROG', 20 );

alter table job_history
  modify constraint johi_start_end_fk
  enable
  novalidate;



/*
   Change and employees's job
   End their current job first
   Then add the new one
*/
update job_history 
set    end_date = date'2023-03-21'
where  employee_id = 999
and    end_date is null;

insert into job_history ( employee_id, start_date, job_id, department_id )
values ( 999, date'2023-03-21', 'PROGRAMMER', 20 );

commit;




/* 
  Mutually exclusive relationship 
  Super/subtypes - job type tables
*/
/* "Redundant" UC as target for FKs */
alter table employees 
  add constraint empl_employee_job_u
  unique ( job_id, employee_id );
  
create table developers (
  employee_id 
    constraint deve_employee_fk
    references employees
    constraint developer_pk
    primary key,
  job_id
    -- Ensure only developers can be inserted
    constraint deve_job_c
    check ( job_id = 'IT_PROG' )
    not null,
  primary_programming_language varchar2(30)
    not null,
  -- Ensure only developers can be inserted
  constraint deve_employee_job_fk
    foreign key ( job_id, employee_id )
    references employees ( job_id, employee_id )
);

create table sales_staff (
  employee_id 
    constraint sast_employee_fk
    references employees
    constraint sales_staff_pk
    primary key,
  job_id
    -- Ensure only sales staff can be inserted
    constraint sast_job_c
    check ( job_id in ( 'SA_MAN', 'SA_REP' ) )
    not null,
  commission_pct number
    not null,
  -- Ensure only sales staff can be inserted
  constraint sast_employee_job_fk
    foreign key ( job_id, employee_id )
    references employees ( job_id, employee_id )
);

select * from employees
where  employee_id = 42;

/* Only insert sales people */
insert into sales_staff 
values ( 42, 'IT_PROG', 0.1 );

/* Parent row must be a sales job */
insert into sales_staff 
values ( 42, 'SA_MAN', 0.1 );

insert into developers 
values ( 42, 'IT_PROG', 'SQL' );

commit;

select * from employees 
join   developers
using  ( employee_id )
where  employee_id = 42;

