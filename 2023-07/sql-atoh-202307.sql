@sql-atoh-202307-setup
  
create table invoices (
  invoice_id       integer not null
    constraint invoice_pk primary key,
  customer_id      integer not null,
  invoice_datetime timestamp not null,
  status           varchar2(10) not null,
  constraint inv_status_c check (
    status in ( 'NEW', 'PAID', 'CANCELLED', 'REFUNDED' )
  )
);



create table invoice_items (
  invoice_id 
    constraint init_invoice_fk references invoices
    not null, 
  item_number     integer not null,
  product_id      integer not null,
  order_id        integer not null,
  quantity        integer not null,
  unit_price      number not null,
  constraint invoice_items_pk primary key ( invoice_id, item_number ),
  constraint inv_order_product_u unique ( order_id, product_id ),
  constraint init_qty_gt_zero_c check ( quantity > 0 )
);


insert into invoices 
  values ( 1, 1, timestamp'2023-01-01 00:00:00', 'NEW' );
commit;



/* Drop and recreate constraint - blocking DDL */
alter table invoices 
  drop constraint inv_status_c;

alter table invoices 
  add constraint inv_status_c
  check (
    status in ( 'NEW', 'PAID', 'CANCELLED', 'REFUNDED', 'VOID' )
  );  
  
  
  
  
  
  
/* Add the new constraint */
alter table invoices 
  add constraint inv_status_c_new
  check (
    status in ( 'NEW', 'PAID', 'CANCELLED', 'REFUNDED', 'VOID' )
  )
  novalidate;  
  
select constraint_name, validated, search_condition
from   user_constraints
where  table_name = 'INVOICES'
and    constraint_type = 'C';


  
alter table invoices 
  modify constraint inv_status_c_new
  validate; 
  
select constraint_name, validated, search_condition
from   user_constraints
where  table_name = 'INVOICES'
and    constraint_type = 'C';
  
/* Remove the old constraint */
alter table invoices 
  drop constraint inv_status_c
  online;
  
  
  
  
  
  
  
  
  
  
/* Optional: rename new constraint - Blocking! */
alter table invoices 
  rename constraint inv_status_c_new
  to inv_status_c;  









/* Set timeout to allow rename? */
alter session set ddl_lock_timeout = 30;


alter table invoices 
  rename constraint inv_status_c_new
  to inv_status_c;  

/* Run another insert in third session */



/* Reset timeout back to zero */
alter session set ddl_lock_timeout = 0;



/*******************************




*******************************/

/* Find check constraint names */
select constraint_name, column_name
from   user_constraints
join   user_cons_columns
using  ( table_name, constraint_name )
where  table_name = 'INVOICES'
and    search_condition_vc like '%NOT NULL%';



/* Removing and adding not null constraint on STATUS */
declare 
  stmt            clob; 
  constraint_name varchar2(ora_max_name_len); 
begin 
  select constraint_name 
  into   constraint_name  
  from   user_constraints 
  join   user_cons_columns 
  using  ( table_name, constraint_name ) 
  where  table_name = 'INVOICES' 
  and    search_condition_vc like '%NOT NULL%' 
  and    column_name = 'STATUS'; 
 
  stmt := 'alter table invoices 
    drop constraint ' || constraint_name || ' 
    online'; 
  execute immediate stmt; 
end; 
/

/* STATUS now nullable */
select column_name, nullable 
from   user_tab_cols
where  table_name = 'INVOICES';




/* Add (named) NN constraint */
alter table invoices
  modify status
  constraint inv_status_nn
  not null
  novalidate;
  
alter table invoices
  modify constraint inv_status_nn 
  validate;

  
  
  

/* Add columns to unique constraint 
   invoice_items -> unique ( order_id, product_id )
   
   !! Can issue many invoices against order & product !!
*/
create unique index inv_order_product_inv_ui
  on invoice_items ( order_id, product_id, invoice_id )
  online;

/* Create constraint using new index */  
alter table invoice_items 
  add constraint inv_order_product_inv_u
  unique ( order_id, product_id, invoice_id ) 
  using index inv_order_product_inv_ui
  novalidate;

/* Unique index => no duplicates => instant! */
alter table invoice_items 
  modify constraint inv_order_product_u
  validate;  




  
/* Remove the old unique constraint */
alter table invoice_items
  drop constraint inv_order_product_u
  online;
  
 

/*******************************




*******************************/ 

/* Drop PK with FK references? */
alter table invoices 
  drop primary key;
  
select * from user_constraints
where  r_constraint_name = 'INVOICE_PK';
  
  
  
  
  
  
  
  
/* Drop PK & FKs preserving index */
alter table invoices 
  drop primary key
  cascade
  keep index;
    
select index_name, uniqueness 
from   user_indexes
where  table_name = 'INVOICES';






alter table invoices
  add unique ( invoice_id )
  using index invoice_pk
  novalidate;
 
  
/* Add foreign key constraint back: ON DELETE CASCADE */
alter table invoice_items 
  add constraint inv_cust_date_fk 
  foreign key ( invoice_id )
  references invoices ( invoice_id )
  on delete cascade;
  
  
  
  
  

/* Can't have duplicate constraints; even though properties different */
alter table invoice_items 
  add constraint inv_cust_date_fk_tmp
  foreign key ( invoice_id )
  references invoices ( invoice_id )
  deferrable;








/* ...except CHECKs! */
alter table invoice_items 
  add constraint init_qty_gt_zero_c_copy
  check ( quantity > 0 ) ;

select constraint_name, search_condition_vc 
from   user_constraints
where  table_name = 'INVOICE_ITEMS';









/* Use DBMS_redef - create a copy table  */
create table invoice_items_tmp (
  invoice_id 
    constraint init_invoice_fk_tmp references invoices ( invoice_id )
    deferrable
    not null, 
  item_number     integer not null,
  product_id      integer not null,
  order_id        integer not null,
  quantity        integer not null,
  unit_price      number not null,
  constraint invoice_items_pk_tmp primary key ( invoice_id, item_number ),
  constraint inv_order_product_u_tmp unique ( order_id, product_id ),
  constraint init_qty_gt_zero_c_tmp check ( quantity > 0 )
);

select table_name, constraint_name, constraint_type, delete_rule, deferrable
from   user_constraints
where  table_name like 'INVOICE_ITEMS%'
and    constraint_type = 'R'
order  by constraint_name;





declare
  l_num_errors pls_integer;
begin
  dbms_redefinition.can_redef_table(user, 'invoice_items');
  dbms_redefinition.start_redef_table(user, 'invoice_items', 'invoice_items_tmp'); 
  
  dbms_redefinition.copy_table_dependents (
    uname             => user,
    orig_table        => 'invoice_items',
    int_table         => 'invoice_items_tmp',
    copy_indexes      => 0,
    copy_constraints  => false,
    ignore_errors     => true,
    num_errors        => l_num_errors
  ); 
    
  if l_num_errors > 0 then
    
    dbms_redefinition.abort_redef_table(user, 'invoice_items', 'invoice_items_tmp');
    raise_application_error ( -20001, 'Redef problem' );
    
  else
  
    dbms_redefinition.sync_interim_table(user, 'invoice_items', 'invoice_items_tmp'); 
    dbms_redefinition.finish_redef_table(user, 'invoice_items', 'invoice_items_tmp');
  
  end if;

end;
/

/* Swapped the constraints over! */
select table_name, constraint_name, constraint_type, delete_rule, deferrable
from   user_constraints
where  table_name like 'INVOICE_ITEMS%'
and    constraint_type = 'R'
order  by constraint_name;


/*******************************




*******************************/ 