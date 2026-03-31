@sql-atoh-202603-init.sql
set timing on




/* Get overall result summary => read all the data! */
select count (*) result_count, 
       count ( score ) score_count, 
       avg ( score ) mean_score,
       sum ( score ) total_score
from   quiz_results;






/* Save the text of the query as a view */
create or replace view quiz_result_summary as
  select count (*) result_count, 
         count ( score ) score_count, 
         avg ( score ) mean_score,
         sum ( score ) total_score
  from   quiz_results;

select * from quiz_result_summary;
/* But this still runs the underlying query */






drop view quiz_result_summary;
/* Store the query result */
create materialized view quiz_result_summary
as
select count (*) result_count, 
       count ( score ) score_count, 
       avg ( score ) mean_score,
       sum ( score ) total_score
from   quiz_results;

/* And now you're reading just one row! */
select * from quiz_result_summary;








/* But how to keep it up to date? */







/* Apply deltas on commit */
alter materialized view quiz_result_summary
  refresh fast on commit;







/* Need MV log for fast refreshes */
create materialized view log on quiz_results
  with rowid ( score ) -- columns used in MV
  including new values;

/* Now we can make it fast refreshable */
alter materialized view quiz_result_summary
  refresh fast on commit;

/* Final complete refresh */
exec dbms_mview.refresh ( 'quiz_result_summary', method => 'C' );

/* Check it's FRESH */
select last_refresh_date, staleness, last_refresh_type
from   user_mviews
where  mview_name = 'QUIZ_RESULT_SUMMARY';

select * from quiz_result_summary;






/* Inserting this row records a change in the MV log */
insert into quiz_results values ( -1, 1, 100, -1 );

/* View change */
select * from mlog$_quiz_results;

select * from quiz_results qure
join   mlog$_quiz_results mlqr
on     qure.rowid = mlqr.m_row$$;

/* Change not applied yet */
select * from quiz_result_summary;

/* Committing applies the change */
commit;

select * from mlog$_quiz_results;
select * from quiz_result_summary;





/* Same for updates and deletes */
delete quiz_results 
where  result_id = -1;

update quiz_results 
set    score = 100 
where  result_id = 1;

select * from mlog$_quiz_results;

commit;

select * from mlog$_quiz_results;
select * from quiz_result_summary;


/* Check the status */
select last_refresh_date, staleness, last_refresh_type
from   user_mviews
where  mview_name = 'QUIZ_RESULT_SUMMARY';



/******************************



******************************/

/* Not all MVs are fast refreshable :( 
   e.g. MV ranking player scores */
create materialized view quiz_ranks_fast
refresh fast on commit
as
select quiz_date, 
       q.title,
       user_id,
       count(*) over ( partition by q.quiz_id ) players, 
       row_number () over ( partition by q.quiz_id order by score desc ) player_rank
from   quizzes q
left join quiz_results qr
on     q.quiz_id = qr.quiz_id;



/* But why isn't it fast refreshable? */
delete mv_capabilities_table;
begin 
  dbms_mview.explain_mview ( -- pass MV name or query 
    'select quiz_date, 
            q.title,
            user_id,
            count(*) over ( partition by q.quiz_id ) players, 
            row_number () over ( partition by q.quiz_id order by score desc ) player_rank
     from   quizzes q
     left join quiz_results qr
     on     q.quiz_id = qr.quiz_id'
  );
end;
/
select capability_name, possible, related_text, msgno, msgtxt 
from   mv_capabilities_table where capability_name like 'REFRESH%';



/* So: we need to complete refresh 
   Step 1: build a view */
create or replace view quiz_ranks_v as 
  select quiz_date, 
         q.title,
         user_id,
         count(*) over ( partition by q.quiz_id ) players, 
         row_number () over ( partition by q.quiz_id order by score desc ) player_rank
  from   quizzes q
  left join quiz_results qr
  on     q.quiz_id = qr.quiz_id;



/* Here's an MV I created earlier that uses the view
create materialized view quiz_ranks as
  select *
  from   quiz_ranks_v;
/**/

