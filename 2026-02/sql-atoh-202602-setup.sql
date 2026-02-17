drop view if exists employee_project_skills;
drop table if exists employee_projects cascade constraints purge;
drop table if exists employee_skills cascade constraints purge;
drop table if exists project_skills cascade constraints purge;
drop table if exists employee_addresses cascade constraints purge;
drop table if exists employee_salaries cascade constraints purge;
drop table if exists employees cascade constraints purge;
drop table if exists employee_project_skills cascade constraints purge;

create table employee_project_skills ( 
  employee varchar2(30), 
  project  varchar2(30),
  skill    varchar2(30),
  primary key ( employee, project, skill )
);

insert into employee_project_skills
set   ( employee = 'Sally', skill = 'SQL', project = 'Mercury' ),
      ( employee = 'Jasper', skill = 'Java', project = 'Mercury' ),
      ( employee = 'Praveen', skill = 'Project Management', project = 'Mercury' );

commit;

create table employees ( 
  employee     varchar2(10), 
  salary       number, 
  main_address json,
  start_date   date, 
  end_date     date,
  primary key ( employee, start_date )
);

insert into employees 
set ( employee = 'Sally', salary = 50000, main_address = json { 'street' : '1 Main St' }, start_date = date'2020-01-01', end_date = date'2024-06-06' ),
    ( employee = 'Sally', salary = 55000, main_address = json { 'street' : '1 Main St' }, start_date = date'2020-06-06', end_date = date'2025-11-11' ),
    ( employee = 'Sally', salary = 50000, main_address = json { 'street' : '99 Low St' }, start_date = date'2025-11-11', end_date = null );

commit;

