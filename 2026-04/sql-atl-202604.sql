


/* Show all the locations and their countries */
/* M:1 join -- duplicates country rows: expected and OK */
select loca.street_address, coun.country_name 
from   hr.locations loca -- from many 
join   hr.countries coun -- to one
on     loca.country_id = coun.country_id;







/* New requirement: only show addresses with a registered department */





/* Locations -> departments is 1:M 
   Joining departments duplicates locations: this is bad :( */
select loca.street_address, coun.country_name 
from   hr.locations loca   -- from many 
join   hr.countries coun   -- to one
on     loca.country_id = coun.country_id
join   hr.departments dept -- to many 
on     dept.location_id = loca.location_id;







/* Instead of a join should have used EXISTS 
   Only show locations with registered department */
select loca.street_address, coun.country_name 
from   hr.locations loca
join   hr.countries coun
on     loca.country_id = coun.country_id
where  exists (
  select 'a department' from hr.departments dept
  where  dept.location_id = loca.location_id
);


/* Joining vs existence is an easy mistake to make! */






/* Introducing JOIN TO ONE: new join syntax to reduce these mistakes */
select loca.street_address, coun.country_name 
from   hr.locations loca -- from many 
join   to one ( 
  hr.countries coun      -- to one
);







/* By default, JOIN TO ONE uses FK->PK relationships for join condition
   Locations -> departmetns is PK->FK => error */
select loca.street_address, coun.country_name 
from   hr.locations loca -- from many 
join   to one ( 
  hr.countries coun,     -- to one 
  hr.departments dept    -- to many
);





/* You can write join condition explicitly 
   => runtime error when reading second DEPT row for one LOCA */
select loca.street_address, coun.country_name 
from   hr.locations loca -- from many 
join   to one ( 
  hr.countries coun,     -- to one
  hr.departments dept    -- to many
    on dept.location_id = loca.location_id -- LOCA -> DEPT join
);





/* Note: multiple row error detected at runtime 
   If no duplicates fetched, no error  */
select loca.street_address, coun.country_name 
from   hr.locations loca -- from many 
join   to one ( 
  hr.countries coun,     -- to one
  hr.departments dept    -- to many
    on dept.location_id = loca.location_id -- LOCA -> DEPT join
)
fetch first row only;
/* Must use explicit joins if there's no FK or multiple FKs from many to one */





/* Need explicit join to resolve which table JOBS joins to */
select * 
from   hr.job_history johi  -- from many 
join   to one (
  hr.employees emp,         -- to one
  hr.jobs                   -- from JOB_HISTORY or EMPLOYEES?
);




select first_name, start_date, end_date, 
       hijo.job_title as previous_job, 
       emjo.job_title as current_job
from   hr.job_history johi  -- from many 
join   to one (
  hr.employees emp,         -- to one
  hr.jobs hijo              -- to one
    on johi.job_id = hijo.job_id,
  hr.jobs emjo              -- to one
    on emp.job_id = emjo.job_id
);








/* Order of tables is important! */
select dept.department_name, 
       count ( emp.first_name ) emp#,
       listagg ( emp.first_name, ', ' ) emp_names
from   hr.departments dept -- from many 
join   to one ( 
  hr.employees emp         -- to one
)  
group  by all;






/* There is a DEPT -> EMP FK on the DEPT.MANAGER_ID */
select constraint_name, r_constraint_name 
from   all_constraints 
where  owner = 'HR'
and    constraint_type = 'R'
and    table_name = 'DEPARTMENTS';







/* EMP -> DEPT via department FK */
select dept.department_name, 
       count ( emp.employee_id ) emp#,
       listagg ( emp.first_name, ', ' ) emp_names
from   hr.employees emp  -- from many 
join   to one ( 
  hr.departments dept    -- to one
)
group  by all;






/* Also note: JOIN TO ONE defaults to LEFT OUTER JOINs - see plan for previous query */






/* Can specify join type explicitly before table name to make inner */
select dept.department_name, dept.location_id,
       count ( emp.employee_id ) emp#,
       listagg ( emp.first_name, ', ' ) emp_names
from   hr.employees emp           -- from many 
join   to one ( 
  inner join hr.departments dept  -- to one
)
group  by all;






/* Order of tables in JOIN TO ONE is also important:
   FKs inspected in order! */
select * 
from   hr.employees emp -- from many 
join   to one (
  hr.locations loca,    -- to ???
  hr.departments dept
);





/* Swap table order in JOIN TO ONE to fix */
select * 
from   hr.employees emp -- from many 
join   to one (
  hr.departments dept,  -- to one
  hr.locations loca     -- to one
);





/* Can list many tables in JOIN TO ONE */
select emp.first_name, regi.region_name
from   hr.employees emp -- from many 
join   to one (
  hr.departments dept,  -- to one
  hr.locations loca,    -- to one
  hr.countries coun,    -- to one
  hr.regions regi       -- to one
);


/**********************************




**********************************/