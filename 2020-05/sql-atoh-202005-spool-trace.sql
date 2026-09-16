cl scr

set sqlformat
set serveroutput off
set pagesize 0
set echo off 
set feedback off 
set trimspool on 
set heading off
set tab off
set long 100000
spool c:\temp\order_trace.trc
select payload 
from   v$diag_trace_file_contents
where  trace_filename = (
    select substr (
           value,
           instr ( value, '/', -1 ) + 1
         ) filename
  from   v$diag_info
  where  name = 'Default Trace File'
)
order  by line_number;
spool off




/*
var loc varchar2(30);
begin
  select substr (
           value,
           instr ( value, '/', -1 ) + 1
         ) filename
  into   :loc
  from   v$diag_info
  where  name = 'Default Trace File';
end;
/

print :loc


select * from chris.tracefiles
  external modify ( 
    location ( :loc )
  );*/
  
set serveroutput on
set feedback on
set echo on