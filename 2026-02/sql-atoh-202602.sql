@sql-atoh-202602-setup.sql

select * from employee_project_skills;










-- Cancel project Mercury...
delete employee_project_skills
where  project = 'Mercury';

-- ... and no-one has an skills anymore!
select * from employee_project_skills;

rollback;





-- We can't add new employe skills without a project...
insert into employee_project_skills 
set   employee = 'Quinn', skill = 'SQL';




-- ...Adding new rows duplicates values 
insert into employee_project_skills 
set   employee = 'Sally', skill = 'SQL', project = 'Venus';


select * from employee_project_skills;

rollback;





-- Let's fix it: create two separate tables
create table employee_skills ( 
  employee varchar2(30), 
  skill    varchar2(30),
  primary key ( employee, skill )
);

create table employee_projects ( 
  employee varchar2(30), 
  project  varchar2(30),
  primary key ( employee, project )
);



/* Split data into normalized tables */
insert into employee_skills
by name 
  select distinct employee, skill 
  from   employee_project_skills;

insert into employee_projects
by name 
  select distinct employee, project
  from   employee_project_skills;

commit;


select * from employee_skills;
select * from employee_projects;





/* We can now add employee skills without projects */ 
insert into employee_skills 
set   ( employee = 'Sally', skill = 'PL/SQL' ),
      ( employee = 'Quinn', skill = 'PL/SQL' );

/* and vice-versa */
insert into employee_projects
set   ( employee = 'Sally', project = 'Venus' ),
      ( employee = 'Lisa', project = 'Venus' );

commit;

select * from employee_skills;
select * from employee_projects;





/* Can remove projects without impacting skills */
delete employee_projects
where  project = 'Mercury';


select * from employee_projects;
select * from employee_skills;

rollback;





-- Re-create original table as a view (if needed)
drop table if exists employee_project_skills cascade constraints purge;

create or replace view employee_project_skills as 
  select * from employee_projects
  full join employee_skills 
  using ( employee );

/* Cross product of an employee's skills and projects */
select * from employee_project_skills
order  by employee, project;




/************************************



************************************/

-- reset
@sql-atoh-202602-setup.sql

select * from employee_project_skills;





/* Assign Quinn to Mercury to for their SQL skills
   Sally and Quinn to Venus for their PL/SQL skills
*/
insert into employee_project_skills 
set   ( employee = 'Quinn', project = 'Mercury', skill = 'SQL' ),
      ( employee = 'Quinn', project = 'Venus', skill = 'PL/SQL' ),
      ( employee = 'Sally', project = 'Venus', skill = 'PL/SQL' );

commit;

/* Assigned to project for their skills => 4NF */
select * from employee_project_skills;





/* But what about 5NF? */
/* Rule: everyone uses the skills they have on their projects that need them */







/* 5NF: decompse into three tables */
create table employee_skills ( 
  employee varchar2(30), 
  skill    varchar2(30),
  primary key ( employee, skill )
);

create table employee_projects ( 
  employee varchar2(30), 
  project  varchar2(30),
  primary key ( employee, project )
);

create table project_skills ( 
  project  varchar2(30),
  skill    varchar2(30),
  primary key ( project, skill )
);

/* Transform existing data */
insert into project_skills
by name 
  select distinct project, skill 
  from   employee_project_skills;

insert into employee_skills
by name 
  select distinct employee, skill 
  from   employee_project_skills;

insert into employee_projects
by name 
  select distinct employee, project
  from   employee_project_skills;

commit;





/* We can reconstruct original table with joins */
create or replace view joined_tables as 
  select employee, project, skill 
  from   employee_projects
  join   employee_skills 
  using ( employee )
  join   project_skills 
  using ( project, skill );

select * from joined_tables;









/* Venus also needs SQL skills */
insert into project_skills 
set    project = 'Venus', skill = 'SQL';

/* Sally and Quinn have SQL skills
   and they're already assigned to Venus
   => they use their SQL skills on Venus */
select * from joined_tables
where  project = 'Venus';

/* In original table needed two inserts */
insert into employee_project_skills 
set    ( employee = 'Sally', project = 'Venus', skill = 'SQL' ),
       ( employee = 'Quinn', project = 'Venus', skill = 'SQL' );