select query from user_mviews 
where  mview_name = 'QUIZ_RANKS';





PRO Default refresh (atomic) 
exec dbms_mview.refresh ( 'quiz_ranks' );







/* Let's see what the query is doing */
explain plan for
select * from quiz_ranks_v;

select * from dbms_xplan.display();




/* Let's optimize the view! 
   Past quiz_ranks are fixed - move to archive table
   Only calculate recent data */
create table quiz_ranks_arch as 
  select * from quiz_ranks 
  where  quiz_date < date'2020-01-01';

exec dbms_stats.gather_table_stats ( ownname => null, tabname => 'quiz_ranks_arch' );



/* Change view to only calculate recent ranks */
create or replace view quiz_ranks_v as 
  select * from quiz_ranks_arch 
  union  all
  select quiz_date, 
         q.title,
         user_id,
         count(*) over ( partition by q.quiz_id ) players, 
         row_number () over ( partition by q.quiz_id order by score desc ) player_rank
  from   quizzes q
  left join quiz_results qr
  on     q.quiz_id = qr.quiz_id
  where  quiz_date >= date'2020-01-01';




/* Check the plan now */
explain plan for
select * from quiz_ranks_v;

select * from dbms_xplan.display();
/**/


PRO So the refresh will be faster now, right?
exec dbms_mview.refresh ( 'quiz_ranks' );






/* A bit faster... but not much :( */

/******************************



******************************/


/* So why's the refresh so slow? 
   Let's see what the SQL monitor tells us... */
select sql_id, elapsed_time / 1000000 time_in_s,  
       first_refresh_time, sql_text 
from   v$sql_monitor
where  last_refresh_time > sysdate - interval '40' minute
and    sql_text like '%MV_REFRESH%'
order  by first_refresh_time desc;
/* Default refresh is atomic => delete + insert
   Deletes are slooooow!
   What else can we try? */







/**/
PRO Non-atomic refresh => truncate + insert
begin
  dbms_mview.refresh ( 
    'quiz_stuff', 
    atomic_refresh => false );
end;
/








/* Much faster! But there's a problem... */
/* MV empty when queried in other sessions :( */






PRO Out-of-place refresh => create another table and swap 
begin
  dbms_mview.refresh ( 
    'quiz_stuff', 
    atomic_refresh => false, 
    out_of_place => true );
end;
/






/* Check to see the impact */
select sql_id, elapsed_time / 1000000 time_in_s,  
       first_refresh_time, sql_text 
from   v$sql_monitor
where  true 
and    last_refresh_time > sysdate - interval '40' minute
and    sql_text like '%MV_REFRESH%'
order  by first_refresh_time desc;
/**/

/* Sooooo.... why not always use out-of-place refresh? */






/* There are restrictions... */
create materialized view quiz_stuff as
  select quiz_id, stuff from quizzes 
  where  rownum <= 1000;

alter table quiz_stuff 
  add primary key ( quiz_id );

/* Constraints block out-of-place refresh */
exec dbms_mview.refresh ( 'quiz_stuff', atomic_refresh => false, out_of_place => true );
begin
  dbms_mview.refresh ( 
    'quiz_stuff', 
    atomic_refresh => false, 
    out_of_place => true );
end;
/









/* But unique indexes are fine! */
alter table quiz_stuff 
  drop primary key;

create unique index qust_quiz_u 
  on quiz_stuff ( quiz_id );

begin
  dbms_mview.refresh ( 
    'quiz_stuff', 
    atomic_refresh => false, 
    out_of_place => true );
end;
/






/* Setup costs for out-of-place: adds overhead if few rows in MV */
begin
  dbms_mview.refresh ( 
    'quiz_stuff', 
    atomic_refresh => false, 
    out_of_place => true );
end;
/
exec dbms_mview.refresh ( 'quiz_stuff' );






/* Need space to store two copies of MV */
begin
  dbms_mview.refresh ( 
    'quiz_stuff', 
    atomic_refresh => false, 
    out_of_place => true );
end;
/

/******************************



******************************/

