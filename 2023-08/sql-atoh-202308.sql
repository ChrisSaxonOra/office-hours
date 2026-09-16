@sql-atoh-202308-setup





select * from exam_results;
  
  
  
  
  
  
  
  
/* Simple case => Exam IDs to names */
select exam_id,
       case exam_id
         when 1 then 'SQL'
         when 2 then 'Java'
         when 3 then 'Python'
         when 4 then 'Javascript'
       end exam_name,
       count (*)
from   exam_results
group  by exam_id
order  by exam_id;









/* Simple case with ELSE */
select exam_id,
       case exam_id
         when 1 then 'SQL'
         when 2 then 'Java'
         when 3 then 'Python'
         when 4 then 'Javascript'
         else 'Other language'
       end exam_name
from   exam_results
group  by exam_id
order  by exam_id;







/* Simple is equivalent to this searched CASE */
select exam_id,
       case 
         when exam_id = 1 then 'SQL'
         when exam_id = 2 then 'Java'
         when exam_id = 3 then 'Python'
         when exam_id = 4 then 'Javascript'
         else 'Other language'
       end exam_name
from   exam_results
group  by exam_id
order  by exam_id;



/* Expressions must have same return type */
select exam_id,
       case exam_id
         when 1 then '1'
         when 2 then 2
       end exam_name,
       count (*)
from   exam_results
group  by exam_id
order  by exam_id;





/* 
   Convert percentages to grades:
     A => 90% or higher
     B => 80% or higher and less than 90%
     C => 70% or higher and less than 80%
     D => 60% or higher and less than 70%
     E => 50% or higher and less than 60%
     F => less than 50%
     U => null
  Simple CASE impratical 
*/
select student_id, exam_id, percent_correct,
       case percent_correct
         when null then 'U'
         when 100 then 'A'
         when 99.99 then 'A'
         when 99.98 then 'A'
         when 99.97 then 'A'
         when 99.96 then 'A'
         -- etc.
       end grade
from   exam_results
order  by percent_correct nulls first;

  
  
  
/* Searched case */
select student_id, exam_id, percent_correct,
       case
         when percent_correct is null then 'U'
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end grade
from   exam_results
order  by percent_correct nulls first;




/* Top-to-bottom evaluation */
select student_id, exam_id, percent_correct,
       case
         -- top line checked first; no-one will get grades A-D!
         when percent_correct >= 50 then 'E'
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         else 'F'
       end grade
from   exam_results
order  by percent_correct desc, grade;




/* Top-to-bottom evaluation - defensive coding */
select student_id, exam_id, percent_correct,
       case
         when percent_correct >= 50 and percent_correct < 60 then 'E'
         when percent_correct >= 60 and percent_correct < 70 then 'D'
         when percent_correct >= 70 and percent_correct < 80 then 'C'
         when percent_correct >= 80 and percent_correct < 90 then 'B'
         when percent_correct >= 90 then 'A'
         else 'F'
       end grade
from   exam_results;





/* Expressions can check different columns */
select exam_id, student_id, percent_correct,
       case
         when exam_id = 0 then 'Test exam'
         when student_id = 0 then 'Test student'
         when percent_correct >= 90 then 'A'
         -- etc.
       end grade
from   exam_results
where  0 in ( exam_id, student_id ) or percent_correct > 99;






/* Classify test rows */
select exam_id, student_id, percent_correct,
       case
         when exam_id = 0 and student_id = 0 then 'Test exam and student'
         when exam_id = 0 and student_id <> 0 then 'Test exam'
         when student_id = 0 and exam_id <> 0 then 'Test student'
         when percent_correct >= 90 then 'A' --etc.
       end grade
from   exam_results
where  0 in ( exam_id, student_id ) or percent_correct > 99;






/* Nesting CASE expressions inside each other & concatenating their result */
select exam_id, student_id, percent_correct,
       case
         when 0 not in ( exam_id, student_id ) then
           case
             when percent_correct >= 90 then 'A'
             when percent_correct >= 80 then 'B'
             -- etc.
           end
         else 
           'Test ' || case 
             when exam_id = 0 then 'exam '
           end || case 
             when student_id = 0 then 'student'
           end
       end grade
from   exam_results
where  0 in ( exam_id, student_id ) or percent_correct > 99;






