@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-setup"


select * from customers_stage;
select * from customers_dim;




/* Load them all in */
merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when not matched then 
  insert ( 
    cd.customer_id, cd.full_name, cd.birth_date 
  ) values ( 
    cs.customer_id, cs.full_name, cs.birth_date
  )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp;



/* All loaded? */
select count (*) from customers_dim;

/* And verify */
select customer_id, full_name, birth_date 
from   customers_dim
minus  
select * from customers_stage;





/* Change some names */
update customers_stage
set    full_name = 'New Name'
where  customer_id <= 10;

/* Re-run; everything's an update */
merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when not matched then 
  insert ( 
    cd.customer_id, cd.full_name, cd.birth_date 
  ) values ( 
    cs.customer_id, cs.full_name, cs.birth_date
  )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp;



/* New names loaded... */
select customer_id, full_name, birth_date 
from   customers_dim
where  full_name = 'New Name';

/* ...but we unnecessarily updated every row */
select update_datetime, count(*)
from   customers_dim
group  by update_datetime;



/* More updates */
update customers_stage
set    full_name = 'Another New Name'
where  customer_id <= 10;


/* Only update if changed */
merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp
  where cd.full_name <> cs.full_name;
  
  

select update_datetime, count(*)
from   customers_dim
group  by update_datetime
order  by update_datetime;




truncate table customers_dim;

/* Conditional inserts are possible too */
merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when not matched then 
  insert ( 
    cd.customer_id, cd.full_name, cd.birth_date 
  ) values ( 
    cs.customer_id, cs.full_name, cs.birth_date
  )
  where  cs.customer_id <= 50;

select count (*) from customers_dim;



/* Merge bind values */
merge into customers_dim cd
using dual
on   ( customer_id = :cust_id )
when not matched then 
  insert ( 
    cd.customer_id, cd.full_name, cd.birth_date 
  ) values ( 
    :cust_id, :full_name, to_date ( :birthday, 'dd/mm/yyyy' )
  )
when matched then 
  update
  set cd.full_name = :full_name,
      cd.update_datetime = systimestamp;
      

/* Verify */ 
select * from customers_dim
where  customer_id = :cust_id;
/* Re-run merge with new name */



rollback;


/************************************************





************************************************/

truncate table customers_dim;

create table inserted_customers (
  customer_id     integer, 
  insert_datetime timestamp
);

create table updated_customers (
  customer_id     integer, 
  update_datetime timestamp
);

/* Track merge changes */
create or replace trigger merge_tracking_trig
for insert or update on customers_dim
compound trigger
  updated_rows   dbms_sql.number_table;
  inserted_rows  dbms_sql.number_table;
  merge_datetime timestamp := systimestamp;

  after each row is
  begin
    if inserting then 
      inserted_rows ( :new.customer_id ) := 
        :new.customer_id;
    elsif updating then
      updated_rows ( :new.customer_id ) := 
        :new.customer_id;
    end if;
  end after each row;
  
  after statement is
  begin
    forall i in indices of updated_rows
      insert into updated_customers 
      values ( updated_rows(i), merge_datetime );
    
    forall i in indices of inserted_rows
      insert into inserted_customers 
      values ( inserted_rows(i), merge_datetime );
  end after statement;

end merge_tracking_trig;
/

/* Get insert vs update counts */
declare
  procedure upsert_customers as 
    trans_id raw(1000);
  begin
    
    merge /*+ monitor */into customers_dim cd
    using customers_stage cs
    on    ( cd.customer_id = cs.customer_id )
    when not matched then 
      insert ( 
        cd.customer_id, cd.full_name, cd.birth_date 
      ) values ( 
        cs.customer_id, cs.full_name, cs.birth_date
      )
    when matched then 
      update
      set cd.full_name = cs.full_name,
          cd.update_datetime = systimestamp
      where  cd.full_name <> cs.full_name;
    
    select xid into trans_id from v$transaction;
    dbms_output.put_line ( 
      'Merged ' || sql%rowcount || 
      ' XID ' || rawtohex ( trans_id )
    );
  end;
begin
  upsert_customers;
  
  commit;
  
  /* Change source */
  update customers_stage
  set    full_name = 'New Name ' || rownum
  where  customer_id <= 10;
  
  /* Remove from target */
  delete customers_dim
  where  customer_id > 90;
  
  commit;
  
  upsert_customers;

