@sql-atoh-202403-setup




-- Get the explain plan
select *
from   mv_results mv 
where  quiz_id = :quiz;




-- ~14M rows
select count(*) from mv_results;






-- But full scan is fast; search ID 11914744 & get execution plan
alter session set statistics_level = all;

select *
from   mv_results mv 
where  quiz_id = :quiz;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');







--Here's one I made earlier...
-- create index mvre_quiz_i on mv_results ( quiz_id ) invisible;
alter index mvre_quiz_i visible;

-- Index makes little difference...
select *
from   mv_results mv 
where  quiz_id = :quiz;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');

-- So what's the real problem? 
-- View trace & find out!










-- Real problem query - populating the drop down!
select quiz_id, competition_name || '-' || to_char ( start_date, 'yyyy' ) comp_event
from   quizzes
join   competitions 
using  ( competition_id )
join   competition_types 
using  ( competition_type_id )
where  status = 'RANKED'
and    type_name = 'CHAMPS'
order  by start_date desc;

select * from dbms_xplan.display();

select * from dbms_xplan.display_cursor( sql_id => '4wj7s1m4bvnk6', format => 'ALLSTATS LAST');




-- Quizzes is a MUCH bigger table
select segment_name, bytes / 1024 / 1024 size_in_mb from user_segments 
where  segment_name in ( 'QUIZZES', 'MV_RESULTS' );








-- Here's another one I created earlier...
-- create index quiz_status_i on quizzes ( status ) invisible;
alter index quiz_status_i visible;

select competition_id, quiz_id, competition_name || '-' || to_char ( start_date, 'yyyy' ) comp_event
from   quizzes
join   competitions 
using  ( competition_id )
join   competition_types 
using  ( competition_type_id )
where  status = 'RANKED'
and    type_name = 'CHAMPS'
order  by start_date desc;

select * from dbms_xplan.display_cursor();

select * from dbms_xplan.display_cursor( sql_id => '4wj7s1m4bvnk6', format => 'ALLSTATS LAST');
-- Check page to verify 

select * from v$sql where sql_text like 'select%quizzes%';




/****************************


        Yearly stats


****************************/


-- Get the results for one year; 2023-01-01 -> 2024-01-01
select count(*) from quiz_results 
where  result_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    result_date < to_date ( :end_date, 'yyyy-mm-dd' )
and    finish_date is not null
union  all 
select count(distinct user_id) from quiz_results 
where  result_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    result_date < to_date ( :end_date, 'yyyy-mm-dd' )
and    finish_date is not null
union  all
select sum (seconds_taken) from quiz_results 
where  result_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    result_date < to_date ( :end_date, 'yyyy-mm-dd' )
-- hide long answer times
and    ( finish_date - result_date ) < 1/24
union  all 
select count(*) from questions
where  created_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    created_date < to_date ( :end_date, 'yyyy-mm-dd' );

select * from dbms_xplan.display_cursor( sql_id => '4vyp8wk95akxm', format => 'ALLSTATS LAST');





-- Real problem: full history of stats! 2010 - 2025
select count(*) from quiz_results 
where  result_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    result_date < to_date ( :end_date, 'yyyy-mm-dd' )
and    finish_date is not null
union  all 
select count(distinct user_id) from quiz_results 
where  result_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    result_date < to_date ( :end_date, 'yyyy-mm-dd' )
and    finish_date is not null
union  all
select sum (seconds_taken) from quiz_results 
where  result_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    result_date < to_date ( :end_date, 'yyyy-mm-dd' )
-- hide long answer times
and    ( finish_date - result_date ) < 1/24
union  all 
select count(*) from questions
where  created_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    created_date < to_date ( :end_date, 'yyyy-mm-dd' );

select * from dbms_xplan.display_cursor( sql_id => '4vyp8wk95akxm', format => 'ALLSTATS LAST');








