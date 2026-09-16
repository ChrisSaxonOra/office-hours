@"C:\Users\csaxon\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202105-setup"

create sequence s;
create table t (
  t_id int 
    default on null s.nextval
    primary key, 
  insert_date date
    default on null sysdate
);



insert into t ( t_id )
values ( default );
commit;
select * from t;




/* Build APIs */
create or replace procedure ins_row ( 
  new_id          out t.t_id%type,
  new_insert_date out t.insert_date%type
) as
begin
 
  insert into t 
  values ( default, default )
  returning t_id, insert_date 
  into new_id, new_insert_date;

end ins_row;
/

create or replace procedure ins_rec ( 
  tab_rec in out t%rowtype
) as
begin
 
  insert into t 
  values tab_rec
  returning t_id, insert_date 
  into tab_rec.t_id, tab_rec.insert_date;

end ins_rec;
/

declare
  new_id          t.t_id%type;
  new_insert_date t.insert_date%type;
begin
  ins_row ( new_id, new_insert_date );
  dbms_output.put_line ( 
    'Inserted ' || new_id
  );
end;
/

declare
  tab_rec t%rowtype;
begin
  ins_rec ( tab_rec );
  dbms_output.put_line ( 
    'Inserted ' || tab_rec.t_id
  );
end;
/




alter table t
  add c3 int;
  
  
declare
  new_id          t.t_id%type;
  new_insert_date t.insert_date%type;
begin
  ins_row ( new_id, new_insert_date );
  dbms_output.put_line ( 
    'Inserted ' || new_id
  );
end;
/

declare
  tab_rec t%rowtype;
begin
  ins_rec ( tab_rec );
  dbms_output.put_line ( 
    'Inserted ' || tab_rec.t_id
  );
end;
/

/***************************





***************************/

select * from t;

/* Make invisible */
alter table t 
  modify insert_month invisible;
  
/* Add virtual column */
alter table t 
  add ( 
    insert_month as ( 
      trunc ( insert_date, 'mm' )
    )
  );
  
  
/* Must specify c3 to insert it */
insert into t ( c3 ) 
values ( 42 );
  
  
/* C3 now hidden */
select * from t;
select t_id, insert_date, c3 from t;


/* Re-run APIs */  
declare
  new_id          t.t_id%type;
  new_insert_date t.insert_date%type;
begin
  ins_row ( new_id, new_insert_date );
  dbms_output.put_line ( 
    'Inserted ' || new_id
  );
end;
/

declare
  tab_rec t%rowtype;
begin
--  tab_rec.c3 := 1;
  ins_rec ( tab_rec );
  dbms_output.put_line ( 
    'Inserted ' || tab_rec.t_id
  );
end;
/

select * from t;



/* Insert into views */
create or replace view vw as 
  select t_id, insert_date, c3
  from   t;
  
declare
  t_rec vw%rowtype;
begin
  t_rec.c3 := 99;
  insert into t
  values t_rec;
  
end;
/

select * from vw;
select c3 from t;


create or replace view vw as 
  select t_id, insert_date, c3
  from   t
  where  insert_date > sysdate
  with check option;
  
declare
  t_rec vw%rowtype;
begin
  t_rec.insert_date := sysdate + 1;
  insert into vw
  values t_rec;
  
end;
/


create table t_child ( 
  t_child_id int
    default on null s.nextval
    primary key,
  t_id references t
);

create or replace view vw_child as 
  select t_child_id 
  from   t
  join   t_child
  using  ( t_id );
  
declare
  t_rec vw_child%rowtype;
begin

  insert into vw_child
  values t_rec;
  
end;
/

select * from t_child;

alter table t_child
  drop primary key;
alter table t
  drop primary key
  cascade;

declare
  t_rec vw_child%rowtype;
begin

  insert into vw_child
  values t_rec;
  
end;
/


create or replace view vw_parent as 
  select c3, insert_date
  from   t
  join   t_child
  using  ( t_id );
  
declare
  t_rec vw_parent%rowtype;
begin

  insert into vw_parent
  values t_rec;
  
end;
/

create or replace trigger vw_parent_ii
instead of insert on vw_parent
for each row
begin
  insert into t ( insert_date, c3 )
  values ( :new.insert_date, :new.c3 );
end;
/

declare
  t_rec vw_parent%rowtype;
begin

  insert into vw_parent
  values t_rec;
  
end;
/

select * from t;




/***********************




***********************/

truncate table t;
truncate table t_child;

/* Multi-row insert */
begin
  insert into t ( t_id )
  with rws as (
    select level c1 from dual
    connect by level <= 10
  )
    select c1 from rws;
    
  dbms_output.put_line ( 'Loaded ' || sql%rowcount || ' rows' );
end;
/
  
select * from t;



/* Multi-table insert */
insert all
  into t ( c3 ) values ( v )
  into t_child ( t_child_id ) values ( null )
  select 42 v from dual;
  
select * from t;
select * from t_child;


/* Can't use sequence */
insert all
  into t ( t_id, c3 ) values ( id, v )
  into t_child ( t_id, t_child_id ) values ( id, null )
  select s.nextval id, 42 v from dual;


/* Add constraints back */
alter table t
  add primary key ( t_id );
alter table t_child
  add foreign key ( t_id )
  references t
  deferrable initially immediate;
  
alter table t_child
  add ( c2 varchar2(4000), c3 varchar2(4000) );
  
/* Insert-all order is intederminate;
   could lead to FK errors */
insert all
  when rn = 1 then 
    into t ( t_id ) 
    values ( id )
  when 1 = 1 then 
    into t_child ( t_id ) 
    values ( id )
  select 99 id, level rn from dual
  connect by level <= 2;

