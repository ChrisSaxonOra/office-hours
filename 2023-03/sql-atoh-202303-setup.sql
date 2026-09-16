alter session set nls_date_format = ' DD-MON-YYYY ';
drop materialized view employee_jobs_mv;
drop materialized view department_salaries_mv;
drop materialized view department_employees_mv;

drop table sales_staff
  cascade constraints purge;
drop table developers
  cascade constraints purge;
drop table jobs
  cascade constraints purge;
drop table job_history 
  cascade constraints purge;
drop table employees
  cascade constraints purge;
drop table departments
  cascade constraints purge;
  
create table jobs (
  job_id constraint job_pk primary key, 
  job_title, min_salary, max_salary
) as
  select * from hr.jobs;
  
create table employees ( 
  employee_id primary key,
  first_name not null, last_name not null, 
  hire_date not null, department_id not null,
  salary not null, job_id not null
) as 
  select employee_id, first_name, last_name, hire_date, department_id, salary, job_id
  from   hr.employees
  where  department_id is not null;
  
create table departments ( 
  department_id primary key, department_name not null, manager_id not null
) as 
  select department_id, department_name, manager_id 
  from   hr.departments
  where  manager_id is not null;



create table job_history (
  employee_id, 
  start_date not null, end_date,
  job_id not null, department_id not null,
  constraint job_history_pk 
    primary key ( employee_id, start_date ),
  constraint job_history_u
    unique ( employee_id, end_date )
) as
  select employee_id, start_date, 
         lead ( start_date, 1, end_date ) over ( 
            partition by employee_id order by start_date 
         ) end_date,
         job_id, department_id
  from   hr.job_history;  

alter table departments
  add constraint dept_manager_fk
  foreign key ( manager_id )
  references employees;
  
alter table employees
  add constraint empl_department_fk
  foreign key ( department_id )
  references departments;
  
alter session set constraints = immediate;

cl scr