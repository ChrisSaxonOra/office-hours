



/* LISTAGG aggregate */
select 
  department_id d_id, 
  listagg ( last_name, ',' ) names_random_order, 
  listagg ( last_name, ',' )
    within group ( order by employee_id ) names_by_id, 
  listagg ( last_name, ',' )
    within group ( order by last_name ) names_by_name
from   hr.employees
where  department_id in ( 20, 30, 60 )
group  by department_id;











/* Enclose values */
select 
  listagg ( '"' || last_name || '"', '; ' ) enclosed_names_semi_colon_separated, 
  listagg ( '~' || last_name || '~' ) enclosed_names_no_separator
from   hr.employees
where  department_id in ( 20, 30, 60 )
group  by department_id;





/* LISTAGG analytic */
select 
  department_id, last_name,
  listagg ( last_name, ',' )
    over ( partition by department_id ) dept_names, 
  listagg ( last_name, ',' )
    over () all_names
from   hr.employees
where  department_id in ( 20, 30, 60 );





/* Analytic with GROUP BY? */
select 
  department_id, 
  listagg ( last_name, ',' )
    over () all_names_by_name
from   hr.employees
group  by department_id;





/*
ORA-00979: not a GROUP BY expression
*/




/* Expand it out */
with rws as (
  select 
    department_id, 
    last_name
  from   hr.employees
  group  by department_id
)
  select 
    department_id, 
    listagg ( last_name, ',' )
      over () all_names_by_name
  from   rws;




/* It's the same problem as this */
select min ( last_name ) over ()
from   hr.employees
group  by department_id;





/* Add expression to GROUP BY */
select department_id, last_name, 
       min ( last_name ) over ()
from   hr.employees
group  by department_id, last_name;

/* Nesting aggregate inisde an analytic (this makes my head hurt!) */
select department_id, 
       min ( last_name ), 
       max ( min ( last_name ) ) over ()
from   hr.employees
group  by department_id;








/* GROUP BY expression */
select 
  department_id, last_name,
  listagg ( last_name, ',' )
    over ( partition by department_id ) dept_names
from   hr.employees
where  department_id in ( 20, 30, 60 )
group  by department_id, last_name;





/* Aggregate expression inside listagg */
select 
  department_id, 
  -- List of lowest surname in each department
  listagg ( min ( last_name ), ',' )
    over () all_lowest_names
from   hr.employees
where  department_id in ( 20, 30, 60 )
group  by department_id;



/* ...which is like */
with dept_lowest_names as (
  select 
    department_id, 
    min ( last_name ) lowest_last_name
  from   hr.employees
  where  department_id in ( 20, 30, 60 )
  group  by department_id
)
select 
  department_id, 
  listagg ( lowest_last_name, ',' )
    over () all_lowest_names
from   dept_lowest_names;















/* Analytic and aggregate in same query!? */
select 
  department_id, last_name,
  -- Number of people with same last name in each department
  count (*),
  -- List the first names of everyone with the same last name in a dept
  listagg ( first_name, ',' ) aggregate_first_names,
  -- List all the unique last names in the department
  listagg ( last_name, ',' )
    over ( partition by department_id ) window_last_names
from   hr.employees
group  by department_id, last_name
-- adding/removing this changes window but not aggregate!
--having count (*) > 1 
order  by count (*) desc;



/* Expand to make clear */
with last_name_stats_per_dept as (
  select 
    department_id, 
    last_name,
    count (*) c,
    listagg ( first_name, ',' ) first_names
  from   hr.employees
  group  by department_id, last_name
)
  select 
    department_id, last_name,
    c, first_names,
    listagg ( last_name, ',' )
      over ( partition by department_id ) unique_dept_last_names
  from   last_name_stats_per_dept
  order  by c desc;














/* Can't use ORDER BY in window clause */
select 
  department_id, last_name,
  listagg ( last_name, ',' )
    over ( order by department_id ) all_names_by_dept_id
from   hr.employees
where  department_id in ( 20, 30, 60 );
/*
ORA-30487: ORDER BY not allowed here
*/





/* "Running CSV" using recursive with */
with rws as (
  select e.*, 
         row_number() over ( 
           partition by department_id 
           order by employee_id 
         ) rn
  from   hr.employees e
  where  department_id = 30
), running_names ( 
  employee_id, department_id, rn, last_name, name_list 
) as (
  select employee_id, department_id, rn, last_name, last_name
  from   rws r
  where  rn = 1
  union all
  select r.employee_id, r.department_id, r.rn, r.last_name, 
         rn.name_list || ',' || r.last_name
  from   rws r
  join   running_names rn
  on     r.department_id = rn.department_id
  and    r.rn - 1 = rn.rn
) 
  select * from running_names;



