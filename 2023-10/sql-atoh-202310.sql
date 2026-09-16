@@sql-atoh-202310-setup



select * from jobs;

select * from jobs_stage;







/* "Classic" approach */
select * from jobs 
minus 
select * from jobs_stage;


select * from jobs_stage
minus 
select * from jobs;



/* All together now! */
( 
  select * from jobs 
  minus 
  select * from jobs_stage
) union all (
  select * from jobs_stage
  minus 
  select * from jobs
)
order by 1;






/* But which rows are from which table??
   Add the source table */
select 't1' as t, t1.* from ( 
  select * from jobs 
  minus 
  select * from jobs_stage
) t1 
union all 
select 't2' as t, t2.* from (
  select * from jobs_stage
  minus 
  select * from jobs
) t2
order by 2;







/* Natural full join */
with t1 as (
  select 't1' as t1, t.* from jobs t
), t2 as (
  select 't2' as t2, t.* from jobs_stage t
)
select *
from   t1 t1
natural full join t2 t2
order  by job_id;





/* Get the mismatched rows */
with t1 as (
  select 't1' as t1, t.* from jobs t
), t2 as (
  select 't2' as t2, t.* from jobs_stage t
)
select *
from   t1 t1
natural full join t2 t2
/* Filter to show only the differences */
where  t1 is null or t2 is null
order  by job_id;







/* Only works if columns have same names & are mandatory! */
update jobs
set    max_salary = null;

update jobs_stage
set    max_salary = null;






/* Nulls => all mismatched! */
with t1 as (
  select 't1' as t1, t.* from jobs t
), t2 as (
  select 't2' as t2, t.* from jobs_stage t
)
select *
from   t1 t1
natural full join t2 t2
where  t1 is null or t2 is null
order  by job_id;




/* Qualified full join */
with t1 as (
  select 't1' as t1, t.* from jobs t
), t2 as (
  select 't2' as t2, t.* from jobs_stage t
)
select *
from   t1 t1
full join t2 t2
on     t1.job_id = t2.job_id
and    t1.job_title = t2.job_title
and    t1.min_salary = t2.min_salary
and    nvl ( t1.max_salary, -1 ) = nvl ( t2.max_salary, -1 )
where  t1 is null or t2 is null
order  by t1.job_id, t1.max_salary;










/* Get row as JSON object; json_object(*) is 19c simplification */
select 't1' t, job_id, json_object (*) jdoc_t1 from jobs;












/* JSON comparison */
with t1_json as (
  select 't1' t, job_id, json_object (*) jdoc_t1 from jobs
), t2_json as (
  select 't2' t, job_id, json_object (*) jdoc_t2 from jobs_stage
)
  select 
    coalesce ( m.job_id, s.job_id ) job_id,
    coalesce ( m.t, s.t ) src, 
    coalesce ( m.jdoc_t1, s.jdoc_t2 ) jdoc
  from   t1_json m
  full join t2_json s
  /* include PK in join for performance */
  on     m.job_id = s.job_id
  and    json_equal ( jdoc_t1, jdoc_t2 )
  /* return the unmatched rows from each table */
  where  m.job_id is null or s.job_id is null
  order  by job_id;










/* GROUP BY => one row/set of columns */
with rws as (
  select t.*, 1 t1, 0 t2 from jobs t
  union  all
  select t.*, 0 t1, 1 t2 from jobs_stage t
)
  select *
  from   rws
  order  by job_id;







/* Group by to combine rows */
with rws as (
  select t.*, 1 t1, 0 t2 from jobs t
  union  all
  select t.*, 0 t1, 1 t2 from jobs_stage t
)
  select job_id, job_title, min_salary, max_salary,
         sum ( t1 ), sum ( t2 )
  from   rws
  group  by job_id, job_title, min_salary, max_salary
  order  by job_id;
  
  



/* Return just the differences */
with rws as (
  select t.*, 1 t1, 0 t2 from jobs t
  union  all
  select t.*, 0 t1, 1 t2 from jobs_stage t
)
  select job_id, job_title, min_salary, max_salary,
         sum ( t1 ), sum ( t2 )
  from   rws
  group  by job_id, job_title, min_salary, max_salary
  /* Filter to only show mismatches */
  having sum ( t1 ) <> sum ( t2 )
  order  by job_id;
  
  
  
  
  