select * from employee_project_skills
where  project = 'Venus';
select * from joined_tables
where  project = 'Venus';

commit;




/* Venus no longer requires PL/SQL skills 
   Decompose => delete one row */
delete project_skills
where  project = 'Venus'
and    skill = 'PL/SQL';

/* Venus no longer requires PL/SQL skills 
   Decompse => delete many rows */
delete employee_project_skills
where  project = 'Venus'
and    skill = 'PL/SQL';

select * from employee_project_skills
where  project = 'Venus';
select * from joined_tables
where  project = 'Venus';

rollback;



/* Compare joins to original table
   If this should return no rows => need the split tables 
   If this should return rows    => keep employee_project_skills table */
with split as (
  select 'split' t1, employee, project, skill 
  from   joined_tables 
), original as ( 
  select 'original' t2, eps.* from employee_project_skills eps
)
select * from original
natural full join split
where  t1 is null or t2 is null;




/************************************



************************************/

@sql-atoh-202602-setup.sql

/* Employee salary and address history */
select * from employees;
-- Duplicate salary and addresses
-- Incorrectly lowered Sally's pay




-- Fix: split into two tables
drop table if exists employees cascade constraints purge;
create table employees ( 
  employee varchar2(10) primary key
);

create table employee_salaries ( 
  employee            references employees,
  salary              number, 
  effective_from_date date, 
  effective_to_date   date,
  primary key ( employee, effective_from_date )
);

create table employee_addresses (
  employee            references employees,
  main_address        json,
  effective_from_date date, 
  effective_to_date   date,
  primary key ( employee, effective_from_date )
);

insert into employees set employee = 'Sally';

insert into employee_salaries
set ( employee = 'Sally', salary = 50000, effective_from_date = date'2020-01-01', effective_to_date = date'2025-11-11' ),
    ( employee = 'Sally', salary = 55000, effective_from_date = date'2025-11-11', effective_to_date = null );

insert into employee_addresses
set ( employee = 'Sally', main_address = json { 'street' : '1 Main St' }, effective_from_date = date'2020-01-01', effective_to_date = date'2024-06-06' ),
    ( employee = 'Sally', main_address = json { 'street' : '99 Low St' }, effective_from_date = date'2024-06-06', effective_to_date = null );

commit;






/* How to find employee current addresses and salaries?
   Write the WHERE clause yourself? :(
   Use temporal validity? :) */






/* Add temporal periods to tables */
alter table employee_salaries 
  add period for pay ( effective_from_date, effective_to_date );

alter table employee_addresses
  add period for residence ( effective_from_date, effective_to_date );





-- AS OF PERIOD FOR finds the active rows on that date
select * from employees 
join   employee_salaries as of period for pay sysdate emsa
using ( employee )
join   employee_addresses as of period for residence sysdate emad
using ( employee );


select * from employees 
join   employee_salaries as of period for pay date'2024-01-01' emsa
using ( employee )
join   employee_addresses as of period for residence date'2024-01-01' emad
using ( employee );







/* How about seeing history? */
/* Get the changes in a time period */
select * from employee_salaries 
  versions period for pay 
  between date'2025-01-01' and sysdate emsa;





/* ...how about full history? */
select * from employees 
join   employee_salaries emsa
using ( employee )
join   employee_addresses emad
using ( employee );






/* Can't pass columns to do a temporal join :( */
select * from employee_salaries es
cross apply ( 
  select * from employee_addresses 
    as of period for residence es.effective_from_date ea
  where  ea.employee = es.employee
);




-- Re-create their history
select e.employee,
       greatest (
         es.effective_from_date, ea.effective_from_date
       ) as effective_from_date,
       least(
         nvl ( es.effective_to_date, date '9999-12-31' ),
         nvl ( ea.effective_to_date, date '9999-12-31' )
       ) as effective_to_date,
       es.salary,
       ea.main_address
from  employees e 
join  employee_salaries es
on    e.employee = es.employee
join  employee_addresses ea
on    ea.employee = e.employee
and   es.effective_from_date < nvl ( ea.effective_to_date, date'9999-12-31' )
and   ea.effective_from_date < nvl ( es.effective_to_date, date'9999-12-31' )
order by es.employee,  effective_from_date;