-- Optimization attempt #1: Refactor query
with rws as ( 
  select count(*) num_answers, count ( distinct user_id ) num_users, 
         sum ( 
           case when ( finish_date - result_date ) < 1/24 then seconds_taken end 
         ) total_time
  from   quiz_results 
  where  result_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
  and    result_date < to_date ( :end_date, 'yyyy-mm-dd' )
  and    finish_date is not null
)
select num_answers from rws 
union  all
select num_users from rws 
union  all
select total_time from rws 
union  all 
select count(*) from questions
where  created_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    created_date < to_date ( :end_date, 'yyyy-mm-dd' );

select * from dbms_xplan.display_cursor( sql_id => '3n1gfvgd25cwq', format => 'ALLSTATS LAST');






-- count distinct => double aggregation
select sum ( seconds_taken ), count ( distinct user_id ) from quiz_results;

-- Query is really something like:
select count ( user_id ), sum ( s ) from (
  select user_id, sum ( seconds_taken ) s from quiz_results
  group  by user_id
);









-- Materialized view
/*
create materialized view year_stats 
as 
select trunc ( result_date, 'y' ) year_start, 
       count(*) num_answers, 
       count ( distinct user_id ) num_users, 
       sum ( case when ( finish_date - result_date ) < 1/24 then seconds_taken end ) total_time
from   quiz_results 
where  finish_date is not null
group  by trunc ( result_date, 'y' );
*/

select * from year_stats;






-- How do we get overall distinct users?
-- SUM ( COUNT DISTINCT ) <> COUNT DISTINCT 
select sum ( num_users ) from year_stats;
select count ( distinct user_id ) from quiz_results;








-- Add overall totals
/*
create materialized view year_stats_rollup 
as 
select trunc ( result_date, 'y' ) year_start, 
       count(*) num_answers, 
       count ( distinct user_id ) num_users, 
       sum ( case when ( finish_date - result_date ) < 1/24 then seconds_taken end ) total_time
from   quiz_results 
where  finish_date is not null
-- Generate overall totals
group  by rollup ( trunc ( result_date, 'y' ) );
*/


-- Now have overall totals stored
select * from year_stats_rollup
where  year_start is null;








-- Select totals based on date range
select * from year_stats_rollup
where  ( 
  months_between (to_date ( :end_date, 'yyyy-mm-dd' ), to_date ( :start_date, 'yyyy-mm-dd' ) ) > 12 )
  and year_start is null 
or (
  months_between (to_date ( :end_date, 'yyyy-mm-dd' ), to_date ( :start_date, 'yyyy-mm-dd' ) ) <= 12 
  and year_start >= to_date ( :start_date, 'yyyy-mm-dd' ) 
  and year_start < to_date ( :end_date, 'yyyy-mm-dd' )
);





with rws as ( 
  select *
  from   year_stats_rollup
  where  ( 
    year_start is null and  
    months_between (to_date ( :end_date, 'yyyy-mm-dd' ), to_date ( :start_date, 'yyyy-mm-dd' ) ) > 12 
  ) or (
   months_between (to_date ( :end_date, 'yyyy-mm-dd' ), to_date ( :start_date, 'yyyy-mm-dd' ) ) <= 12 
   and year_start >= to_date ( :start_date, 'yyyy-mm-dd' ) 
   and    year_start < to_date ( :end_date, 'yyyy-mm-dd' )
  ) 
)
select 'Answers' type, to_char ( sum ( num_answers ), '999,999,990' ) value from rws 
union  all
select 'Players' type, to_char ( sum ( num_users ), '999,999,990' ) value from rws 
union  all
select 'Time' type, to_char ( numtodsinterval ( sum ( total_time ) / 86400, 'day' ) ) value from rws 
union  all 
select 'Quizzes' type, to_char ( count(*), '999,990' ) value from questions 
where  created_date >= to_date ( :start_date, 'yyyy-mm-dd' ) 
and    created_date <  to_date ( :end_date, 'yyyy-mm-dd' );

select * from dbms_xplan.display_cursor( sql_id => 'a6378rd1ps8np', format => 'ALLSTATS LAST');



