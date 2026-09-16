@C:\Users\csaxon\Documents\Scripts\sql-atoh-202006-setup

select * from running_log;




select *   
from   running_log match_recognize (  
  order by run_date  
  measures   
    first ( run_date ) as start_date,  
    count (*) as days  
  pattern ( init consecutive* )  
  define consecutive as run_date = ( prev ( run_date ) + 1 )  
);





select *   
from   running_log match_recognize ( 
  order by run_date  
  measures   
    first ( run_date ) as start_date,  
    count (*) as days ,
    classifier() as variable
  all rows per match
  pattern ( init consecutive* )  
  define consecutive as run_date = ( prev ( run_date ) + 1 )  
);



select days, variable, run_date
from   running_log match_recognize (  
  order by run_date  
  measures   
    first ( run_date ) as start_date,  
    final count (*) as days ,
    classifier() as variable
  all rows per match
  pattern ( init consecutive* )  
  define consecutive as run_date = ( prev ( run_date ) + 1 )  
);




select *   
from   running_log match_recognize (  
  order by run_date  
  measures   
    first ( run_date ) as start_date,  
    final count (*) as days,
    classifier() as variable
  all rows per match
  pattern ( init consecutive{2} )  
  define consecutive as run_date = ( prev ( run_date ) + 1 )  
);


/* *********************************** */









create or replace function get_consecutive_rows (
  tab dbms_tf.table_t, col dbms_tf.columns_t
)
  return varchar2 sql_macro 
as
begin
  return 'tab   
match_recognize (  
  order by ' || get_consecutive_rows.col ( 1 ) || '  
  measures   
    first ( ' || get_consecutive_rows.col ( 1 ) || ' ) as start_value,  
    count (*) as num_rows  
  pattern ( init consecutive* )  
  define   
    consecutive as ' || get_consecutive_rows.col ( 1 ) || ' = ( 
      prev ( ' || get_consecutive_rows.col ( 1 ) || ' ) + 1 
    )  
)';
end get_consecutive_rows;
/


select * 
from   get_consecutive_rows ( 
  running_log, columns ( run_date ) 
);


set serveroutput on
declare
  l_clob clob;
begin
  dbms_utility.expand_sql_text (
    input_sql_text  => q'!select * 
  from   get_consecutive_rows ( running_log, columns ( run_date ) )!',
    output_sql_text => l_clob  );
  dbms_output.put_line(l_clob);
end;
/
/*
select "A1"."START_VALUE"    "START_VALUE",
       "A1"."NUM_ROWS"       "NUM_ROWS"
from (
  select "A3"."START_VALUE"    "START_VALUE",
         "A3"."NUM_ROWS"       "NUM_ROWS"
  from (
    select *
    from (
      select "A2"."RUN_DATE"          "RUN_DATE",
             "A2"."TIME_IN_S"         "TIME_IN_S",
             "A2"."DISTANCE_IN_KM"    "DISTANCE_IN_KM"
      from "CHRIS"."RUNNING_LOG" "A2"
    ) "A4" match_recognize (
      order by "RUN_DATE"
      measures
        first ("RUN_DATE") as "START_VALUE",
        count (*) as "NUM_ROWS"
      one row per match
      after match skip past last row
    pattern ("INIT" ("CONSECUTIVE") *) define
      "CONSECUTIVE" as "RUN_DATE" = prev ("RUN_DATE") + 1
    )
  ) "A3"
) "A1"
*/


with rws as (
  select level x from dual connect by level <= 10
  union all 
  select level + 20 x from dual connect by level <= 4
)
  select * 
  from   get_consecutive_rows ( rws, columns ( x ) );



select * 
from   get_consecutive_rows ( 
  running_log, columns ( dummy ) 
);
-- ORA-00904: "DUMMY": invalid identifier

select * 
from   get_consecutive_rows ( 
  blahaldld, columns ( dummy ) 
);


select * 
from   get_consecutive_rows ( 
  'RUNNING_LOG WHERE 1=''1--', columns ( dummy ) 
);


select * 
from   get_consecutive_rows ( 
  "RUNNING_LOG WHERE 1='1--", columns ( dummy ) 
);



  
  


/* *********************************** */















select * from meeting_attendees
order by start_date, end_date;
alter session set nls_date_format = '  HH24:MI  ';

  
select * 
from   meeting_attendees match_recognize (
    order by start_date, end_date
    measures
      max ( end_date ) start_gap, 
      next ( start_date ) end_gap,
      classifier() as cls
    all rows per match 
    pattern ( ( gap | {-no_gap-} )+ )
    define gap as max ( end_date ) < next ( start_date )
  );
  
  

select cls, end_date, start_gap, end_gap 
from   meeting_attendees match_recognize (
    order by start_date, end_date
    measures
      max ( end_date ) start_gap, 
      next ( start_date ) end_gap,
      classifier() as cls
    all rows per match 
    pattern ( ( gap | no_gap )+ )
    define gap as max ( end_date ) < next ( start_date )
  );  

  
  
create or replace function find_gaps (
  tab            dbms_tf.table_t, 
  date_cols      dbms_tf.columns_t
)
  return varchar2 
  sql_macro 
as
begin
  return 'find_gaps.tab match_recognize ( 
  order by ' || find_gaps.date_cols ( 1 ) || ', ' || find_gaps.date_cols ( 2 ) || '  
  measures   
    max ( ' || find_gaps.date_cols ( 2 ) || ' ) start_gap, 
    next ( ' || find_gaps.date_cols ( 1 ) || ' ) end_gap
  all rows per match
  pattern ( ( gap | {-no_gap-} )+ )  
  define   
    gap as max ( ' || find_gaps.date_cols ( 2 ) || ' ) < ( 
      next ( ' || find_gaps.date_cols ( 1 ) || ' )
    )  
)';
end find_gaps;
/


select start_gap, end_gap
from   find_gaps ( 
  meeting_attendees, 
  columns ( start_date, end_date ) 
);

select * from calendar_dates;
alter session set nls_date_format = '  DD-MON  ';
with rws as (
  select dt, run_date, 
         nvl ( 
           lead ( run_date ) over ( order by dt ),
           dt
         ) next_run_date
  from   calendar_dates
  left join running_log
  on     run_date = dt
  where  dt >= date'2020-04-01'
)
  select * from find_gaps ( 
    rws, 
    columns ( run_date, next_run_date ) 
  );
  

DECLARE
  l_clob CLOB;
BEGIN
  DBMS_UTILITY.expand_sql_text (
    input_sql_text  => q'!select * 
from   find_gaps ( 
  meeting_attendees, 
  columns ( start_date, end_date ) 
)!',
    output_sql_text => l_clob  );
  DBMS_OUTPUT.put_line(l_clob);
END;
/