rollback;  










-- Add duplicate rows
insert into jobs select * from jobs where job_id = 'AC_MGR';
insert into jobs_stage select * from jobs_stage where job_id = 'SA_MAN';


select * from jobs order by job_id;
select * from jobs_stage order by job_id;







/* Re-run queries => show difference; extra rows missing */
( 
  select * from jobs 
  minus 
  select * from jobs_stage
) union all (
  select * from jobs_stage
  minus 
  select * from jobs
)
order  by 1;




/* MINUS ALL in 21c addresses this */
( 
  select * from jobs 
  minus all
  select * from jobs_stage
) union all (
  select * from jobs_stage
  minus all
  select * from jobs
)
order  by 1;





/* Full join - duplicates not shown */
with t1 as (
  select 't1' as t1, t.* from jobs t
), t2 as (
  select 't2' as t2, t.* from jobs_stage t
)
select *
from   t1 t1
natural full join t2 t2
where  t1 is null or t2 is null
order  by job_id;









/* Add row_number/set to results to de-duplicate */
select 't1' as t1, t.*,
       row_number () over ( partition by job_id order by 1 ) rn
from   jobs t;







with t1 as (
  select 't1' as t1, t.*,
         row_number () over ( partition by job_id order by 1 ) rn
  from   jobs t
), t2 as (
  select 't2' as t2, t.*, 
         row_number () over ( partition by job_id order by 1 ) rn
  from   jobs_stage t
)
select *
from   t1 t1
natural full join t2 t2
where  t1 is null or t2 is null
order  by job_id;





/* GROUP BY includes duplicates */
with rws as (
  select t.*, 1 t1, 0 t2 from jobs t
  union  all
  select t.*, 0 t1, 1 t2 from jobs_stage t
)
  select job_id, job_title, min_salary, max_salary,
         sum ( t1 ), sum ( t2 )
  from   rws
  group  by job_id, job_title, min_salary, max_salary
  having sum ( t1 ) <> sum ( t2 )
  order  by job_id;
  








/* LOBs */
alter table jobs add description clob default 'description';
alter table jobs_stage add description clob default 'description';








/* Set operations don't support LOBs */
( 
  select * from jobs 
  minus 
  select * from jobs_stage
) union all (
  select * from jobs_stage
  minus 
  select * from jobs
);




/* Same for UNION ALL ... GROUP BY */
with rws as (
  select e.*, 1 t1, 0 t2 from jobs e
  union  all
  select s.*, 0 t1, 1 t2 from jobs_stage s
)
  select job_id, job_title, min_salary, max_salary, description,
         sum ( t1 ), sum ( t2 )
  from   rws
  group  by job_id, job_title, min_salary, max_salary, description
  having sum ( t1 ) <> sum ( t2 )
  order  by job_id;




/* Neither to joins */
with t1 as (
  select 't1' as t1, t.* from jobs t
), t2 as (
  select 't2' as t2, t.* from jobs_stage t
)
select *
from   t1 t1
natural full join t2 t2
where  t1 is null or t2 is null
order  by job_id, max_salary;




/* ... need to DBMS_LOB.compare */
with t1 as (
  select 't1' as t1, t.* from jobs t
), t2 as (
  select 't2' as t2, t.* from jobs_stage t
)
select *
from   t1 t1
full join t2 t2
on     t1.job_id = t2.job_id
and    t1.job_title = t2.job_title
and    t1.min_salary = t2.min_salary
and    nvl ( t1.max_salary, -1 ) = nvl ( t2.max_salary, -1 )
and    dbms_lob.compare ( t1.description, t2.description ) = 0
where  t1 is null or t2 is null
order  by t1.job_id, t1.max_salary;







  