end;
/


/* Find changes from logging tables */
select nvl ( insert_datetime, update_datetime ) change_time, 
       count (*) , 
       count ( insert_datetime ), 
       count ( update_datetime )
from   inserted_customers
full outer join updated_customers
on     insert_datetime = update_datetime
group  by nvl ( insert_datetime, update_datetime )
order  by change_time;




/* Flashback versions query to find operations */
select versions_xid, versions_operation, count(*) 
from   customers_dim
  versions between scn 
  minvalue and maxvalue
group  by versions_xid, rollup ( versions_operation )
order  by versions_xid;




/* Need to commit to see last transaction! */
commit;




/* Get stats from SQL monitor */
select m.last_refresh_time, 
       s1.name, otherstat_1_value insert_count, 
       s2.name, otherstat_2_value update_count, 
       s3.name, otherstat_3_value delete_count
from   v$sql_plan_monitor m
left join v$sql_monitor_statname s1
on     m.otherstat_1_id = s1.id
and    s1.name like 'MERGE%'
left join   v$sql_monitor_statname s2
on     m.otherstat_2_id = s2.id
and    s2.name like 'MERGE%'
left join   v$sql_monitor_statname s3
on     m.otherstat_3_id = s3.id
and    s3.name like 'MERGE%'
where  nvl ( s1.name, s2.name ) is not null
order  by last_refresh_time desc;




/* Add duplicate source row */
alter table customers_stage
  drop primary key;
insert into customers_stage 
  values ( 1, 'Duplicate Customer', trunc ( sysdate ) );

select * from customers_stage 
where  customer_id = 1;

/* M:1 source -> target =>
   ORA-30926: unable to get a stable set of rows in the source tables
*/
merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp;
      
      
      
/* 
  Error only triggered on second update! 
  If target only changed once => success
*/
merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp
  where cd.full_name <> cs.full_name;
  
/* Re-run above; name flips back and forth */
select * from customers_dim
where  customer_id = 1;



/* Remove duplicate in source query */
merge into customers_dim cd
using ( 
  with rws as (
    select cs.*, 
      row_number() over ( 
        partition by customer_id 
        order by birth_date desc 
      ) rn
    from   customers_stage cs
  )
    select * from rws
    where  rn = 1
) cs
on    ( cd.customer_id = cs.customer_id )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp;

/* Result now consistent */
select * from customers_dim
where  customer_id = 1;



/* Remove rows from source */
delete customers_stage
where  customer_id < 11;

/* Use full outer join to identify removed rows */
create or replace view customer_stage_dim as
  select customer_id,
         nvl ( cs.full_name, cd.full_name ) full_name,
         nvl ( cs.birth_date, cd.birth_date ) birth_date,
         case 
           when cs.full_name is null then 'Y' 
           else 'N'
         end to_delete
  from   customers_dim cd
  full  join customers_stage cs
  using  ( customer_id );
  
select * from customer_stage_dim
order  by customer_id;

select * from customers_dim cd
join  customer_stage_dim cs
on    ( cd.customer_id = cs.customer_id );

/* Delete only removes updated rows */
merge into customers_dim cd
using customer_stage_dim cs
on    ( cd.customer_id = cs.customer_id )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp
  where  to_delete = 'N'
  delete where to_delete = 'Y';

/* So all the removed rows are still here! */
select * from customers_dim
where  customer_id < 11;


/* Delete only operates on updated rows */
merge /*+ monitor */into customers_dim cd
using customer_stage_dim cs
on    ( cd.customer_id = cs.customer_id )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp
  delete where cs.to_delete = 'Y';

/* Now they're gone! */
select * from customers_dim
where  customer_id < 11;


/* Get stats from SQL monitor */
select m.last_refresh_time, 
       s1.name, otherstat_1_value insert_count, 
       s2.name, otherstat_2_value update_count, 
       s3.name, otherstat_3_value delete_count