select * from t;
select * from t_child;


alter session set constraints = deferred;

insert all
  when rn = 1 then 
    into t ( t_id ) 
    values ( s.nextval )
  when 1 = 1 then 
    into t_child ( t_id ) 
    values ( s.nextval )
  select 100 id, 1 rn from dual;
  
alter session set constraints = immediate;

select * from t;
select * from t_child;

  
/***********************




***********************/

select * from v$version;

begin
  timing_pkg.set_start_time;
  insert into t ( t_id, insert_date )
    values ( default, default ); 
  timing_pkg.calc_runtime ( 'Insert-values', 1 ); 
end;
/



create table source_t as
  select * from dba_objects;
  
create table target_t as
  select * from dba_objects
  where  1 = 0;
  
select count(*) from source_t;

declare
  num_rows pls_integer := 75435;
  
  type t_arr is 
    table of target_t%rowtype
    index by pls_integer;
  
  t_recs t_arr;
begin
  for i in 1 .. num_rows loop 
    t_recs ( i ).object_id := i;
  end loop; 
  
  execute immediate 'truncate table target_t';
  
  timing_pkg.set_start_time; 
  for i in ( select * from  source_t ) loop 
    insert into target_t
    values t_recs ( i );
  end loop; 
  timing_pkg.calc_runtime ( 'Insert-loop', num_rows ); 
  
  execute immediate 'truncate table target_t';
  
  timing_pkg.set_start_time; 
  forall i in 1 .. num_rows 
    insert into target_t
    values t_recs ( i );
  timing_pkg.calc_runtime ( 'Insert-forall', num_rows ); 
  /* %rowcount works with bulk loads too */
  dbms_output.put_line ( 'Loaded ' || sql%rowcount );
  
  execute immediate 'truncate table target_t';
  
  timing_pkg.set_start_time; 
  insert into target_t
    select * from source_t;
  timing_pkg.calc_runtime ( 'Insert-select', num_rows ); 
  commit;
end;
/


/* Check plan */
insert /*+ parallel */into target_t
  select * from source_t;




alter session enable parallel dml;


/* By default parallel & append (direct-path) */
insert /*+ parallel */into target_t
  select * from source_t;
  
select * from target_t;
truncate table target_t;

begin
  for i in 1 .. 5 loop
    insert into source_t
      select * from source_t;
  end loop;
  commit;
end;
/

select count (*) from source_t;

select bytes/1024/1024 
from   user_segments
where  segment_name = 'SOURCE_T';

declare
  start_time pls_integer;
  iterations pls_integer := 3;
begin
  execute immediate 'alter session enable parallel dml';
  execute immediate 'truncate table target_t';
  
  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    for rws in (
      select * from source_t
    ) loop
      null;
    end loop;
  end loop;
  timing_pkg.calc_runtime ( 'Select', iterations ); 
  
  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert into target_t
      select * from source_t;
    execute immediate 'truncate table target_t';
  end loop;
  timing_pkg.calc_runtime ( 'Insert-select', iterations ); 
  
  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert /*+ append */into target_t
      select * from source_t;
    execute immediate 'truncate table target_t';
  end loop;
  timing_pkg.calc_runtime ( 'Insert-select-append', iterations );
  
  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert /*+ parallel noappend */into target_t
      select * from source_t;
    execute immediate 'truncate table target_t';
  end loop;
  timing_pkg.calc_runtime ( 'Insert-select-parallel', iterations );
  
  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert /*+ parallel */into target_t
      select * from source_t;
    execute immediate 'truncate table target_t';
  end loop;
  timing_pkg.calc_runtime ( 'Insert-select-parallel-append', iterations );

end;
/

/***********************





***********************/




create table unindex (
  c1 int, c2 int, c3 int, c4 int, c5 int, 
  c6 int, c7 int, c8 int, c9 int, c10 int
);
create table indexed_nulls as
 select * from unindex;
create table indexed as
 select * from unindex;
 select * from unindex;
create table indexed5 as
 select * from unindex;
 
begin
  for i in 1 .. 10 loop
    execute immediate 'create index in' || i || ' on indexed_nulls ( c' || i || ')';
    execute immediate 'create index id' || i || ' on indexed ( c' || i || ')';
    if i <= 5 then
      execute immediate 'create index i5d' || i || ' on indexed5 ( c' || i || ')';
    end if;
  end loop;
end;
/
 
declare
  start_time pls_integer;
  iterations pls_integer := 100000;
begin
  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert into unindex 
    values ( 
      i, i, i, i, i,
      i, i, i, i, i
    );
  end loop;
  timing_pkg.calc_runtime ( 'insert-unindexed', iterations );
  commit;

  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert into indexed_nulls 
    values ( 
      i, null, null, null, null, 
      null, null, null, null, null
    );
  end loop;
  timing_pkg.calc_runtime ( 'insert-mostly-null', iterations );
  commit;
  
  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert into indexed5
    values ( 
      i, i, i, i, i,
      i, i, i, i, i
    );
  end loop;
  timing_pkg.calc_runtime ( 'insert-5-indexes', iterations );
  commit;

  timing_pkg.set_start_time; 
  for i in 1 .. iterations loop
    insert into indexed
    values ( 
      i, i, i, i, i,
      i, i, i, i, i
    );
  end loop;
  timing_pkg.calc_runtime ( 'insert-all-indexed', iterations );
  commit;
end;
/

drop table indexed_nulls
  cascade constraints purge;
drop table indexed
  cascade constraints purge;
drop table indexed5
  cascade constraints purge;
drop table unindex
  cascade constraints purge;