/* Note: only shows periods employee has both a salary and address! */
insert into employee_salaries 
set    employee = 'Sally', 
       salary   = 45000,
       effective_from_date = date'2000-01-01', 
       effective_to_date = date'2010-01-01';

insert into employee_addresses
set    employee = 'Sally', 
       main_address = json { 'street' : '42 Old Lane' },
       effective_from_date = date'2000-01-01', 
       effective_to_date = date'2020-01-01';

commit;



/* To show missing from one table */
with ranges as (
  /* Get the unique from/to dates */
  select employee, effective_from_date, effective_to_date from employee_addresses
  union  all
  select employee, effective_from_date, effective_to_date from employee_salaries
), dates as (
  /* Convert into a list of dates */
  select distinct employee, dt 
  from   ranges 
  unpivot ( 
    dt for col in ( effective_from_date, effective_to_date )
  )
)
select e.employee, 
       dt, lead ( dt ) over ( partition by e.employee order by dt ) end,
       salary, 
       main_address
from   dates e
left join  employee_salaries es
on    e.employee = es.employee
/* Find the row active on this date */
and   es.effective_from_date <= e.dt
and   e.dt < nvl ( es.effective_to_date, date'9999-12-31' )
left join  employee_addresses ea
on    ea.employee = e.employee
/* Find the row active on this date */
and   ea.effective_from_date <= e.dt
and   e.dt < nvl ( ea.effective_to_date, date'9999-12-31' )
order  by dt;



/* Overlapping dates ranges :( */
insert into employee_salaries 
set    employee = 'Sally', 
       salary   = 33333,
       effective_from_date = date'2001-01-01', 
       effective_to_date = date'2005-01-01';

rollback;




/* Stop overlapping effective dates */
create assertion no_overlapping_salaries 
check (
  all (
    select * 
    from   employee_salaries e
  ) sal
  satisfy ( 
    not exists (
      select 'an overlapping range'
      from   employee_salaries overlap
      where  sal.employee = overlap.employee 
      and    sal.effective_from_date < overlap.effective_from_date
      and    ( overlap.effective_from_date < sal.effective_to_date 
            or sal.effective_to_date is null )
    )
  )
);

/* Within existing range */
insert into employee_salaries 
set    employee = 'Sally', 
       salary   = 33333,
       effective_from_date = date'2001-01-01', 
       effective_to_date = date'2005-01-01';

/* Starts before first salary, ends after */
insert into employee_salaries 
set    employee = 'Sally', effective_from_date = date'2024-01-01';




/* Ensure all employees have a salary */
create assertion employee_must_have_salary
check (
  all (
    select * from employees
  ) emp 
  satisfy (
    exists ( 
      select 'there is a salary' 
      from   employee_salaries emsa
      where  emp.employee = emsa.employee 
    )
  )
)
/* Must delay validation to allow insert! */
deferrable initially deferred;




set constraints all immediate;

insert into employees 
set    employee = 'Quinn';

set constraints all deferred;

insert into employees 
set    employee = 'Quinn';

/* No salary inserted => error */
commit;


/* Load emps and their salaries in same transaction */
insert all 
  into employees 
  set  employee = emp_name
  into employee_salaries 
  set  employee = emp_name, salary = salary, effective_from_date = effective
select 'Quinn' as emp_name, 67890 as salary, trunc ( sysdate ) as effective;


select * from employees;
select * from employee_salaries;

/* Success! */
commit;


/*********************************




*********************************/


-- But only permanent staff have a salary!

/*
alter table employees 
  add employment_type varchar2(10) 
  default 'PERMANENT'
  check ( employment_type in ( 'PERMANENT', 'TEMPORARY', 'CONTRACTOR' ) );


drop assertion employee_must_have_salary;
create assertion permanent_employee_must_have_salary
check (
  all (
    select * from employees
    where  employment_type = 'PERMANENT'
  ) emp 
  satisfy (
    exists ( 
      select 'there is a salary' 
      from   employee_salaries emsa
      where  emp.employee = emsa.employee 
    )
  )
)
deferrable initially deferred;

insert into employees 
set    employee = 'Lisa', employment_type = 'CONTRACTOR';

-- All good; rule only applies to permanent staff
commit;

-- Lisa must have salary to become permanent
update employees 
set    employment_type = 'PERMANENT'
where  employee = 'Lisa'; 

commit;

/**/