/* JSON comparison - works with LOB data! */
with t1_json as (
  select 't1' t, job_id, json_object (* returning json) jdoc_t1 from jobs
), t2_json as (
  select 't2' t, job_id, json_object (* returning json) jdoc_t2 from jobs_stage
)
  select 
    coalesce ( m.job_id, s.job_id ) job_id,
    coalesce ( m.t, s.t ) src, 
    coalesce ( m.jdoc_t1, s.jdoc_t2 ) jdoc
  from   t1_json m
  full join t2_json s
  on     m.job_id = s.job_id
  and    json_equal ( jdoc_t1, jdoc_t2 )
  -- return the unmatched rows from both tables
  where  m.job_id is null or s.job_id is null
  order  by 1;




/* Remove LOBs & duplicates */
alter table jobs drop column description;
alter table jobs_stage drop column description;

delete jobs where job_id = 'AC_MGR' and rownum = 1;
delete jobs_stage where job_id = 'SA_MAN' and rownum = 1;

commit;


/****************************************





****************************************/

/* Make it a function with SQL macros! */
create or replace function compare_tables ( 
  t1 dbms_tf.table_t, t2 dbms_tf.table_t, comparison_columns dbms_tf.columns_t
) return clob sql_macro as
  stmt clob;
  column_list clob;
begin

  for col in 1 .. comparison_columns.count loop
    column_list := column_list || comparison_columns ( col ) || ',';
  end loop;
  column_list := rtrim ( column_list, ',' );
  
  stmt := q'!
  select ##COLUMNS##,
         case 
           when sum ( t1 ) > sum ( t2 ) then 't1'
           else 't2'
         end as source_table
  from   (
    select t1.*, 1 t1, 0 t2 from t1
    union  all
    select t2.*, 0 t1, 1 t2 from t2
  )
  group  by ##COLUMNS##
  having sum ( t1 ) <> sum ( t2 ) !';
  
  stmt := replace ( stmt, '##COLUMNS##', column_list );

  return stmt;
end compare_tables;
/



select * from compare_tables ( 
  jobs, jobs_stage, 
  columns ( job_id, job_title, min_salary, max_salary ) 
);








/* Compare queries */
select j.*,
       ( select min ( min_salary ) from jobs ) min_min,
       ( select max ( max_salary ) from jobs ) max_max,
       ( select avg ( max_salary - min_salary ) from jobs ) avg_range,
       ( select count (*) from employees e where e.job_id = j.job_id ) emp#
from   jobs j;








/* Optimized query */
select j.*,
       min ( min_salary ) over () min_min,
       max ( max_salary ) over () max_max,
       avg ( max_salary - min_salary ) over () avg_range,
       count (*) emp#
from   jobs j
left join employees e
on     j.job_id = e.job_id
group  by j.job_id, j.job_title, j.min_salary, j.max_salary;







/* Put the queries in views */
create or replace view original_query as 
select j.*,
       ( select min ( min_salary ) from jobs ) min_min,
       ( select max ( max_salary ) from jobs ) max_max,
       ( select avg ( max_salary - min_salary ) from jobs ) avg_range,
       ( select count (*) from employees e where e.job_id = j.job_id ) emp#
from   jobs j;

create or replace view new_query as 
select j.*,
       min ( min_salary ) over () min_min,
       max ( max_salary ) over () max_max,
       avg ( max_salary - min_salary ) over () avg_range,
       count (*) emp#
from   jobs j
left join employees e
on     j.job_id = e.job_id
group  by j.job_id, j.job_title, j.min_salary, j.max_salary;