from   v$sql_plan_monitor m
left join v$sql_monitor_statname s1
on     m.otherstat_1_id = s1.id
and    s1.name like 'MERGE%'
left join   v$sql_monitor_statname s2
on     m.otherstat_2_id = s2.id
and    s2.name like 'MERGE%'
left join   v$sql_monitor_statname s3
on     m.otherstat_3_id = s3.id
and    s3.name like 'MERGE%'
where  nvl ( s1.name, s2.name ) is not null
order  by last_refresh_time desc;



/***************************



***************************/

set serveroutput off
truncate table customers_stage;
truncate table customers_dim;
alter table customers_stage
  add constraint stage_pk
  primary key ( customer_id );
  
insert into customers_stage
with rws as (
  select level id from dual
  connect by level <= 10000
)
  select id, 
         initcap ( 
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) || ' ' ||
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) 
         ) nm,
         date'1920-01-01' +
           numtoyminterval ( dbms_random.value ( 2, 1200 ), 'month' ) +
           numtodsinterval ( round ( dbms_random.value ( 1, 31 ) ), 'day' ) dt
  from   rws;
  
insert into customers_dim ( customer_id, full_name, birth_date )
  select customer_id, full_name, birth_date from customers_stage;
  
commit;
exec dbms_stats.gather_table_stats ( null, 'customers_stage' ) ;
exec dbms_stats.gather_table_stats ( null, 'customers_dim' ) ;

select * from customers_dim cd
right join customers_stage cs
on    ( cd.customer_id = cs.customer_id );

alter session set statistics_level = all;
set serveroutput off

merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp
  where  cs.full_name <> cd.full_name;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));

update (
  select cs.full_name as full_name_stage, 
         cd.full_name as full_name_dim,
         cd.update_datetime
  from   customers_stage cs
  join   customers_dim cd
  on     cs.customer_id = cd.customer_id
  and    cs.full_name <> cd.full_name
) cd
set    full_name_dim = full_name_stage,
       update_datetime = systimestamp;   
  
select * 
from   table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


update (
  select cs.full_name as full_name_stage, 
         cd.full_name as full_name_dim,
         cd.update_datetime,
         count (*) over () c
  from   customers_stage cs
  join   customers_dim cd
  on     cs.customer_id = cd.customer_id
) cd
set    full_name_dim = full_name_stage,
       update_datetime = systimestamp;  


update customers_dim cd
set    ( full_name, update_datetime ) = (
  select cs.full_name, systimestamp
  from   customers_stage cs
  where  cs.customer_id = cd.customer_id
)
where  exists (
  select * from customers_stage cs
  where  cs.customer_id = cd.customer_id
  and    cs.full_name <> cd.full_name
);

select * 
from   table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));



/***************************





***************************/








truncate table customers_dim;


/* Merge an array */
declare
  type customer_rec is record (
    customer_id integer,
    full_name   varchar2(100),
    birth_date  date
  );
  type customer_arr 
    is table of customer_rec
    index by pls_integer;
  
  customer_data customer_arr;
begin

  customer_data := customer_arr (
    for i in 1 .. 10 => customer_rec (
      -i, 'Test', trunc ( sysdate )
    )
  );
  
  forall i in indices of customer_data
    merge into customers_dim cd
    using dual
    on   ( customer_id = customer_data ( i ).customer_id )
    when not matched then 
      insert
      values ( 
        customer_data ( i ).customer_id, 
        customer_data ( i ).full_name, 
        customer_data ( i ).birth_date, 
        systimestamp, systimestamp 
      )
    when matched then 
      update
      set cd.full_name = customer_data ( i ).full_name,
          cd.update_datetime = systimestamp;
  
end;
/

select * from customers_dim
order  by 1;


/*

begin
  for custs in (
    select * from customers_stage
  ) loop
    insert into customers_dim 
    values ( 
      custs.customer_id, custs.full_name, custs.birth_date, 
      systimestamp, systimestamp 
    ); 
  end loop;
end;
/


begin
  for custs in (
    select * from customers_stage
  ) loop
    begin
      insert into customers_dim 
      values ( 
        custs.customer_id, custs.full_name, custs.birth_date, 
        systimestamp, systimestamp 
      ); 
    exception
      when DUP_VAL_ON_INDEX then
        update customers_dim cd
        set    
          cd.full_name = custs.full_name,
          cd.update_datetime = systimestamp
        where  cd.customer_id = custs.customer_id
        and    cd.full_name <> custs.full_name;
    end;
  end loop;
end;
/




exec dbms_errlog.create_error_log ( 'customers_dim' );

/* Trap the exceptions; update the differences /
begin
  insert into customers_dim (
    customer_id, full_name, birth_date
  )
    select customer_id, full_name, birth_date
    from   customers_stage
    log    errors
    reject limit unlimited;
    
  update customers_dim cd
  set    cd.full_name = (
    select cs.full_name from customers_stage cs
    where  cs.customer_id = cd.customer_id
  )
  where  exists (
    select null from customers_stage cs
    where  cs.customer_id = cd.customer_id
    and    cs.full_name <> cd.full_name
  );
end;
/
*/

















