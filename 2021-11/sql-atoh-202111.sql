alter session set tracefile_identifier = chris;
/* Capture parsing details */
alter session set events '10053 trace name context forever, level 1';

select * from hr.departments
where  department_id in ( 
  select distinct department_id 
  from   hr.employees
  where  salary > 10000
);

alter session set events '10053 trace name context off';








/* View tracefiles (12.2) */
select * from v$diag_trace_file_contents;



/* Get transformed query */
with rws as (
  select payload, line_number,
         last_value ( 
           case 
             when payload like '%Final query after transformation%' then line_number
           end 
         ) ignore nulls over ( 
           partition by trace_filename
           order by line_number
           rows between 1 preceding and current row
         ) final_q_ln
  from   v$diag_trace_file_contents c
  where  trace_filename like '%CHRIS.trc'
  and    timestamp > sysdate - interval '1' hour
)
  select * from rws
  where  final_q_ln is not null;

/*
select "DEPARTMENTS"."DEPARTMENT_ID"   "DEPARTMENT_ID",
       "DEPARTMENTS"."DEPARTMENT_NAME" "DEPARTMENT_NAME",
       "DEPARTMENTS"."MANAGER_ID"      "MANAGER_ID",
       "DEPARTMENTS"."LOCATION_ID"     "LOCATION_ID"
from "HR"."EMPLOYEES"   "EMPLOYEES",
     "HR"."DEPARTMENTS" "DEPARTMENTS"
where "DEPARTMENTS"."DEPARTMENT_ID" = "EMPLOYEES"."DEPARTMENT_ID"
      and "EMPLOYEES"."SALARY" > 10000
*/





/* Transformations in (non)action! */
/* Remove constraints */
alter table hr.employees
  modify constraint emp_dept_fk
  disable;  
  
alter table hr.employees
  modify constraint emp_emp_id_pk
  disable cascade;  



/* Reads both tables; depts first */
select distinct * 
from   hr.employees
join   hr.departments
using  ( department_id );





/* Remove select * => reads emps first */
select distinct e.employee_id, e.first_name 
from   hr.employees e
join   hr.departments
using  ( department_id );





/* Re-enable FK constraint */
alter table hr.employees
  modify constraint emp_dept_fk
  enable;
  
  

/* FK enabled => what happens to departments? */
select distinct e.employee_id, e.first_name 
from   hr.employees e
join   hr.departments
using  ( department_id );




/* Re-enable PK for employees */
alter table hr.employees
  modify constraint emp_emp_id_pk
  enable;  
  
/* PK enabled => what's going to happen to DISTINCT? */
select distinct e.employee_id, e.first_name 
from   hr.employees e
join   hr.departments
using  ( department_id );




/* Remove nulls in FK columns => make NN */
delete hr.employees 
where  department_id is null;

alter table hr.employees 
  modify department_id not null;

/* Remove bad data => index scans */
select distinct e.employee_id, e.first_name 
from   hr.employees e
join   hr.departments
using  ( department_id );





/* Why not write this to start? */
select e.employee_id, e.first_name  
from   hr.employees e
where  e.department_id is not null;


/*
  No PK => could be duplicate rows
  No FK => could be 1:M relationship
*/ 





/* Reset */
alter table hr.employees 
  modify department_id null;
    
insert into hr.employees values 
  ( 178 , 'Kimberely' , 'Grant' , 'KGRANT' , '011.44.1644.429263' , TO_DATE('24-05-2007', 'dd-MM-yyyy') , 'SA_REP'
   , 7000, .15, 149, NULL );
commit; 





/* Subqueries <> order-of-processing */
with dept_employee_counts as (
  select department_id, job_id, 
         count (*) emp_count
  from   hr.employees
  group  by department_id, job_id 
)
  select department_id 
  from   hr.departments d
  join   dept_employee_counts 
  using  ( department_id )
  where  location_id in ( 
    select location_id 
    from   hr.locations
    where  country_id = 'UK'
  );








/* Impossible (always false) search criteria */
select * from hr.employees
where  1 = 0;





drop table employees
  cascade constraints purge;
drop table departments
  cascade constraints purge;
  
  
  
/* Impossible where => read zero rows from employees! */
create table employees as 
  select * from hr.employees
  where  1 = 0;
  
  
create table departments ( 
  department_id primary key,
  department_name unique not null,
  manager_id, 
  location_id
) as 
  select * from hr.departments;
 
create index emp_dept_i
  on employees ( department_id );
  
create index emp_email_i
  on employees ( email );

  
alter table employees
  add constraint emp_dep_fk
  foreign key ( department_id )
  references departments ( department_id );
  
insert into employees
with rws as (
  select level+1000 x from dual
  connect by level <= 100000
)
  select x, null, 'Doe','Doe' || x || '@example.com',
         null, sysdate, 'AC_ACCOUNT', null, null, null, 50 
  from   rws;
  
commit;



set serveroutput off

select *
from   employees e
join   departments d
using  ( department_id )
where  e.email = 'SSTILES' or 
       d.department_name = 'Treasury';
       
select * 
from   dbms_xplan.display_cursor( format => 'BASIC LAST' );





