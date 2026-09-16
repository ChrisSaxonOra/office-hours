



-- 2nd session 
select * from accounts
where  user_id = 1;


update accounts
set    full_name = 'Chris Saxon'
where  user_id = 1;
/* Back to session 1 */



select * from accounts
where  user_id = 1;

commit;
/* Back to session 1 */



/*************************************




*************************************/


select email_address, full_name
from   accounts
where  user_id = 1;
/* Back to session 1 */




update accounts
set    email_address = 'chris.saxon@oracle.com', -- same email
       full_name     = 'CHRIS SAXON' -- change name format
where  user_id = 1;

commit;

select * from accounts
where  user_id = 1;
/* Back to Session 1 */




select * from accounts
where  user_id = 1
for update nowait;
/* Back to session 1 */



select * from accounts
where  user_id = 1;
/* Back to session 1 */


declare
  new_hash accounts.row_hash%type;
  new_time accounts.last_updated_datetime%type;
begin 
  update accounts
  set    email_address = 'saxon.chris@oracle.com', -- change email address
         full_name     = 'Chris Saxon'
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
/* Back to session 1 */




/*************************************




*************************************/

set timing on
declare
   update_stmt clob := q'!
update accounts_tmp a
set    last_updated_datetime = sysdate, 
       last_login_time = (
  select max ( login_datetime ) max_login
  from   account_logins al
  where  a.user_id = al.user_id
)
where  exists (
  select null
  from   account_logins al
  where  login_datetime >= date'2021-05-31'
  and    a.user_id = al.user_id
)!';
begin
   dbms_redefinition.execute_update ( update_stmt );
exception
  when others then
    dbms_output.put_line ('reason for failure is'|| sqlerrm);
    dbms_redefinition.abort_update ( update_stmt );
    raise;    
end;
/