/* 
  How to find all grade A students?
  => Searched case in WHERE 
*/
select student_id, exam_id, percent_correct
from   exam_results
where  'A' = case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end;
       
       

/* Find all grade A-C results */
select student_id, exam_id, percent_correct,
       case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end grade
from   exam_results
where  case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end in ( 'A', 'B', 'C' );



/* Can also GROUP & ORDER BY CASE */
select case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end grade, count(*)
from   exam_results
group  by case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end
order  by case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end;





/* ORDER BY alias; 23c => can GROUP BY alias too */
select case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end grade, count(*)
from   exam_results
group  by grade
order  by grade;






/* Place CASE expression in a virtual column to make it reusable */
alter table exam_results 
  add ( grade as ( case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end )
  );

select grade, count(*)
from   exam_results
where  grade in ( 'A', 'B', 'C' )
group  by grade
order  by grade;



/* View CASE expression for VC */
select column_name, data_default 
from   user_tab_cols
where  table_name = 'EXAM_RESULTS';




/* Remove virtual column */
alter table exam_results 
  drop ( grade );


/*******************************






*******************************/ 


/* 
   Return grade & pass/fail
   Grades A-C are a pass; others are fail
   => can't return two values in one CASE
*/
select student_id, exam_id, percent_correct,
       case
         when percent_correct >= 90 then 'A', 'Pass'
         when percent_correct >= 80 then 'B', 'Pass'
         when percent_correct >= 70 then 'C', 'Pass'
         when percent_correct >= 60 then 'D', 'Fail'
         when percent_correct >= 50 then 'E', 'Fail'
         else 'F', 'Fail'
       end grade
from   exam_results;




/* Two values => duplicate logic! */
select student_id, exam_id, percent_correct,
       case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end grade,
       case
--         when percent_correct >= 90 then 'Pass'
--         when percent_correct >= 80 then 'Pass'
         when percent_correct >= 70 then 'Pass'
--         when percent_correct >= 60 then 'Fail'
--         when percent_correct >= 50 then 'Fail'
         else 'Fail'
       end outcome
from   exam_results;









/* Use complex type to return many values */
select student_id, exam_id, percent_correct,
       case
         when percent_correct >= 90 then json_object ( 'grade' : 'A', 'outcome' : 'Pass' )
         when percent_correct >= 80 then json_object ( 'grade' : 'B', 'outcome' : 'Pass' )
         when percent_correct >= 70 then json_object ( 'grade' : 'C', 'outcome' : 'Pass' )
         when percent_correct >= 60 then json_object ( 'grade' : 'D', 'outcome' : 'Fail' )
         when percent_correct >= 50 then json_object ( 'grade' : 'E', 'outcome' : 'Fail' )
         else json_object ( 'grade' : 'F', 'outcome' : 'Fail' )
       end grade
from   exam_results;









/* Join to case expression */
with exam_grades as (
  select 'A' grade, 'Pass' outcome from dual union all 
  select 'B' grade, 'Pass' outcome from dual union all 
  select 'C' grade, 'Pass' outcome from dual union all 
  select 'D' grade, 'Fail' outcome from dual union all 
  select 'E' grade, 'Fail' outcome from dual union all 
  select 'F' grade, 'Fail' outcome from dual 
)
select student_id, exam_id, percent_correct, 
       grade, outcome
from   exam_results
join   exam_grades 
on     grade = case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end;






/* Have lookup table */
create table exam_grades (
  grade       char(1) not null
    primary key,
  lower_bound number
    unique,
  upper_bound number
    references exam_grades ( lower_bound ),
  outcome     varchar2(10) not null
);

begin
  insert into exam_grades values ( 'A', 90,   null, 'Pass' );
  insert into exam_grades values ( 'B', 80,   90,   'Pass' );
  insert into exam_grades values ( 'C', 70,   80,   'Pass' );
  insert into exam_grades values ( 'D', 60,   70,   'Fail' );
  insert into exam_grades values ( 'E', 50,   60,   'Fail' );
  insert into exam_grades values ( 'F', null, 50,   'Fail' );
  commit;
end;
/



/* Join to CASE expression */
select student_id, exam_id, percent_correct, 
       lower_bound, upper_bound, grade, outcome
from   exam_results
join   exam_grades 
on     grade = case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end;
  
  
  
  
  


