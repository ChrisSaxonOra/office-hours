drop table paint 
  cascade constraints purge;
drop table brush 
  cascade constraints purge;
  
create table paint (
  colour varchar2(10)
);
create table brush (
  colour varchar2(10)
);

drop table t 
  cascade constraints purge;
create table t (
  c1 int, c2 int
);

insert into t values ( 1, 1 );
insert into t values ( 2, 2 );
commit;

update t
set    c2 = 0
where  c1 = 1;


update t
set    c2 = 0
where  c1 = 2;





select * from t;

commit;

/*************************




*************************/

drop table parent_t 
  cascade constraints purge;
drop table child_t 
  cascade constraints purge;
  
create table parent_t (
  c1 int primary key, c2 int
);

create table child_t (
  c1 references parent_t ( c1 ), c2 int
);

insert into parent_t values ( 1, 1 );
insert into child_t values ( 1, 1 );
insert into parent_t values ( 2, 2 );
commit;



/* Session 1 */
insert into child_t values ( 1, 1 );

select * from child_t
where  c1 = 2;

/*
--Blocked in session 2
delete parent_t
where  c1 = 2;
*/

select * from dba_blockers;
select * from dba_dml_locks;
select * from dba_locks
where  con_id = 3;

/* in both sessions */
rollback;



drop index i2;
create index i2 on child_t ( c1 );

insert into child_t values ( 1, 1 );
insert into child_t values ( 2, 2 );



/*************************




*************************/



lock table paint
  in exclusive mode;
  
  
/*
In session two
lock table brush
  in exclusive mode;


lock table paint
  in exclusive mode;
*/

lock table brush
  in exclusive mode;





select * from dba_locks
where  con_id = 3;






/* Find deadlock details */
select trace_filename, payload, timestamp 
from   v$diag_trace_file_contents
where  trace_filename in ( 
  select trace_filename from v$diag_trace_file_contents
  where  timestamp > systimestamp - interval '1' hour
  and    lower ( payload ) like '%deadlock%'
)
and    line_number < 100;


/*************************




*************************/




truncate table t;
insert into t 
with rws as (
  select level x from dual
  connect by level <= 1000
)
  select x, x from rws;
commit;

select * from t;


/* Session 1 */
declare
  cursor cur is
    select * from t
    where  c1 = 10
    for update 
--      nowait;
      wait 2;
  rec cur%rowtype;
begin

  open cur;
  fetch cur into rec;
  
  update t
  set    c2 = -9999
  where  current of cur;
  
  close cur;
  
end;
/
select * from t
where  c1 = 10;

/*
 Session 2 
declare
  cursor cur is
    select * from t
    where  c1 <= 100
    for update 
      skip locked;
      
  type cur_arr
    is table of cur%rowtype 
    index by pls_integer;
  
  recs cur_arr;
begin

  open cur;
  
  fetch cur bulk collect into recs;
  
  forall i in 1 .. recs.count
    delete t
    where  c1 = recs (i).c1;
  
  close cur;
  
end;
/

select * from t
where  c1 <= 100;
*/

create or replace procedure p ( p int ) as
begin
  dbms_session.sleep ( p );
end p;
/

exec p ( 20 );