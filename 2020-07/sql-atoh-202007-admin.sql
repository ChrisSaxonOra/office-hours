/* 
 - Restart ATP
 - Rerun queries; ensure unique - not in SQL tuning set already!
*/

EXEC DBMS_AUTO_INDEX.CONFIGURE('AUTO_INDEX_MODE','IMPLEMENT');
--EXEC DBMS_AUTO_INDEX.CONFIGURE('AUTO_INDEX_MODE','OFF');


grant SELECT_CATALOG_ROLE, SELECT ANY DICTIONARY, dwrole, pdb_dba to chris
  identified by "SIRCHsirch99";

alter user chris default tablespace data
              quota unlimited on data;
              
select sysdate, e.* 
from   dba_auto_index_executions e
order  by execution_end desc;


select * from dba_auto_index_statistics
order  by 1 desc;

select execution_name, statement 
from dba_auto_index_ind_actions
--where  table_name = 'ORDERS'
order  by 1 desc;

select * from dba_auto_index_verifications;

select * from dba_auto_index_verifications v
left join v$sql s
using ( sql_id )
order  by execution_name desc;

select sysdate, c.* from dba_auto_index_config c;


select * from v$sql
where  sql_text like '%perf%';


select * from dba_sqlset_statements
where  1=1
and    parsing_schema_name = 'CHRIS'
and    sql_text like '%perf%';

select * from dba_sql_plan_baselines
where  parsing_schema_name = 'CHRIS';

exec dbms_sqltune.delete_sqlset ( 'SYS_AUTO_STS', 'parsing_schema_name = ''CHRIS''', 'SYS' );
exec dbms_sqltune.delete_sqlset ( 'SYS_AUTO_STS', null, 'SYS' );
exec dbms_sqltune.delete_sqlset ( 'SYS_AUTO_STS', '1=1', 'SYS' );
