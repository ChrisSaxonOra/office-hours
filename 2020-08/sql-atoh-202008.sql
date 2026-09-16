@C:\Users\csaxon\Documents\Scripts\sql-atoh-202008-setup

exec dbms_stats.gather_table_stats ( user, 'bricks' ) ;

select count (*) from bricks
where  colour = 'red';

select count (*) from bricks
where  colour = 'red'
and    shape = 'cylinder';

select count (*) from bricks
where  brick_id between 0 and 1000;

select count (*) from bricks
where  brick_id between 9000 and 10000;



/* **************************************** */
  





/* **************************************** */
  
exec dbms_stats.gather_table_stats ( user, 'bricks' ) ;

select column_name, histogram 
from   user_tab_cols
where  table_name = 'BRICKS';

select colour, count(*) from bricks
group  by colour;

select weight, count(*) from bricks
group  by weight
order  by count(*) desc;


set long 10000
select dbms_stats.report_col_usage ( user , 'bricks' )
from   dual;


select count (*) from bricks
where  colour = 'red';

select count (*) from bricks
where  brick_id between 0 and 1000;

select count (*) from bricks
where  brick_id between 9000 and 10000;




/* New query */
select count (*) from bricks b
where  colour = 'red';

select count (*) from bricks b
where  brick_id between 0 and 1000;

select count (*) from bricks b
where  brick_id between 9000 and 10000;





/* Correlation */
select count (*) from bricks b
where  colour = 'red'
and    shape = 'cylinder';

select count (*) from bricks b
where  colour = 'red'
and    shape = 'star';




begin
  dbms_stats.gather_table_stats ( 
    user, 'bricks', 
    method_opt => 'for all columns size auto, ' || 
      'for columns ( colour, shape ) size auto'
  ) ;
end;
/

select column_name, data_default, histogram 
from   user_tab_cols
where  table_name = 'BRICKS';



select count (*) from bricks b2
where  colour = 'red'
and    shape = 'cylinder';

select count (*) from bricks b2
where  colour = 'red'
and    shape = 'star';





begin
  dbms_stats.gather_table_stats ( 
    user, 'bricks', 
    method_opt => 
      'for all columns size auto, ' || 
      'for columns ( colour, shape ) size auto'
  ) ;
end;
/

select column_name, data_default, histogram 
from   user_tab_cols
where  table_name = 'BRICKS';


select count (*) from bricks b3
where  colour = 'red'
and    shape = 'cylinder';

select count (*) from bricks b3
where  colour = 'red'
and    shape = 'star';





/* What about expressions? */
select count (*) from bricks
where  lower ( colour ) = 'red';




select * 
from   table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));




select count (*) from bricks
where  lower (colour) = 'red';


/* Index doesn't help estimate! */
create index bric_lower_colour_i
  on bricks ( lower ( colour ) );
  
select count (*) from bricks
where  lower ( colour ) = 'red';


begin
  dbms_stats.gather_table_stats ( 
    user, 'bricks', 
    method_opt => 
      'for all columns size auto, ' ||
      'for columns ( colour, shape ) size auto, ' || 
      '( lower ( colour ) ) size auto'
  ) ;
end;
/

select count (*) from bricks b
where  lower ( colour ) = 'red';


select * 
from   table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));

select column_name, data_default, histogram 
from   user_tab_cols
where  table_name = 'BRICKS';




/* Subquery problems */
select count (*) from bricks b
where  colour = (
  select colour from colours
  where  rgb_hex_code = 'FF0000'
);



select count (*) from bricks
join   colours
using  ( colour ) 
where  rgb_hex_code = 'FF0000';



select count (*) from bricks b
where  colour = (
  select colour from colours
  where  rgb_hex_code = '0000FF'
);




declare
  colour_name varchar2(10);
  brick_count integer;
begin

  select colour
  into   colour_name 
  from   colours
  where  rgb_hex_code = '0000FF';
  
  select count (*) 
  into   brick_count 
  from   bricks
  where  colour = colour_name;

end;
/


select p.*  
from v$sql s, table (  
  dbms_xplan.display_cursor (  
    s.sql_id, s.child_number, 'ALLSTATS LAST'  
  )  
) p  
where s.sql_text like 'SELECT COUNT (*)%FROM BRICKS%'  
and   s.sql_text not like '%not this%';





/* Disable histograms */ 
begin
  dbms_stats.gather_table_stats ( 
    user, 'bricks', 
    method_opt => 
      'for columns brick_id size 1'
  ) ;
end;
/

select column_name, data_default, histogram 
from   user_tab_cols
where  table_name = 'BRICKS';



exec dbms_stats.gather_table_stats ( null, 'bricks' ) ;

select column_name, data_default, histogram 
from   user_tab_cols
where  table_name = 'BRICKS';




/* Set table preferences! */
begin 
  dbms_stats.set_table_prefs ( 
    null, 'bricks', 
    'method_opt', 
    'for all columns size auto, ' || 
    'for columns brick_id size 1, ' ||
    '( colour, shape ) size auto, ' || 
    '( lower ( colour ) ) size auto'
  ); 
end;
/

exec dbms_stats.gather_table_stats ( null, 'bricks' ) ;

select column_name, data_default, histogram 
from   user_tab_cols
where  table_name = 'BRICKS';