/***********************

drop table t 
  cascade constraints purge;
drop table tnew
  cascade constraints purge;
  
create table t ( x int primary key, y int );
create table tnew ( x int, y int );
insert into t values ( 1, 1 );
insert into tnew values ( 1, 1 );
insert into tnew values ( 2, 2 );

commit;

create or replace trigger t_bufer
 before update on t for each row
 begin
         dbms_output.put_line
         ( 'old.x = ' || :old.x ||
           ', old.y = ' || :old.y );
         dbms_output.put_line
         ( 'new.x = ' || :new.x ||
           ', new.y = ' || :new.y );
end;
/

create or replace trigger t_bifer
 before insert on t
 begin
         dbms_output.put_line
         ( 'Statement-level ' );
end;
/
create or replace trigger t_bifer
 before insert on t for each row
 begin
         dbms_output.put_line
         ( 'Adding x = ' || :new.x ||
           ', y = ' || :new.y );
end;
/
/*
set serveroutput on
update t set x = x+1;


set serveroutput on
update t set x = x+1 where x > 0;
/

merge into t
using dual
on   ( y = 1 )
when matched then update
  set x = x+1
  where  x > 0 ;

merge into t
using tnew n
on   ( t.x = n.x )
when matched then update
  set t.y = t.y+1
  where t.y > 0 
when not matched then insert
  values ( n.y, n.x ); 

select xid from v$transaction;
truncate table t;
select versions_operation, versions_xid, 
  versions_startscn, versions_endscn ,
  t.*
from   t
  versions between scn minvalue and maxvalue
where versions_xid = hextoraw ( '080001000A740000' );
  
select * from flashback_transaction_query;

select * from t;
select * from tnew;
-- merge does suffer 
declare
  arr dbms_sql.number_table;
begin
  arr := dbms_sql.number_table (
    for i in 1 .. 10 => i
  );
  
  forall i in indices of arr
    merge into t
    using dual
    on   ( t.x = arr(i) )
    when matched then update
      set t.y = t.y+1
      where t.y > 0 
    when not matched then insert
      values ( arr(i), 1 ); 

end;
/

declare
  arr dbms_sql.number_table;
begin
  arr := dbms_sql.number_table (
    for i in 3 .. 10 => i
  );
  
  forall i in indices of arr 
  save exceptions
    insert into t values ( arr(i), 1 ); 

end;
/

merge into customers_dim cd
    using customers_stage cs
    on    ( cd.customer_id = cs.customer_id )
    when not matched then 
      insert
      values ( 
        cs.customer_id, 
        cs.full_name, cs.birth_date, 
        systimestamp, systimestamp 
      )
    when matched then 
      update
      set cd.full_name = cs.full_name || dbms_random.string ('l', 1 ),
          cd.update_datetime = systimestamp
      where  cd.full_name < 'C%';
      
create or replace trigger restart_test
before insert or update on customers_dim
for each row
begin
  dbms_output.put_line ( 'Restart test updating ' || :new.customer_id );
end;
/

************************/


set serveroutput on
truncate table customers_stage;
insert into customers_stage
with rws as (
  select level id from dual
  connect by level <= 500000
)
  select id, 
         initcap ( 
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) || ' ' ||
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) 
         ) nm,
         date'1920-01-01' +
           numtoyminterval ( dbms_random.value ( 2, 1200 ), 'month' ) +
           numtodsinterval ( round ( dbms_random.value ( 1, 31 ) ), 'day' ) dt
  from   rws;
commit;
/**/
truncate table customers_dim;
cl scr