/* Move CASE logic into join */
select student_id, exam_id, percent_correct, grade, outcome 
from   exam_results 
join   exam_grades 
on     ( lower_bound <= percent_correct or lower_bound is null )
and    ( upper_bound > nvl ( percent_correct, 0 ) or upper_bound is null );










/* View to make join reusable */
create or replace view exam_result_outcomes as 
select student_id, exam_id, percent_correct, 
       lower_bound, upper_bound, grade, outcome
from   exam_results
join   exam_grades 
on     grade = case
         when percent_correct >= 90 then 'A'
         when percent_correct >= 80 then 'B'
         when percent_correct >= 70 then 'C'
         when percent_correct >= 60 then 'D'
         when percent_correct >= 50 then 'E'
         else 'F'
       end;

select * from exam_result_outcomes;







/* 
   "Dynamic" filtering/joins
   Two variables - join type/column (res_type) and value (res_value)
   Use CASE to SELECT column to compare
   => AVOID! 
*/
select grade, outcome, count(*) 
from   exam_result_outcomes
where  case :res_type
  when 'G' then grade
  when 'O' then outcome 
end = :res_value
group  by grade, outcome;





/* Prefer separate variables */
select grade, outcome, count(*) 
from   exam_result_outcomes
where  grade = nvl ( :grade, grade )
and    outcome = nvl ( :outcome, outcome )
group  by grade, outcome;

  

  
  
  
/* 
   Find number of passes & fails/exam
   => place CASE expression in COUNT without ELSE
*/
select exam_id, 
       count ( case when percent_correct >= 70 then 'a' end ) pass, 
       count ( case when nvl ( percent_correct, 0 ) < 70 then 1 end ) fail
from   exam_results
group  by exam_id;






/*
  Compare AVG pass/fail percentage/exam
  Get highest & lowest pass mark/exam
*/
select exam_id, 
       avg ( case when percent_correct >= 70 then percent_correct end ) pass_mean, 
       avg ( case when nvl ( percent_correct, 0 ) < 70 then percent_correct end ) fail_mean, 
       max ( case when percent_correct >= 70 then percent_correct end ) max_pass_pct, 
       min ( case when percent_correct >= 70 then percent_correct end ) min_pass_pct 
from   exam_results
group  by exam_id;






/* Show grade count/exam as columns */
select exam_id, 
       count ( case when percent_correct >= 90 then 1 end ) a, 
       count ( case when percent_correct >= 80 and percent_correct < 90 then 1 end ) b, 
       count ( case when percent_correct >= 70 and percent_correct < 80 then 1 end ) c, 
       count ( case when percent_correct >= 60 and percent_correct < 70 then 1 end ) d, 
       count ( case when percent_correct >= 50 and percent_correct < 60 then 1 end ) e, 
       count ( case when percent_correct < 50 then 1 end ) f
from   exam_results
group  by exam_id;





/* Get the grade counts using PIVOT 
   Use CASE in a subquery */
with rws as (
  select exam_id, case
           when percent_correct >= 90 then 'A'
           when percent_correct >= 80 then 'B'
           when percent_correct >= 70 then 'C'
           when percent_correct >= 60 then 'D'
           when percent_correct >= 50 then 'E'
           else 'F'
         end grade
  from   exam_results
)
  select * from rws
  pivot (
    count(*) for grade in ( 'A', 'B', 'C', 'D', 'E' )
  );






/* Pass count & average using PIVOT */
with rws as (
  select exam_id, percent_correct, 
         case 
           when percent_correct >= 70 then 'Pass'
           else 'Fail'
         end outcome
  from   exam_results
)
  select * from rws
  pivot (
    count(*) num, avg ( percent_correct ) mean
    for outcome in ( 'Pass' pass )
  );





/* 
   Find how far above/below the average pass pct each student was for each exam
   CASE expression in window function
*/
select exam_id, student_id, percent_correct,
       round ( 
         avg ( case when percent_correct >= 70 then percent_correct end ) 
           over ( partition by exam_id ), 2 
       ) exam_pass_mean,
       percent_correct - round ( 
         avg ( case when percent_correct >= 70 then percent_correct end ) 
           over (  partition by exam_id ), 2 
       ) gap_to_avg_exam_pass
from   exam_results;




