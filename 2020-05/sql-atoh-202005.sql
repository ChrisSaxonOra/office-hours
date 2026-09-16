@C:\Users\csaxon\Documents\Scripts\sql-atoh-202005-setup

create or replace procedure create_order as
  item_number    pls_integer := 1;
  order_id       orders.order_id%type;
  order_datetime orders.order_datetime%type;
begin

  order_datetime := systimestamp;
  
  insert into orders ( 
    order_id, order_datetime, customer_id, order_status, store_id 
  ) values (
    default, order_datetime, 1, 'PAID', 1 
  );
  
  select ord.order_id
  into   create_order.order_id
  from   orders ord
  where  ord.order_datetime = create_order.order_datetime;
  
  for prods in ( 
    select prod.product_id, prod.unit_price
    from   products prod
    where  json_value ( 
      product_details, '$.colour' returning varchar2 error on error
    ) = 'black'
  ) loop
  
    insert into order_items ( 
      order_id, line_item_id, product_id, unit_price, quantity 
    ) values ( 
      create_order.order_id, item_number, prods.product_id, prods.unit_price, 
      mod ( prods.product_id, 5 ) + 1
    );
    
    item_number := item_number + 1;
    
  end loop;
  
  for prods in ( 
    select prod.product_id, prod.unit_price
    from   products prod
    where  json_value ( 
      product_details, '$.colour' returning varchar2 error on error
    ) = 'white'
  ) loop
  
    insert into order_items ( 
      order_id, line_item_id, product_id, unit_price, quantity 
    ) values ( 
      create_order.order_id, item_number, prods.product_id, prods.unit_price, 
      mod ( prods.product_id, 5 ) + 1
    );
    
    item_number := item_number + 1;
    
  end loop;
  
end create_order;
/


exec create_order();


alter session set tracefile_identifier = chris;

begin
  sys.dbms_monitor.session_trace_enable ( 
    waits => true, binds => true 
  );

  create_order();
  
  sys.dbms_monitor.session_trace_disable ();
end;
/




select value,
       substr (
         value, instr ( value, '/', -1 ) + 1
       ) filename
from   v$diag_info
where  name = 'Default Trace File';


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
  

@C:\Users\csaxon\Documents\Scripts\sql-atoh-202005-spool-trace











/* PL/SQL Profiler */
declare
  run# number;
begin
  dbms_hprof.start_profiling (
    location => 'PLSHPROF_DIR',
    filename => 'profile.txt'
  );
   
  create_order ();

  dbms_hprof.stop_profiling;
  run# := dbms_hprof.analyze (
     location    => 'PLSHPROF_DIR',
     filename    => 'profile.txt',
     run_comment => 'test run'
  );
                    
  dbms_output.put_line('Run number: ' || run#);
end;
/



with execution_stats as (
  select fi.runid,
         fi.symbolid,
         pci.parentsymid,
         rtrim(fi.owner || '.' || fi.module || '.' || nullif(fi.function,fi.module), '.') as unit,
         nvl(pci.subtree_elapsed_time, fi.subtree_elapsed_time) as subtree_elapsed_time,
         nvl(pci.function_elapsed_time, fi.function_elapsed_time) as function_elapsed_time,
         fi.line#,
         nvl(pci.calls, fi.calls) as calls,
         namespace,
         sql_id, 
         sql_text
  from   dbmshp_function_info fi
  left join dbmshp_parent_child_info pci 
  on fi.runid = pci.runid 
  and    fi.symbolid = pci.childsymid
  where  fi.runid = :run
  and    fi.module != 'SYS.DBMS_HPROF'
), execution_tree as (
  select runid, 
         rpad(' ', (level-1)*2, ' ') || unit as unit,
         line#,
         subtree_elapsed_time,
         function_elapsed_time,
         calls,
         namespace,
         sql_id, 
         sql_text
  from   execution_stats
  start with parentsymid is null
  connect by parentsymid = prior symbolid
  and runid = prior runid
)
  select * from execution_tree;

@C:\Users\csaxon\Documents\Scripts\sql-atoh-202005-setup








/* So what could we change? */








 
create or replace procedure create_order as
  order_id       orders.order_id%type;
begin

  insert into orders ( 
    order_id, order_datetime, customer_id, order_status, store_id 
  ) values (
    default, systimestamp, 1, 'PAID', 1 
  ) returning order_id into create_order.order_id;
  
  insert into order_items ( 
    order_id, line_item_id, product_id, unit_price, quantity 
  ) 
    select order_id, rownum, prod.product_id, prod.unit_price, mod ( prod.product_id, 5 ) + 1
    from   products prod
    where  json_value ( 
      product_details, '$.colour' returning varchar2(100) error on error
    ) in ( 'black', 'white' );
  
end create_order;
/









create index prod_colour_i 
  on products ( 
    json_value ( 
      product_details, '$.colour'
      returning varchar2(100)
      error on error
    )
  ); 
  
exec dbms_stats.gather_table_stats ( user, 'products', no_invalidate => false, method_opt => 'for all columns size skewonly' ) ;
exec dbms_stats.gather_index_stats ( user, 'prod_colour_i' ) ;
alter system flush shared_pool;

drop index prod_colour_i ;

