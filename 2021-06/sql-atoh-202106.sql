@"C:\Users\csaxon\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202106-setup"


select * from accounts
where  user_id = 1;

update accounts
set    email_address = 'chris.saxon@oracle.com'
where  user_id = 1;

select * from accounts
where  user_id = 1;
-- 2nd session; run update









commit;

select * from accounts
where  user_id = 1;

-- Check 2nd session



declare
  acct_rec accounts%rowtype;
begin
  acct_rec.email_address   := 'chris.saxon@oracle.com';
  acct_rec.last_login_time := systimestamp;
  acct_rec.full_name       := 'Chris Saxon';

  update accounts 
  set    row = acct_rec
  where  user_id = 1;
end;
/


declare
  acct_rec accounts%rowtype;
begin
  acct_rec.user_id         := 1;
  acct_rec.email_address   := 'chris.saxon@oracle.com';
  acct_rec.last_login_time := systimestamp;
  acct_rec.full_name       := 'Chris Saxon';

  update accounts 
  set    row = acct_rec
  where  user_id = 1;
end;
/


declare  
  type acct_details_cols is record (
    email_address accounts.email_address%type,
    full_name     accounts.full_name%type
  ); 
  
  acct_rec acct_details_cols;
begin
  acct_rec := acct_details_cols (
    email_address   => 'chris.saxon@oracle.com',
    full_name       => 'Chris Saxon'
  );
    
  update ( 
    select email_address, full_name 
    from   accounts 
    where  user_id = 1 
  )
  set    row = acct_rec;
end;
/
commit;



/* Update join - must be key preserved */
begin
  update ( 
    select a.email_address, a.last_login_time, 
           al.login_datetime
    from   accounts a
    join   account_logins al
    using  ( user_id )
    where  user_id = 1 
  )
  set    last_login_time = login_datetime;
end;
/

/* Can do the other way - sort of! */
begin
  update ( 
    select a.email_address, a.last_login_time, 
           al.login_datetime
    from   accounts a
    join   account_logins al
    using  ( user_id )
    where  user_id = 1 
  )
  set    login_datetime = last_login_time;
end;
/



/* Update join - can't have group by */
begin
  update ( 
    select last_login_time, max ( login_datetime ) mx
    from   accounts a
    join   account_logins al
    using  ( user_id )
    where  user_id = 1 
    group  by last_login_time
  )
  set    last_login_time = mx;
end;
/


/*************************************




*************************************/


update accounts
set    email_address = 'chris.saxon@oracle.com', 
       full_name     = 'Chris Saxon' 
where  user_id = 1;

commit;

select email_address, full_name
from   accounts
where  user_id = 1;
/* Fetch in session 2 */



update accounts
set    email_address = 'saxon.chris@oracle.com', -- change email address
       full_name     = 'Chris Saxon'  -- same name
where  user_id = 1;

commit;
/* Session 2 run update */






select * from accounts
where  user_id = 1;



/* Pessmistic locking */
select * from accounts
where  user_id = 1
for update nowait;
/* Session 2 for update */



update accounts
set    email_address = 'chris.saxon@oracle.com', -- same email
       full_name     = 'CHRIS SAXON' -- change name format
where  user_id = 1;

commit;

select * from accounts
where  user_id = 1;





/* Optimistic locking prep; create hashing function */
create or replace function hash_row (
  email_address accounts.email_address%type,
  full_name     accounts.full_name%type
) return raw deterministic as
begin
  return sys.dbms_crypto.hash (
    utl_raw.cast_to_raw (
      email_address || '#' || full_name
    ), 
    dbms_crypto.hash_sh1
  );
end hash_row;
/


alter table accounts add (
  last_updated_datetime date
    default sysdate
    not null,
  row_hash raw(64) as ( 
    cast ( hash_row (
      email_address, full_name   
    ) as raw(40) )
  )
);

create or replace trigger accounts_bu
before update on accounts
for each row
begin
  :new.last_updated_datetime := sysdate;
end;
/

/* reset */
update accounts
set    email_address = 'chris.saxon@oracle.com', 
       full_name     = 'Chris Saxon' 
where  user_id = 1;

commit;


/* Optimistic locking - fetch details */
select * from accounts
where  user_id = 1;
/* Session 2 fetch */




declare
  new_hash accounts.row_hash%type;
  new_time accounts.last_updated_datetime%type;
begin 
  update accounts
  set    email_address = 'chris.saxon@oracle.com',
         full_name     = 'CHRIS SAXON' -- change name format
  where  user_id = 1
  and    row_hash = 
    hextoraw ( 'C9C5ECF6B61142BFB4C34388462BA88D8CE569CF' )
  returning row_hash, last_updated_datetime
  into  new_hash, new_time;
    
  if sql%rowcount = 0 then 
    dbms_output.put_line ( 'Nothing updated' );
  else
    dbms_output.put_line ( new_hash || ' at ' || new_time );
  end if;
  
  commit;
  
end;
/
/* Session 2 optimistic update */



/* Size comparison */
select vsize ( last_updated_datetime ),
       vsize ( row_hash )
from   accounts;