/* "Sliding window CSV" using model */
select * 
from   hr.employees
where  department_id = 30
model 
  dimension by ( 
    row_number () over ( order by employee_id ) rn 
  )
  measures ( 
    department_id, employee_id, last_name,
    cast ( ' ' as varchar2(100 ) ) strlist
  ) (
    strlist[any] = 
      last_name[cv()] || 
      case when last_name[cv()-1] is not null then
        ',' || last_name[cv()-1] 
      end  || 
      case when last_name[cv()-2] is not null then
        ',' || last_name[cv()-2] 
      end 
  );

  
/*****************************************






*****************************************/
  
/* Overflow */
select 
  owner, 
  listagg ( object_name ) 
    within group ( order by object_name )
from   dba_objects
group  by owner;




/* Truncate output */
with rws as (
  select 
    owner, 
    listagg ( 
      object_name, ', ' 
      on overflow truncate 
    ) within group ( order by object_name ) default_trunc, 
    listagg ( 
      object_name, ', ' 
      on overflow truncate 
        'more' without count
    ) within group ( order by object_name ) no_count_trunc
  from   dba_objects
  group  by owner
)
  select owner, 
         substr ( default_trunc, -40, 40 ) default_trunc, 
         substr ( no_count_trunc, -40, 40 ) no_count_trunc
  from   rws
  where  no_count_trunc like '%more';




/* Split into groups <= length */
with rws as (
  select owner, object_name, grp
  from   dba_objects 
    match_recognize (
      partition by owner
      order by object_name
      measures
        match_number() as grp
      all rows per match
      pattern ( init len* )
      define 
        len as lengthb ( init.object_name ) 
          + sum ( lengthb ( len.object_name ) + lengthb ( ', ') ) <= 80
    )
  where  owner in ( 'HR', 'SH', 'CO' )
)
  select 
    owner, grp,
    listagg ( object_name, ', ' )
  from   rws
  group  by owner, grp;
  



/* CSV CLOB XML - slow! */
select
  owner, 
  xmlagg (
    xmlelement ( e, object_name, ', ' ).extract ('//text()')
      order by object_name
  ).getclobval () name_csv
from   dba_objects
group by owner;




/* CSV CLOB - JSON array (18c) */
select
  owner, 
  json_arrayagg ( 
    distinct object_name
    order by object_name 
    returning clob 
  ) name_array
from   dba_objects
group by owner;

  


/* Remove duplicate names */
select 
  owner, 
  listagg ( distinct object_name, ', ' ) 
    within group ( order by object_name ) object_names
from   dba_objects
where  owner = 'SH'
group  by owner;




  
  
/* List of object types/schema */
select 
  owner, 
  listagg ( distinct object_type, ', ' ) 
    within group ( order by object_type ) object_types
from   dba_objects
group  by owner;





/* DISTINCT still works when sorting by another column */
select 
  owner, 
  listagg ( distinct object_type, ', ' ) 
    within group ( order by object_id ) unique_object_types_by_id, 
  listagg ( distinct object_type, ', ' ) 
    within group ( order by object_name ) unique_object_types_by_name
from   dba_objects
where  owner in ( 'HR', 'CO' )
group  by owner;




/* But how many objects were there? */
/* Group to get the object counts */
select distinct 
  owner, 
  listagg ( object_type || ' (' || count(*) || ')', ', ' ) 
    within group ( order by object_type ) 
    over ( partition by owner ) object_types
from   dba_objects
where  owner in ( 'HR', 'CO', 'SH' )
group  by owner, object_type
order  by owner;




/* List of object counts per schema */
with schema_object_counts as (
  select owner, object_type, count(*) c
  from   dba_objects 
  where  owner in ( 'HR', 'CO', 'SH' )
  group  by owner, object_type
)
  select 
    owner, 
    listagg ( object_type || ' (' || c || ') ', ', ' )
      within group ( order by object_type ) objects
  from   schema_object_counts
  group  by owner
  order  by owner;
  




/* Unique names and types? */
select 
  owner, 
  listagg ( distinct object_type, ', ' ) 
    within group ( order by object_type ) object_types, 
  listagg ( distinct object_name, ', ' on overflow truncate ) 
    within group ( order by object_name ) object_names
from   dba_objects
where  owner in ( 'HR', 'CO', 'SH' )
group  by owner;








/* Unique names & types pre LISTAGG DISTINCT */
with schema_object_counts as (
  select owner, object_type, object_name,
         row_number () over ( 
           partition by owner, object_type
           order by object_id
         ) type_rn,
         row_number () over ( 
           partition by owner, object_name
           order by object_id 
         ) name_rn
  from   dba_objects 
  where  owner in ( 'HR', 'CO', 'SH' )
)
  select 
    owner, 
    listagg ( 
      case when type_rn = 1 then object_type end, ', ' 
    ) within group ( order by object_type ) objects, 
    listagg ( 
      case when name_rn = 1 then object_name end, ', ' 
      on overflow truncate 
    ) within group ( order by object_name ) names
  from   schema_object_counts
  group  by owner
  order  by owner;