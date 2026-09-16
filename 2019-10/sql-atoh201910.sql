set serveroutput off

drop table order_items
  cascade constraints purge;
  
create table order_items (
  order_id   not null,
  product_id not null,
  unit_price not null,
  quantity   not null,
  notes,
  primary key ( order_id, product_id )
) as 
  with orders as (
    select level order_id from dual
    connect by level <= 100000
  ), products as (
    select level product_id from dual
    connect by level <= 10000
  )
    select order_id, product_id, 
           ( mod ( rownum, 1000 ) + 1 ) / 100,
           mod ( rownum, 10 ) + 1,
           lpad ( 'x', 100, 'x' )
    from   orders
    cross join products
    where mod ( order_id, 67 ) = mod ( product_id, 167 );

create or replace function get_item_value (
  unit_price number, quantity integer
)
  return number as
begin
  return ( unit_price * quantity ) ;
end get_item_value;
/

select count (*) 
from   order_items
where  get_item_value ( 
  unit_price, quantity 
) > 50;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'BASIC LAST +PREDICATE'));
/* 
Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("GET_ITEM_VALUE"("UNIT_PRICE","QUANTITY")>50)
*/

create or replace function get_item_value (
  unit_price number, quantity integer
)
  return varchar2 
  sql_macro ( scalar ) 
as
begin
  return ' ( unit_price * quantity ) ';
end get_item_value;
/

select count (*) from order_items
where  get_item_value ( unit_price, quantity ) > 50;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'BASIC LAST +PREDICATE'));

/*
Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("UNIT_PRICE"*"QUANTITY">50)
*/

/* VC use of SQL macros unsupported */
alter table order_items
  add ( 
    total_value as ( 
      get_item_value ( unit_price, quantity ) 
    ) 
  );
--ORA-64630: unsupported use of SQL macro: use of SQL macro with virtual column expressions is not supported

/* FBI use of SQL macros unsupported */
create index value_fbi 
  on order_items ( 
    get_item_value ( unit_price, quantity ) 
  );
--ORA-64632: SQL macro is not supported with Functional Index


create or replace function get_formatted_item_value (
  unit_price number, quantity integer,
  format_mask varchar2 default 'FM$999,999,990.00'
)
  return varchar2 
  sql_macro ( scalar ) 
as
begin
  return q'[ to_char ( 
    get_item_value ( unit_price, quantity ),
    format_mask
  )]';
end get_formatted_item_value;
/

select get_formatted_item_value ( unit_price, quantity )
from   order_items;

set serveroutput off
select count (*)
from   order_items
where  get_formatted_item_value ( unit_price, quantity ) = '$25.00';

select * 
from   table(dbms_xplan.display_cursor(null, null, 'BASIC LAST +PREDICATE'));

set serveroutput off
select count (*)
from   order_items
where  get_formatted_item_value ( unit_price, quantity, '9.000' ) = '$25.00';

select * 
from   table(dbms_xplan.display_cursor(null, null, 'BASIC LAST +PREDICATE'));


var v number;
exec :v := 10;
select *
from   dual
where  get_item_value ( 1, :v ) >= 1;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'BASIC LAST +PREDICATE'));

declare
  v number;
  c pls_integer;
begin

  select count (*)
  into   c
  from   dual
  where  get_item_value ( 1, v ) >= 5;

end;
/

select * from v$sql
where  sql_text like '%DUAL%';

select * 
from   table(dbms_xplan.display_cursor('fhft5axwv9sy2', null, 'BASIC LAST +PREDICATE'));

select * from user_dependencies
where  name like 'GET%';

select * from user_objects
where  object_name like 'GET%';

drop function get_item_value;

--

with emps as (
  select sum ( salary ) over ( 
           partition by department_id
           order by hire_date
         ) sm,
         count (*) over ( 
           partition by department_id
           order by hire_date         
         ) c,
         e.* 
  from   hr.employees e
)
  select * from emps
  where  hire_date > date'2008-01-01';
  
create or replace function running_emp_totals (
  hire_date date
)
  return varchar2 
  sql_macro ( table ) 
as
begin
  return ' select sum ( salary ) over ( 
           partition by department_id
           order by hire_date
         ) sm,
         count (*) over ( 
           partition by department_id
           order by hire_date         
         ) c,
         e.* 
  from   hr.employees e 
  where  e.hire_date > running_emp_totals.hire_date ';
end running_emp_totals;
/

create function running_tots ( hire_date date )
  return varchar2 sql_macro ( table ) 
as
begin
  return 'select count (*) over ( 
           order by hire_date         
         ) c,
         e.* 
  from   hr.employees e 
  where  e.hire_date > running_tots.hire_date ';
end running_tots;
/

select * from running_tots ( sysdate );

alter session set tracefile_identifier = chris;
alter session set events '10053 trace name context forever, level 1';