/* TS vs. hash runtime */
set serveroutput on
declare
  row_count pls_integer;
begin
  select count(*) into row_count from accounts;

  timing_pkg.set_start_time;
  for rw in ( 
    select last_updated_datetime from accounts
  ) loop
    null;
  end loop;
  timing_pkg.calc_runtime ( 'TS', row_count );
  
  timing_pkg.set_start_time;
  for rw in ( 
    select row_hash from accounts
  ) loop
    null;
  end loop;
  timing_pkg.calc_runtime ( 'Hash', row_count );
end;
/



/* Returning many rows */
declare
  type login_arr is
    table of accounts.last_login_time%type
    index by pls_integer;
    
  login_recs login_arr;
begin
  update accounts
  set    last_login_time = last_login_time + user_id
  where  user_id <= 10
  returning last_login_time
  bulk collect into login_recs;
  
  for i in 1 .. login_recs.count loop
    dbms_output.put_line ( 'New login = ' || login_recs(i) );
  end loop;
  
  rollback;
end;
/


declare
  max_login  timestamp;
  num_login  pls_integer;
begin
  update accounts
  set    last_login_time = last_login_time + 1
  where  user_id <= 100
  returning max ( last_login_time ), count (*)
  into   max_login, num_login;
  
  dbms_output.put_line ( 'Max login = ' || max_login || ' # changes ' || num_login );
  
  rollback;
end;
/







/*************************************




*************************************/


select count(*), count ( distinct user_id )
from   account_logins
where  login_datetime >= date'2021-05-31';

set timing on
set serveroutput on
declare
  rws pls_integer := 0;
begin 
 
  for acct in ( 
    select user_id, max ( login_datetime ) login_datetime 
    from   account_logins
    where  login_datetime >= date'2021-05-31'
    group  by user_id
  ) loop
    update accounts a
    set    last_login_time = acct.login_datetime
    where  a.user_id = acct.user_id;
    
    rws := rws + 1;
  end loop;
  
  dbms_output.put_line ( 'Updated ' || rws );
  
end;
/
rollback;



drop trigger accounts_bu;


declare
  rws pls_integer := 0;
begin 
 
  for acct in ( 
    select user_id, max ( login_datetime ) login_datetime 
    from   account_logins
    where  login_datetime >= date'2021-05-31'
    group  by user_id
  ) loop
    update accounts a
    set    last_login_time = acct.login_datetime,
           last_updated_datetime = sysdate
    where  a.user_id = acct.user_id;
    
    rws := rws + 1;
  end loop;
  
  dbms_output.put_line ( 'Updated ' || rws );
  
end;
/
rollback;





--cl scr
alter session set statistics_level = all;
set serveroutput off

update accounts a
set    ( last_updated_datetime, last_login_time ) = (
  select /*+ qb_name ( st ) */
         sysdate,
         max ( login_datetime ) login_datetime
  from   account_logins al
  where  a.user_id = al.user_id
)
where  exists (
  select null
  from   account_logins al
  where  login_datetime >= date'2021-05-31'
  and    a.user_id = al.user_id
);

select * 
from   dbms_xplan.display_cursor ( 
  format => 'ALLSTATS LAST +ALIAS'
);
rollback;




merge into accounts a
using (
  select user_id, max ( login_datetime ) login_datetime
  from   account_logins
  where  login_datetime >= date'2021-05-31'
  group  by user_id
) al
on   ( a.user_id = al.user_id )
when matched then 
  update set 
    a.last_login_time = al.login_datetime, 
    a.last_updated_datetime = sysdate;
  
select * 
from   dbms_xplan.display_cursor( format => 'ALLSTATS LAST');
rollback;






create table accounts_upd (
  user_id not null primary key,
  email_address not null unique,
  full_name not null,
  last_login_time not null,
  last_updated_datetime not null
) as
  select user_id, email_address, full_name, 
         max ( login_datetime ) last_login_time,
         last_updated_datetime
  from   accounts 
  join   account_logins
  using  ( user_id ) 
  group  by user_id, email_address, full_name, 
         last_updated_datetime;
  
select * from accounts_upd
where  user_id = 1;





create table accounts_tmp (
  user_id not null primary key,
  email_address not null unique,
  full_name not null,
  last_login_time not null,
  last_updated_datetime not null
) as
  select user_id, email_address, full_name, 
         last_login_time, last_updated_datetime
  from   accounts;



/* Session 2 start redef */


/* Session 1 */
insert into accounts_tmp values ( 
  0, 'test@ting.com', 'Tess Ting', 
  systimestamp, sysdate
);

delete accounts_tmp
where  user_id between 1 and 10;

update accounts_tmp
set    full_name = 'New name', 
       last_login_time = systimestamp,
       last_updated_datetime = sysdate
where  user_id between 11 and 100;


select * from accounts_tmp
where  user_id between 0 and 100;
/* Pin results; wait for redef to finish */




select * from accounts_tmp a
where  user_id between 0 and 100;
and    exists (
  select null
  from   account_logins al
  where  login_datetime >= date'2021-05-31'
  and    a.user_id = al.user_id
);