
insert into invoices 
  values ( 2, 2, systimestamp, 'NEW' );
  
rollback;












select sid, blocking_session, final_blocking_session 
from   v$session
where  status = 'ACTIVE'
and    username = user;


insert into invoices 
  values ( 3, 3, systimestamp, 'NEW' );



/* Monitor locks - no worky? only show 2 sessions? */
select session_id, mode_held, mode_requested, blocking_others 
from   dba_locks
where  lock_type in ( 'Transaction' ) 
and    session_id in ( 
  select sid from v$session
  where  status = 'ACTIVE'
  and    username = user
);