var dt varchar2(12);
exec :dt := '01-JAN-2008';
select /*+ bind */c, hire_date, last_name
from   running_tots ( to_date ( :dt, 'DD-MON-YYYY' ) )
order  by hire_date;

/*
select "SYS__$"."C"           "C",
       "SYS__$"."HIRE_DATE"   "HIRE_DATE",
       "SYS__$"."LAST_NAME"   "LAST_NAME"
from (
  select count (*) over (
    order by "E"."HIRE_DATE"
    range between unbounded preceding and current row
  ) "C",
         "E"."EMPLOYEE_ID"      "EMPLOYEE_ID",
         "E"."FIRST_NAME"       "FIRST_NAME",
         "E"."LAST_NAME"        "LAST_NAME",
         "E"."EMAIL"            "EMAIL",
         "E"."PHONE_NUMBER"     "PHONE_NUMBER",
         "E"."HIRE_DATE"        "HIRE_DATE",
         "E"."JOB_ID"           "JOB_ID",
         "E"."SALARY"           "SALARY",
         "E"."COMMISSION_PCT"   "COMMISSION_PCT",
         "E"."MANAGER_ID"       "MANAGER_ID",
         "E"."DEPARTMENT_ID"    "DEPARTMENT_ID"
  from "HR"."EMPLOYEES" "E"
  where "E"."HIRE_DATE" > to_date (:b1,'DD-MON-YYYY')
) "SYS__$"
order by "SYS__$"."HIRE_DATE"
*/

select /*+ literal */c, hire_date, last_name
from   running_tots ( date'2008-03-01' )
order  by hire_date;

/*
select "SYS__$"."C"           "C",
       "SYS__$"."HIRE_DATE"   "HIRE_DATE",
       "SYS__$"."LAST_NAME"   "LAST_NAME"
from (
  select count (*) over (
    order by "E"."HIRE_DATE"
    range between unbounded preceding and current row
  ) "C",
         "E"."EMPLOYEE_ID"      "EMPLOYEE_ID",
         "E"."FIRST_NAME"       "FIRST_NAME",
         "E"."LAST_NAME"        "LAST_NAME",
         "E"."EMAIL"            "EMAIL",
         "E"."PHONE_NUMBER"     "PHONE_NUMBER",
         "E"."HIRE_DATE"        "HIRE_DATE",
         "E"."JOB_ID"           "JOB_ID",
         "E"."SALARY"           "SALARY",
         "E"."COMMISSION_PCT"   "COMMISSION_PCT",
         "E"."MANAGER_ID"       "MANAGER_ID",
         "E"."DEPARTMENT_ID"    "DEPARTMENT_ID"
  from "HR"."EMPLOYEES" "E"
  where "E"."HIRE_DATE" > to_date (' 2008-03-01 00:00:00','syyyy-mm-dd hh24:mi:ss'
  )
) "SYS__$"
order by "SYS__$"."HIRE_DATE"
*/

/* Appears in v$sql as unexpanded text */
select * from v$sql
where  sql_text like '%hire_date%';

DECLARE
  l_clob CLOB;
BEGIN
  DBMS_UTILITY.expand_sql_text (
    input_sql_text  => q'[select c, hire_date, last_name
from   running_tots ( date'2008-03-01' )]',
    output_sql_text => l_clob
  );

  DBMS_OUTPUT.put_line(l_clob);
END;
/


/*
C    HIRE_DATE     LAST_NAME   
   1 08 Mar 2008   Markle       
   2 24 Mar 2008   Ande         
   4 21 Apr 2008   Banda        
   4 21 Apr 2008   Kumar  
*/


select * from running_emp_totals ( sysdate );
select * from running_emp_totals ( date'2008-01-01' )
order  by department_id, hire_date;


  select sum ( salary ) over w sm,
         count (*) over w c,
         e.* 
  from   hr.employees e
  window w as (
    partition by department_id
    order by hire_date  
  );

select count (*) over ( 
         partition by owner 
       ) user_obj#, 
       a.* 
from   all_objects a;

create or replace function add_count (
  t dbms_tf.table_t
) return varchar2 sql_macro ( table )
as
begin
  return q'[
    select count (*) over ( 
             partition by owner 
           ) rws, 
           t.* 
    from   t t
]';
end;
/

select * from add_count ( all_tables );

--USER_OBJ#   OWNER       TABLE_NAME      
--          5 APPQOSSYS   WLM_CLASSIFIER_PLAN 

select * from add_count ( all_procedures );

--USER_OBJ#   OWNER    OBJECT_NAME   
--         40 AUDSYS   DBMS_AUDIT_MGMT

select * from v$sql
where  sql_text like '%add_count%';

with rws as (
  select /*+ materialize */* from all_tables
  where  owner like 'C%'
)
select * from add_count ( rws )
where  rownum  = 1;

drop table t cascade constraints purge;
create table t (
  owner int, c1 int
);

insert into t values ( 1, 1 );
insert into t values ( 2, 1 );
insert into t values ( 1, 2 );
commit;

