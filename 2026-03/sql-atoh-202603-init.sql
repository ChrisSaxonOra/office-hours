cl scr
set pages 100
spool sql-atoh-202603.log
/**/
set timing on
set long 1000000
-- drop materialized view if exists quiz_ranks;
drop materialized view if exists quiz_stuff;
drop materialized view if exists quiz_result_summary;
drop view if exists quiz_result_summary;
drop table if exists quiz_ranks_arch purge;
drop materialized view log on quiz_results;


/**/
create or replace view quiz_ranks_v as 
select quiz_date, 
       q.title,
       qr.user_id,
       count(*) over ( partition by q.quiz_id ) players, 
       row_number () over ( partition by q.quiz_id order by score desc ) player_rank
from   quizzes q
left join quiz_results qr
on     q.quiz_id = qr.quiz_id;

begin 
  for rws in ( select * from quiz_ranks_v ) loop 
    null;
  end loop;
end;
/
alter system checkpoint;