alter session set tracefile_identifier = or_expand;
/* Capture parsing details */
alter session set events '10053 trace name context forever, level 1';

select *
from   employees e
join   departments d
using  ( department_id )
where  e.email = 'SSTILES' or d.department_name = 'Treasury';

alter session set events '10053 trace name context off';

/* Get transformed query */
with rws as (
  select payload, line_number,
         last_value ( 
           case 
             when payload like '%Final query after t%' then line_number
           end 
         ) ignore nulls over ( 
           partition by trace_filename
           order by line_number
           rows between 1 preceding and current row
         ) final_q_ln
  from   v$diag_trace_file_contents c
  where  trace_filename like '%OR_EXPAND.trc'
  and    timestamp > sysdate - interval '1' hour
)
  select * from rws
  where  final_q_ln is not null;

select "VW_ORE_9CEC7F3F"."ITEM_1"  "DEPARTMENT_ID",
       "VW_ORE_9CEC7F3F"."ITEM_2"  "EMPLOYEE_ID",
       "VW_ORE_9CEC7F3F"."ITEM_3"  "FIRST_NAME",
       "VW_ORE_9CEC7F3F"."ITEM_4"  "LAST_NAME",
       "VW_ORE_9CEC7F3F"."ITEM_5"  "EMAIL",
       "VW_ORE_9CEC7F3F"."ITEM_6"  "PHONE_NUMBER",
       "VW_ORE_9CEC7F3F"."ITEM_7"  "HIRE_DATE",
       "VW_ORE_9CEC7F3F"."ITEM_8"  "JOB_ID",
       "VW_ORE_9CEC7F3F"."ITEM_9"  "SALARY",
       "VW_ORE_9CEC7F3F"."ITEM_10" "COMMISSION_PCT",
       "VW_ORE_9CEC7F3F"."ITEM_11" "MANAGER_ID",
       "VW_ORE_9CEC7F3F"."ITEM_12" "DEPARTMENT_NAME",
       "VW_ORE_9CEC7F3F"."ITEM_13" "MANAGER_ID",
       "VW_ORE_9CEC7F3F"."ITEM_14" "LOCATION_ID"
from (
  (select "D"."DEPARTMENT_ID"   "ITEM_1",
          "E"."EMPLOYEE_ID"     "ITEM_2",
          "E"."FIRST_NAME"      "ITEM_3",
          "E"."LAST_NAME"       "ITEM_4",
          "E"."EMAIL"           "ITEM_5",
          "E"."PHONE_NUMBER"    "ITEM_6",
          "E"."HIRE_DATE"       "ITEM_7",
          "E"."JOB_ID"          "ITEM_8",
          "E"."SALARY"          "ITEM_9",
          "E"."COMMISSION_PCT"  "ITEM_10",
          "E"."MANAGER_ID"      "ITEM_11",
          "D"."DEPARTMENT_NAME" "ITEM_12",
          "D"."MANAGER_ID"      "ITEM_13",
          "D"."LOCATION_ID"     "ITEM_14"
  from "CHRIS"."DEPARTMENTS" "D",
       "CHRIS"."EMPLOYEES"   "E"
  where "E"."EMAIL" = 'SSTILES'
        and "E"."DEPARTMENT_ID" = "D"."DEPARTMENT_ID"
  )
  union all
  (select "D"."DEPARTMENT_ID"   "ITEM_1",
          "E"."EMPLOYEE_ID"     "ITEM_2",
          "E"."FIRST_NAME"      "ITEM_3",
          "E"."LAST_NAME"       "ITEM_4",
          "E"."EMAIL"           "ITEM_5",
          "E"."PHONE_NUMBER"    "ITEM_6",
          "E"."HIRE_DATE"       "ITEM_7",
          "E"."JOB_ID"          "ITEM_8",
          "E"."SALARY"          "ITEM_9",
          "E"."COMMISSION_PCT"  "ITEM_10",
          "E"."MANAGER_ID"      "ITEM_11",
          "D"."DEPARTMENT_NAME" "ITEM_12",
          "D"."MANAGER_ID"      "ITEM_13",
          "D"."LOCATION_ID"     "ITEM_14"
  from "CHRIS"."DEPARTMENTS" "D",
       "CHRIS"."EMPLOYEES"   "E"
  where "D"."DEPARTMENT_NAME" = 'Treasury'
        and "E"."DEPARTMENT_ID" = "D"."DEPARTMENT_ID"
        and lnnvl ("E"."EMAIL" = 'SSTILES')
  )
) "VW_ORE_9CEC7F3F"




/* Questions? */












/* Cursor-duration temp tables */
with country_summaries as (
  /* Get the number of departments/country 
     Along with one department in that country 
  */
  select country_id, count (*) c, 
         any_value ( department_id ) department_id
  from   hr.departments
  join   hr.locations 
  using  ( location_id )
  group  by country_id
)
  select e.employee_id, e.first_name, d.*, 
         m.employee_id, m.first_name, md.* 
  from   hr.employees e
  join   country_summaries d
  on     e.department_id = d.department_id
  left join hr.employees m
  on     m.employee_id = e.manager_id
  left join country_summaries md
  on     m.department_id = md.department_id;