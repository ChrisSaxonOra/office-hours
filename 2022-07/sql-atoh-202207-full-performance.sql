@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-setup"
set pages 100
set lines 320
--spool sql-atoh-202207-perf.log
cl scr
set serveroutput on
truncate table customers_stage;
insert /*+ append */into customers_stage
with rws as (
  select level id from dual
  connect by level <= 100000
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
  run_id integer := customer_merge_id.nextval;
begin    
  
  insert /* monitor */ into customers_dim (
    customer_id, full_name, birth_date, merge_run_id
  )
    select customer_id, full_name, birth_date, run_id
    from   customers_stage cs
    where  not exists (
      select null from customers_dim cd
      where  cs.customer_id = cd.customer_id
    );
  
  dbms_output.put_line ( 'Inserted ' || sql%rowcount );
    
  update /* monitor */ (
    select cs.full_name as full_name_stage, 
           cd.full_name as full_name_dim,
           cd.update_datetime,
           cd.merge_run_id
    from   customers_stage cs
    join   customers_dim cd
    on     cs.customer_id = cd.customer_id
  ) cd
  set    full_name_dim = full_name_stage,
         update_datetime = systimestamp
  where  merge_run_id <> run_id;
  
  dbms_output.put_line ( 'Updated ' || sql%rowcount );
end indate_data;
/

create or replace procedure upsert_data as
begin 
    
  update /* monitor */ (
    select cs.full_name as full_name_stage, 
           cd.full_name as full_name_dim,
           cd.update_datetime
    from   customers_stage cs
    join   customers_dim cd
    on     cs.customer_id = cd.customer_id
  ) cd
  set    full_name_dim = full_name_stage,
         update_datetime = systimestamp;   
  
  dbms_output.put_line ( 'Updated ' || sql%rowcount );
  
  insert /* monitor */into customers_dim (
    customer_id, full_name, birth_date, merge_run_id
  )
    select customer_id, full_name, birth_date, customer_merge_id.nextval
    from   customers_stage cs
    where  not exists (
      select null from customers_dim cd
      where  cs.customer_id = cd.customer_id
    );
  
  dbms_output.put_line ( 'Inserted ' || sql%rowcount );
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
      systimestamp, systimestamp, customer_merge_id.nextval 
    )
  when matched then 
    update
    set cd.full_name = cs.full_name,
        cd.update_datetime = systimestamp;
        
  dbms_output.put_line ( 'Merged ' || sql%rowcount );
end merge_data;
/


create or replace procedure remove_half as
begin
--  delete customers_dim cd
--  where  customer_id <= 50000;
  execute immediate 
    'alter table customers_dim move including rows 
     where customer_id > 50000 or customer_id < 0 online';
end remove_half;
/

--@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-plans"
--@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-performance"

/**************

With stats - empty table

**************/
truncate table customers_dim;
exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_STAGE', no_invalidate => false ) ;
exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_DIM', no_invalidate => false ) ;

PRO With stats - empty table
--@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-plans"
@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-performance"

exec merge_data();
commit;
exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_STAGE', no_invalidate => false ) ;
exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_DIM', no_invalidate => false ) ;
truncate table customers_dim;

/**************

With stats - full table

**************/
PRO With stats - full table
--@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-plans"
@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-performance"

truncate table customers_dim;

insert /*+ append */into customers_dim
with rws as (
  select level id from dual
  connect by level <= 1000000
)
  select -id, 
         initcap ( 
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) || ' ' ||
           dbms_random.string ( 'l', dbms_random.value ( 2, 10 ) ) 
         ) nm,
         date'1920-01-01' +
           numtoyminterval ( dbms_random.value ( 2, 1200 ), 'month' ) +
           numtodsinterval ( round ( dbms_random.value ( 1, 31 ) ), 'day' ) dt,
         systimestamp, 
         systimestamp,
         0
  from   rws;
commit;

exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_STAGE', no_invalidate => false ) ;
exec dbms_stats.gather_table_stats ( user, 'CUSTOMERS_DIM', no_invalidate => false ) ;

/**************

With stats - target full with non-mergeable rows

**************/
PRO With stats - target full with non-mergeable rows
--@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-plans"
@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202207-performance"


PRO With stats - target full with correlated update

create or replace procedure upsert_data_correlated as
begin

  update customers_dim cd
  set    ( full_name, update_datetime ) = (
    select cs.full_name, systimestamp
    from   customers_stage cs
    where  cs.customer_id = cd.customer_id
  )
  where  exists (
    select * from customers_stage cs
    where  cs.customer_id = cd.customer_id
  );
  
  dbms_output.put_line ( 'Updated ' || sql%rowcount );

  insert /* monitor */into customers_dim (
    customer_id, full_name, birth_date, merge_run_id
  )
    select customer_id, full_name, birth_date, customer_merge_id.nextval
    from   customers_stage cs
    where  not exists (
      select null from customers_dim cd
      where  cs.customer_id = cd.customer_id
    );
  
  dbms_output.put_line ( 'Inserted ' || sql%rowcount );
end upsert_data_correlated;
/

begin
  remove_half();
  timing_pkg.set_start_time;
  upsert_data_correlated();
  timing_pkg.calc_runtime ( 'correlated upsert 50:50' );  
end;
/
/
begin
  timing_pkg.set_start_time;
  upsert_data_correlated();
  timing_pkg.calc_runtime ( 'correlated upsert 50:50' );  
end;
/
/

spool off