create or replace procedure indate_data as
begin    
  
  insert /* monitor */ into customers_dim (
    customer_id, full_name, birth_date
  )
    select customer_id, full_name, birth_date
    from   customers_stage cs
    where  not exists (
      select null from customers_dim cd
      where  cs.customer_id = cd.customer_id
    );
    
  update /* monitor */ (
    select cs.full_name as full_name_stage, 
           cd.full_name as full_name_dim
    from   customers_stage cs
    join   customers_dim cd
    on     cs.customer_id = cd.customer_id
    and    cs.full_name <> cd.full_name
  ) cd
  set    full_name_dim = full_name_stage;
end indate_data;
/

create or replace procedure upsert_data as
begin 
    
  update /* monitor */ (
    select cs.full_name as full_name_stage, 
           cd.full_name as full_name_dim
    from   customers_stage cs
    join   customers_dim cd
    on     cs.customer_id = cd.customer_id
    and    cs.full_name <> cd.full_name
  ) cd
  set    full_name_dim = full_name_stage;   
  
  insert /* monitor */into customers_dim (
    customer_id, full_name, birth_date
  )
    select customer_id, full_name, birth_date
    from   customers_stage cs
    where  not exists (
      select null from customers_dim cd
      where  cs.customer_id = cd.customer_id
    );
end upsert_data;
/

create or replace procedure merge_data as
begin
  merge /* monitor */into customers_dim cd
  using customers_stage cs
  on    ( cd.customer_id = cs.customer_id )
  when not matched then 
    insert
    values ( 
      cs.customer_id, cs.full_name, cs.birth_date, 
      systimestamp, systimestamp 
    )
  when matched then 
    update
    set cd.full_name = cs.full_name,
        cd.update_datetime = systimestamp
    where cd.full_name <> cs.full_name;
end merge_data;
/


begin
  timing_pkg.set_start_time;
  indate_data();
  timing_pkg.calc_runtime ( 'insert-update inserts' );
  timing_pkg.set_start_time;
  indate_data();
  timing_pkg.calc_runtime ( 'insert-update updates' );
  
  rollback;
  
  timing_pkg.set_start_time;
  upsert_data();
  timing_pkg.calc_runtime ( 'update-insert inserts' );
  timing_pkg.set_start_time;
  upsert_data();
  timing_pkg.calc_runtime ( 'update-insert updates' );
  
  rollback;
  
  timing_pkg.set_start_time;
  merge_data();
  timing_pkg.calc_runtime ( 'merge inserts' );
  timing_pkg.set_start_time;
  merge_data();
  timing_pkg.calc_runtime ( 'merge updates' );
  
  rollback;
  
end;
/
/
/
/


alter session set statistics_level = all;
set serveroutput off;
merge into customers_dim cd
using customers_stage cs
on    ( cd.customer_id = cs.customer_id )
when not matched then 
  insert
  values ( 
    cs.customer_id, cs.full_name, cs.birth_date, 
    systimestamp, systimestamp 
  )
when matched then 
  update
  set cd.full_name = cs.full_name,
      cd.update_datetime = systimestamp
  where cd.full_name <> cs.full_name;
select * 
from   table(dbms_xplan.display_cursor( format => 'ALLSTATS LAST'));
rollback;

select * from customers_stage;
select * from customers_dim;
truncate table customers_dim;
exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_STAGE', no_invalidate => false ) ;
exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_DIM', no_invalidate => false ) ;



create or replace package merge_pkg as 
  insert_count pls_integer := 0;
  
  function increment_insert_count
    return pls_integer;
  function  get_insert_count
    return pls_integer;
  function  get_update_count ( 
    row_count pls_integer 
  ) return pls_integer;
  
  procedure reset_counters;
end;
/

create or replace package body merge_pkg as 

  function increment_insert_count
    return pls_integer as
  begin
    insert_count := insert_count + 1;
    return 1;
  end;
  
  function  get_insert_count
    return pls_integer as 
  begin
    return insert_count;
  end;
  
  function  get_update_count ( 
    row_count pls_integer 
  ) return pls_integer as 
  begin
    return row_count - insert_count;
  end;
  
  procedure reset_counters as
  begin
    insert_count := 0;
  end;
end;
/