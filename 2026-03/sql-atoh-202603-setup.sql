cl scr
set pages 100
spool sql-atoh-202603.log
/**/
var num_rows number;
var results_per_quiz number;
var title_length number;
var stuff_length number;
exec :num_rows := 160000;
exec :results_per_quiz := 10;
exec :title_length := 100;
exec :stuff_length := 10;

set timing on
set long 1000000

alter session set nls_date_format = 'DD-Mon-YYYY HH24:MI:SS';


drop materialized view if exists quiz_stuff;
drop materialized view if exists quiz_result_summary;
drop materialized view if exists quiz_count;
drop materialized view if exists quiz_ranks;
drop materialized view if exists results;
drop table if exists quizzes cascade constraints purge;
drop table if exists quiz_results cascade constraints purge;
drop table if exists quiz_ranks_arch purge;

create table quizzes ( quiz_id int primary key, quiz_date date, title varchar2(4000), stuff clob );
create table quiz_results ( 
  result_id int primary key, quiz_id int, score number, user_id integer
);
create index qr_quiz_i on quiz_results ( quiz_id );
create index qr_quiz_score_i on quiz_results ( quiz_id, score desc );
create index qr_date_i on quizzes ( quiz_date );
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

create materialized view quiz_ranks as
  select *
  from   quiz_ranks_v;

create index qura_date_i on quiz_ranks ( quiz_date );
create index qura_title_i on quiz_ranks ( title );

truncate table quizzes;
insert into quizzes 
by name
select level quiz_id, 
       date'2010-01-01' + ( level / 20 ) quiz_date,
       rpad ( 'Quiz ' || level || ' ', :title_length, 'x' ) title,
       rpad ( 'stuff' || level, :stuff_length, 'f' ) stuff
connect by level <= :num_rows;
commit;

truncate table quiz_results;
insert into quiz_results 
by name 
select rownum result_id, quiz_id, round ( dbms_random.value ( 0, 100 ) ) score, mod ( rownum, 133 ) user_id
from   ( select * from quizzes where quiz_id <= (:num_rows / 2 )) cross join lateral (
  select level from dual connect by level <= :results_per_quiz
);
commit;
insert into quiz_results 
by name 
select ( 20 * (:num_rows/2)) + rownum result_id, quiz_id, round ( dbms_random.value ( 0, 100 ) ) score, mod ( rownum, 133 ) user_id
from   ( select * from quizzes where quiz_id > (:num_rows / 2)) cross join lateral (
  select level from dual connect by level <= :results_per_quiz
);
commit;
exec dbms_stats.gather_table_stats ( ownname => null, tabname => 'quizzes' );
exec dbms_stats.gather_table_stats ( ownname => null, tabname => 'quiz_results' );

select sysdate;
PRO Initial refreshes 
exec dbms_mview.refresh ( 'quiz_ranks', atomic_refresh => true );
exec dbms_mview.refresh ( 'quiz_ranks', atomic_refresh => false );
exec dbms_mview.refresh ( 'quiz_ranks', atomic_refresh => false, out_of_place => true );

