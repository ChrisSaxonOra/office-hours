set echo off
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


create or replace function compare_tables_grouping ( 
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
end compare_tables_grouping;
/


create or replace function compare_tables_full_join ( 
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
           when t1 is not null then 't1'
           else 't2'
         end as source_table
  from   ( select 't1' as t1, t1.* from t1 ) t1
  full join ( select 't2' as t2, t2.* from t2 ) t2
  using ( ##COLUMNS## ) 
  where  t1 is null or t2 is null !';
  
  stmt := replace ( stmt, '##COLUMNS##', column_list );

  return stmt;
end compare_tables_full_join;
/

create or replace function compare_tables_full_join_json ( 
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
  select coalesce ( j1, j2 ) json_data,
         case 
           when t1 is not null then 't1'
           else 't2'
         end as source_table
  from   ( select 't1' as t1, json_object ( * returning json ) j1, ##COLUMNS## from t1 ) t1
  full join ( select 't2' as t2, json_object ( * returning json ) j2, ##COLUMNS## from t2 ) t2
  on     t1.##COLUMNS## = t2.##COLUMNS##
  and    json_equal ( j1, j2 )
  where  t1 is null or t2 is null !';
  
  stmt := replace ( stmt, '##COLUMNS##', column_list );

  return stmt;
end compare_tables_full_join_json;
/

create or replace function compare_tables_set_operations ( 
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
  ( 
    select 't1' as source_table, ##COLUMNS## from t1 
    minus
    select 't1' as source_table, ##COLUMNS## from t2
  ) union all (
    select 't2' as source_table, ##COLUMNS## from t2
    minus
    select 't2' as source_table, ##COLUMNS## from t1
  ) !';
  
  stmt := replace ( stmt, '##COLUMNS##', column_list );
  
  return stmt;
end compare_tables_set_operations;
/

drop function compare_tables;
drop table jobs
  cascade constraints purge;
drop table jobs_stage
  cascade constraints purge;
drop table employees
  cascade constraints purge;
create table employees as
  select * from hr.employees
  where  job_id <> 'SA_MAN';
begin
  for i in 1 .. 4 loop
    insert /*+ append */into employees 
      select * from employees;
    commit;
  end loop;
end;
/

create table jobs as
  select * from hr.jobs
  where  1 = 0;
create table jobs_stage as
  select * from hr.jobs
  where  1 = 0;
  
alter table jobs modify job_id varchar2(100);
alter table jobs_stage modify job_id varchar2(100);

insert into jobs values ( 'AD_PRES','President', 20000, 40000 );
insert into jobs values ( 'IT_PROG', 'Programmer', 4000, 10000 );
insert into jobs values ( 'AC_MGR', 'Accounting Manager', 8200, 16000);
insert into jobs values ( 'FI_ACCOUNT', 'Accountant', 4200, 9000);
insert into jobs values ( 'SA_MAN', 'Sales Manager', 10000, 20000);

insert into jobs_stage values ( 'AD_PRES','President', 20000, 40000 );
insert into jobs_stage values ( 'IT_PROG', 'Programmer', 4000, 15000 );
insert into jobs_stage values ( 'AC_MGR', 'Accounting Manager', 8200, 16000);
insert into jobs_stage values ( 'SA_MAN', 'Sales Manager', 10000, 20000);
insert into jobs_stage values ( 'SA_REP', 'Sales Representative', 6000, 12000);

commit;

cl scr
set echo on