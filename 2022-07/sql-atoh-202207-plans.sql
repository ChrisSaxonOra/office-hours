alter session set statistics_level = all;
set serveroutput off;

exec merge_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => '7xzwk0jacgfbw', format => 'ALLSTATS LAST') );

exec remove_half();
exec merge_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => '7xzwk0jacgfbw', format => 'ALLSTATS LAST') );

exec merge_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => '7xzwk0jacgfbw', format => 'ALLSTATS LAST') );
rollback;

exec upsert_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'arj74mjgq7k27', format => 'ALLSTATS LAST') );
select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'ag8jd9yyh6jnz', format => 'ALLSTATS LAST') );

exec remove_half();
exec upsert_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'arj74mjgq7k27', format => 'ALLSTATS LAST') );
select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'ag8jd9yyh6jnz', format => 'ALLSTATS LAST') );


exec upsert_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'arj74mjgq7k27', format => 'ALLSTATS LAST') );
select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'ag8jd9yyh6jnz', format => 'ALLSTATS LAST') );

rollback;


exec indate_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'arj74mjgq7k27', format => 'ALLSTATS LAST') );
select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'ag8jd9yyh6jnz', format => 'ALLSTATS LAST') );

exec remove_half();
exec indate_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'arj74mjgq7k27', format => 'ALLSTATS LAST') );
select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'ag8jd9yyh6jnz', format => 'ALLSTATS LAST') );

exec indate_data();

select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'arj74mjgq7k27', format => 'ALLSTATS LAST') );
select * 
from   table ( dbms_xplan.display_cursor( sql_id => 'ag8jd9yyh6jnz', format => 'ALLSTATS LAST') );

rollback;