/* Are they the same? */
select * from compare_tables ( 
  original_query, new_query, 
  columns ( job_id, min_min, max_max, avg_range, emp# ) 
);











/* Fix it! */
create or replace view new_query as 
select j.*,
       min ( min_salary ) over () min_min,
       max ( max_salary ) over () max_max,
       avg ( max_salary - min_salary ) over () avg_range,
       count (e.job_id) emp# -- what's the problem?
from   jobs j
left join employees e
on     j.job_id = e.job_id
group  by j.job_id, j.job_title, j.min_salary, j.max_salary;





/* Check the solution */
select * from compare_tables ( 
  original_query, new_query, 
  columns ( job_id, min_min, max_max, avg_range, emp# ) 
);






/* back to the original tables */
select * from compare_tables ( 
  jobs, jobs_stage, 
  columns ( job_id, job_title, min_salary, max_salary ) 
);



/* Check changes over time! */
merge into jobs j
using jobs_stage s
on   ( j.job_id = s.job_id )
when not matched then 
  insert values ( s.job_id, s.job_title, s.min_salary, s.max_salary )
when matched then 
  update
  set    j.job_title = s.job_title, j.min_salary = s.min_salary, j.max_salary = s.max_salary;

commit;


/* Changes from stage copied to main table */
select * from compare_tables ( 
  jobs, jobs_stage, 
  columns ( job_id, job_title, min_salary, max_salary ) 
);
/* But what changed exactly? */



/* View the table in the past */
select * from jobs as of timestamp sysdate - interval '120' second;


/* Find what merge changed */
with old_state as (
  select * from jobs as of timestamp sysdate - interval '120' second
)
select * from compare_tables ( 
  jobs, old_state, 
  columns ( job_id, job_title, min_salary, max_salary ) 
)
order  by job_id;






/* Flashback versions query - includes no change updates */
select s.*, versions_operation, versions_xid
/* Get the state of the table 1 minute ago */
from   jobs 
  versions between timestamp 
  systimestamp - interval '120' second and systimestamp s
/* View the changes */
where versions_operation is not null;








/* Column differences as rows - UNPIVOT first */
select * from ( 
  select job_id, job_title, 
         to_char ( min_salary ) min_salary, 
         to_char ( max_salary ) max_salary 
  from   jobs 
)
unpivot (
  /* Omit PK from unpivoted column list */
  val for col in ( job_title, min_salary, max_salary )
);








with t1_cols as (
  select * from ( 
    select job_id, job_title, 
           to_char ( min_salary ) min_salary, 
           to_char ( max_salary ) max_salary 
    from   jobs 
  )
  unpivot (
    val for col in ( job_title, min_salary, max_salary )
  )
), t2_cols as (
  select * from ( 
    select job_id, job_title, 
           to_char ( min_salary ) min_salary, 
           to_char ( max_salary ) max_salary 
    from   jobs as of timestamp sysdate - interval '240' second
  )
  unpivot (
    val for col in ( job_title, min_salary, max_salary )
  )
)
select * from compare_tables ( 
  t1_cols, t2_cols, 
  columns ( job_id, col, val ) 
)
order  by job_id;




/****************************************





****************************************/



/* Performance test - load up the data! */
begin
  for i in 1 .. 14 loop
    insert into jobs select lpad ( i, 3, '0' ) || job_id, job_title, min_salary, max_salary + 100 from jobs;
    insert into jobs_stage select lpad ( i, 3, '0' ) || job_id, job_title, min_salary, max_salary from jobs_stage;
    commit;
  end loop;
end;
/

select count(*) from jobs;
select count(*) from jobs_stage;

alter table jobs add primary key ( job_id );
alter table jobs_stage add primary key ( job_id );



/* Table comaparison methods performance */
declare
  
  iterations     pls_integer := 5;
  start_time     pls_integer;
  full_join_time pls_integer;
  set_ops_time   pls_integer;
  group_by_time  pls_integer;
  procedure format_time ( operation varchar2, run_time integer ) as
  begin
    dbms_output.put_line ( operation || to_char ( ( run_time / 100 ), 'FM990.00' )  || ' seconds ' );
  end;

begin
  for i in 1 .. iterations loop
  
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_set_operations ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Set operations = ', dbms_utility.get_time() - start_time );
  
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_grouping ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Group by = ', dbms_utility.get_time() - start_time );
   
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_full_join ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Full join = ', dbms_utility.get_time() - start_time );
    
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_full_join_json ( 
        jobs, jobs_stage, columns ( job_id ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'JSON join = ', dbms_utility.get_time() - start_time );
    
    dbms_output.put_line ( '' );
    dbms_output.put_line ( '******************' );
    dbms_output.put_line ( '' );
  
  end loop;
end;
/







/* Add more data, run tests again (except JSON) */
begin
  for i in 1 .. 3 loop
    insert into jobs select lpad ( i, 2, '0' ) || job_id, job_title, min_salary, max_salary + 100 from jobs;
    insert into jobs_stage select lpad ( i, 2, '0' ) || job_id, job_title, min_salary, max_salary + 100 from jobs_stage;
    commit;
  end loop;
end;
/

declare
  
  iterations     pls_integer := 3;
  start_time     pls_integer;
  procedure format_time ( operation varchar2, run_time integer ) as
  begin
    dbms_output.put_line ( operation || to_char ( ( run_time / 100 ), 'FM990.00' )  || ' seconds ' );
  end;

begin
  for i in 1 .. iterations loop
  
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_set_operations ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Set operations = ', dbms_utility.get_time() - start_time );
  
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_grouping ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Group by = ', dbms_utility.get_time() - start_time );
   
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_full_join ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Full join = ', dbms_utility.get_time() - start_time );
    
    dbms_output.put_line ( '' );
    dbms_output.put_line ( '******************' );
    dbms_output.put_line ( '' );
  
  end loop;
end;
/








/* There's lots of differences! */
select count(*) from compare_tables_full_join ( 
  jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
);

/* Make the tables identifical */
truncate table jobs;
insert into jobs select * from jobs_stage;
commit;



declare
  
  iterations     pls_integer := 5;
  start_time     pls_integer;
  procedure format_time ( operation varchar2, run_time integer ) as
  begin
    dbms_output.put_line ( operation || to_char ( ( run_time / 100 ), 'FM990.00' )  || ' seconds ' );
  end;

begin
  for i in 1 .. iterations loop
  
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_set_operations ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Set operations = ', dbms_utility.get_time() - start_time );
  
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_grouping ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Group by = ', dbms_utility.get_time() - start_time );
   
    start_time := dbms_utility.get_time();
    for rws in (
      select * from compare_tables_full_join ( 
        jobs, jobs_stage, columns ( job_id, job_title, min_salary, max_salary ) 
      )
    ) loop
      null;
    end loop;
    format_time ( 'Full join = ', dbms_utility.get_time() - start_time );

    dbms_output.put_line ( '' );
    dbms_output.put_line ( '******************' );
    dbms_output.put_line ( '' );
  
  end loop;
end;
/



/* Remove lots of data from the tables */
alter table jobs 
  move including rows 
  where length ( job_id ) < 22
  online;
  
alter table jobs_stage
  move including rows 
  where length ( job_id ) < 22
  online;


select count(*) from jobs;
select count(*) from jobs_stage;

/* Incorrect old query to ensure many differences */
create or replace view new_query as 
select j.*,
       min ( min_salary ) over () min_min,
       max ( max_salary ) over () max_max,
       avg ( max_salary - min_salary ) over () avg_range,
       count (*) emp#
from   jobs j
left join employees e
on     j.job_id = e.job_id
group  by j.job_id, j.job_title, j.min_salary, j.max_salary;



/* Query comaparison methods performance */
declare
  
  start_time     pls_integer;
  procedure format_time ( operation varchar2, run_time integer ) as
  begin
    dbms_output.put_line ( operation || to_char ( ( run_time / 100 ), 'FM990.00' )  || ' seconds ' );
  end;

begin

  start_time := dbms_utility.get_time();
  for rws in (
    select * from compare_tables_set_operations ( 
      original_query, new_query, 
      columns ( job_id, min_min, max_max, avg_range, emp# ) 
    )
  ) loop
    null;
  end loop;
  format_time ( 'Set operations = ', dbms_utility.get_time() - start_time );

  start_time := dbms_utility.get_time();
  for rws in (
    select * from compare_tables_grouping ( 
      original_query, new_query, 
      columns ( job_id, min_min, max_max, avg_range, emp# ) 
    )
  ) loop
    null;
  end loop;
  format_time ( 'Group by = ', dbms_utility.get_time() - start_time );
 
  start_time := dbms_utility.get_time();
  for rws in (
    select * from compare_tables_full_join ( 
      original_query, new_query, 
      columns ( job_id, min_min, max_max, avg_range, emp# ) 
    )
  ) loop
    null;
  end loop;
  format_time ( 'Full join = ', dbms_utility.get_time() - start_time );

end;
/




create search index js_search_i on t ( json_column ) for json;

select * from t where json_textcontains ( json_column, '$'