/*******************************






*******************************/ 

/* Reminder: no implicit conversion in SQL */
select case :selector
    when 1 then '1'
    when 2 then 2
  end;
  
set serveroutput on
/* PL/SQL does have implicit conversion */
declare
  selector pls_integer := 1;
begin
  dbms_output.put_line ( case selector
    when 1 then '1'
    when 2 then 2
  end );
end;
/




/* CASE statement in PL/SQL - have statements in each clause */
declare
  grade   char(1);
  outcome varchar2(10);
begin
  for rws in ( select * from exam_results fetch first 10 rows only ) loop
    case
      when rws.percent_correct >= 90 then 
        grade := 'A'; outcome := 'Pass';
      when rws.percent_correct >= 80 then
        grade := 'B'; outcome := 'Pass';
      when rws.percent_correct >= 70 then
        grade := 'C'; outcome := 'Pass';
      when rws.percent_correct >= 60 then
        grade := 'D'; outcome := 'Fail';
      when rws.percent_correct >= 50 then
        grade := 'E'; outcome := 'Fail';
      else 
        grade := 'F'; outcome := 'Fail';
    end case;
    dbms_output.put_line ( rws.percent_correct || ' ' || grade || ' ' || outcome );
  end loop;
end;
/





/* CASE statement => one expression must be TRUE; if not CASE_NOT_FOUND is raised */
declare
  grade   char(1);
  outcome varchar2(10);
begin
  for rws in ( select * from exam_results ) loop
    case
      when rws.percent_correct >= 90 then 
        grade := 'A'; outcome := 'Pass';
      when rws.percent_correct >= 80 then
        grade := 'B'; outcome := 'Pass';
      when rws.percent_correct >= 70 then
        grade := 'C'; outcome := 'Pass';
      when rws.percent_correct >= 60 then
        grade := 'D'; outcome := 'Fail';
      when rws.percent_correct >= 50 then
        grade := 'E'; outcome := 'Fail';
    end case;
    dbms_output.put_line ( rws.percent_correct || ' ' || grade || ' ' || outcome );
  end loop;
end;
/




/* CASE_NOT_FOUND only for CASE statements */
declare
  grade char(1);
begin
  for rws in ( select * from exam_results fetch first 10 rows only ) loop
    grade := case
      when rws.percent_correct >= 90 then 'A'
    end;
    dbms_output.put_line ( rws.percent_correct || ' ' || grade );
  end loop;
end;
/




/* Must have non-null return in PL/SQL */
declare
  grade char(1);
begin
  for rws in ( select * from exam_results fetch first 10 rows only ) loop
    grade := case
      when rws.percent_correct >= 90 then null
      else null
    end;
    dbms_output.put_line ( rws.percent_correct || ' ' || grade );
  end loop;
end;
/





/* Lots of duplication of selector PERCENT_CORRECT
case
  when percent_correct >= 90 then 'A'
  when percent_correct >= 80 then 'B'
  when percent_correct >= 70 then 'C'
  when percent_correct >= 60 then 'D'
  when percent_correct >= 50 then 'E'
  else 'F'
end
*/

/* 23c => dangling predicates in PL/SQL only */
declare
  grade char(1);
begin
  for rws in ( select * from exam_results fetch first 10 rows only ) loop
    grade := case rws.percent_correct 
      when >= 90 then 'A'
      when >= 80 then 'B'
      when >= 70 then 'C'
      when >= 60 then 'D'
      when >= 50 then 'E'
      else 'F'
    end;
    dbms_output.put_line ( rws.percent_correct || ' ' || grade );
  end loop;
end;
/




/* Can use most conditions as dangling predicate */
declare
  grade varchar2(10);
begin
  for rws in ( select * from exam_results fetch first 10 rows only ) loop
    grade := case rws.percent_correct 
      when 100 then 'A*' -- implicit = 100
      when in ( 50, 60, 70, 80, 90 ) then 'boundary'
      when > 90 then 'A'
      when > 80 then 'B'
      when > 70 then 'C'
      when > 60 then 'D'
      when > 50 then 'E'
      when is null, 0 then 'U' -- implicit = 0
      else 'F'
    end;
    dbms_output.put_line ( rws.percent_correct || ' ' || grade );
  end loop;
end;
/



/*******************************



              FIN



*******************************/