with rws as ( 
  select * from t where owner = 1 
) 
  select * from add_count ( rws );
  

create or replace function add_count (
  t dbms_tf.table_t,
  c dbms_tf.columns_t
) return varchar2 sql_macro ( table )
as
  stmt varchar2(200) := '
    select count (*) over ( 
             partition by t.' || c(1) || '
           ) rws, 
           t.* 
    from   t t';
begin
  return stmt;
end;
/

select * from add_count ( 
  all_tables, columns ( tablespace_name ) 
)
where rownum  = 1;
/*
RWS    OWNER   TABLE_NAME   TABLESPACE_NAME ...
   877 DVSYS   CODE$        SYSAUX
*/
  
select count(*) over w,
       owner, table_name 
from   all_tables
window w as ( 
  order by owner, table_name 
    rows between 5 preceding and current row 
);

select count(*) over w1, --owner, 
       count(*) over w2, --owner, 
       count(*) over w3, --owner, 
       trunc ( created ), object_name
from   user_objects a
window w1 as ( 
  order by trunc ( created )
    groups between 2 preceding and current row 
), w2 as ( 
  order by trunc ( created )
    rows between 2 preceding and current row 
), w3 as ( 
  order by trunc ( created )
    range between 2 preceding and current row 
)
order  by trunc ( created );

/* You can chain windowing clauses */
select count(*) over w1, --owner, 
       count(*) over w2, --owner, 
       count(*) over w3, --owner, 
       trunc ( created ), object_name
from   all_objects a
window w1 as ( 
  partition by owner
), w2 as ( 
  w1 order by trunc ( created )
), w3 as ( 
  w2 rows between 1 preceding and 1 following
)
order  by trunc ( created );

select count (*) over part emps_per_dept,
       count (*) over ord emps_per_dept_by_hire,
       count (*) over wind emps_hired_per_dept_last_4_weeks,
       department_id, 
       hire_date
from   hr.employees e
window part as (
  partition by department_id
), ord as (
  part order by hire_date
), wind as (
  ord range between 28 preceding and current row
)
order  by department_id, hire_date;



select count (*) over rws by_row,
       count (*) over rng by_range,
       count (*) over grps by_group,
       department_id, 
       hire_date
from   hr.employees e
window grp as (
  partition by department_id
  order by trunc ( hire_date, 'mm' )
), rws as (
  grp rows between 5 preceding and current row
), rng as (
  grp range between 5 preceding and current row
), grps as (
  grp groups between 5 preceding and current row
)
order  by department_id, hire_date;

alter session set nls_date_format = 'DD Mon YYYY';

with rws as (
  select trunc(sysdate) - 1 + ( mod ( level, 4 ) * 2 ) dt
  from   dual
  connect by level <= 9
)
  select /*here*/dt, 
         count(*) over rws, 
         count(*) over rng, 
         count(*) over grps
  from   rws
  window grp as (
    order by dt
  ), rws as (
    grp rows between 2 preceding and current row
  ), rng as (
    grp range between 2 preceding and current row
  ), grps as (
    grp groups between 2 preceding and current row
  )
  order  by 1;
  
with rws as (
  select trunc(sysdate) - 1 + ( mod ( level, 4 ) * 2 ) dt
  from   dual
  connect by level <= 9
)
  select /*here*/dt, 
         count(*) over tie, 
         count(*) over curr, 
         count(*) over grps
  from   rws
  window grp as (
    order by dt
  ), tie as (
    grp groups 2 preceding 
      exclude ties
  ), curr as (
    grp groups 2 preceding
      exclude current row
  ), grps as (
    grp groups 2 preceding
      exclude group
  )
  order  by 1;
  
drop table t1
  cascade constraints purge;
drop table t2
  cascade constraints purge;
  
create table t1 ( c1, c2 ) as 
  select mod ( level, 3 ) , mod ( level, 2 ) + 1
  from   dual
  where  1=0
  connect by level <= 5;
  
create table t2 ( c1, c2 ) as 
  select level, mod ( level, 3 ) 
  from   dual
  where  1=0
  connect by level <= 4;

insert into t1 values ( 1, 1 );
insert into t1 values ( 1, 1 );
insert into t1 values ( 2, 2 );
insert into t1 values ( 2, 2 );
insert into t1 values ( null, null );
insert into t1 values ( 1, null );

insert into t2 values ( 1, null );
insert into t2 values ( 2, 2 );
insert into t2 values ( 1, 1 );
insert into t2 values ( 1, 1 );
insert into t2 values ( 3, 3 );
insert into t2 values ( 3, 3 );
commit;

select * from t1;
select * from t2;

select * from t1
except all
select * from t2;  

select * from t2
minus all
select * from t1;

select * from t2
intersect
select * from t1;

select count(*) over ( order by null rows 1 preceding )
from dual
connect by level <= 10;
