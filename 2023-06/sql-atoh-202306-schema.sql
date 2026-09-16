

/* Remove users to reset 
   Doesn't exist? => no error! */
drop user if exists league_owner
  cascade;
drop user if exists reporting_user
  cascade;
drop user if exists admin_user
  cascade;
  
  
  
  
  
  
  
  
  
/* LEAGUE_OWNER can't login (18c) */  
create user if not exists league_owner
  no authentication;
   
   
   
   
   
  
/* Create low priv user to run script */
grant create session
  to admin_user
  identified by admin_user; 
  
/* Allow low priv user to proxy through the league owner (9i?) */
alter user league_owner 
  grant connect through admin_user;
  
/* New developer role grants league_owner system privileges needed */
grant db_developer_role to league_owner;
alter user league_owner quota unlimited on users;





/* Make reporting user with only create session privs */
grant create session
  to reporting_user
  identified by reporting_user;
  
  
  
  
  