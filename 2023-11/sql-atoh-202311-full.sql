@sql-atoh-202311-setup

/*  
create table addresses (
--  address_id   integer generated as identity
--  address_id   raw(16) default sys_guid()
    not null primary key
, address    json
);

-- Ensure addresses are unique
create unique index address_u
  on addresses a ( a.address.address.string() );
/**/


create /*blockchain /**/ table invoices (
--  invoice_id   integer generated as identity
--  invoice_id   raw(16) default sys_guid()
    not null primary key  
, customer_id  integer not null
--, payment_address  json
--, delivery_address json
--, payment_address_id  references addresses
--, delivery_address_id references addresses
--, total_amount 
--    integer not null
--    number(*,2) not null
) /* Blockchain to disable updates *
no drop until 0 days idle
no delete until 16 days after insert
hashing using "SHA2_512" version "v2" /**/
;


/* Trigger to disable updates *
create trigger invo_no_update 
before update on invoices
begin
  raise_application_error ( -20001, q'|You can't update invoices!|' );
end;
/
/**/


create /*blockchain /**/ table invoice_items (
  invoice_id  references invoices not null
, product_id  integer not null
, quantity    integer not null
, unit_price  
--    integer not null
--    number(*,2) not null
, primary key ( invoice_id, product_id )
) /* Blockchain to disable updates *
no drop until 0 days idle
no delete until 16 days after insert
hashing using "SHA2_512" version "v2" /**/;


/* Trigger to disable updates *
create trigger init_no_update 
before update on invoice_items
begin
  raise_application_error ( -20001, q'|You can't update invoices!|' );
end;
/
/**/

/* Data load package */
create or replace package invoice_pkg as 
  
  type items_arr 
    is table of invoice_items%rowtype
    index by pls_integer;

  procedure insert_invoice (
    customer_id      integer
  , payment_address  json
  , delivery_address json
  , items            invoice_pkg.items_arr
  );
end;
/



/* Update flags! */
alter session set PLSQL_CCFlags = 'address_tab:,store_total:';



create or replace package body invoice_pkg as 

  $if $$address_tab $then
  function add_address (
    add_address json
  ) return addresses.address_id%type as
    address_id addresses.address_id%type;
  begin
    insert into addresses values ( default, add_address )
    returning address_id into address_id;
    
    return address_id;
  exception
     when DUP_VAL_ON_INDEX then
        select address_id into address_id
        from   addresses
        where  json_equal ( address, add_address );
        
        return address_id;
  end;
  $end

  procedure insert_invoice (
    customer_id      integer
  , payment_address  json
  , delivery_address json
  , items            invoice_pkg.items_arr
  ) as
    $if $$address_tab $then
    payment_address_id  addresses.address_id%type;
    delivery_address_id addresses.address_id%type;
    $end
    invoice_id          invoices.invoice_id%type;
    local_items         invoice_pkg.items_arr;
    invoice_total       number := 0;
  begin
  
    $if $$store_total $then
    for i in 1 .. items.count loop
      invoice_total := items(i).quantity * items(i).unit_price;
    end loop;
    $end
  
    $if $$address_tab $then
      payment_address_id := add_address ( payment_address );
      
      if not json_equal ( payment_address, delivery_address ) then
        delivery_address_id := add_address ( delivery_address );
      else
        delivery_address_id := payment_address_id;
      end if;
      
      insert into invoices values ( 
        default, customer_id, payment_address_id, delivery_address_id
        $if $$store_total $then , invoice_total $end
      )
      returning invoice_id into invoice_id;
      
    $else
    
      insert into invoices values ( 
        default, customer_id, delivery_address, payment_address 
        $if $$store_total $then , invoice_total $end
      )
      returning invoice_id into invoice_id;
      
    $end
    
    for i in 1 .. items.count loop
      local_items(i) := items(i);
      local_items(i).invoice_id := invoice_id;
    end loop;

    forall i in indices of local_items
      insert into invoice_items values local_items(i);
  end;
end;
/





/* Initial load */
declare
  purchases invoice_pkg.items_arr;
  major_units boolean := true|false;
begin
  for i in 1 .. 5 loop
    purchases(i).product_id := i;
    purchases(i).quantity   := i;
    if major_units then
      purchases(i).unit_price := dbms_random.value ( 1, 10 );
    else
      purchases(i).unit_price := dbms_random.value ( 1, 10 ) * 100;
    end if;
  end loop;
  
  invoice_pkg.insert_invoice ( 
    customer_id      => 1
  , payment_address  => json ( ' { "address" : "payment address" } ' )
  , delivery_address => json ( ' { "address" : "delivery address" } ' )
  , items            => purchases
  );
  
  invoice_pkg.insert_invoice ( 
    customer_id      => 2
  , payment_address  => json ( ' { "address" : "same address" } ' )
  , delivery_address => json ( ' { "address" : "same address" } ' )
  , items            => purchases
  );
  
  invoice_pkg.insert_invoice ( 
    customer_id      => 1
  , payment_address  => json ( ' { "address" : "same address" } ' )
  , delivery_address => json ( ' { "address" : "delivery address" } ' )
  , items            => purchases
  );
  
  commit;
end;
/




select * from invoices i
join   invoice_items 
using  ( invoice_id )
/* Add back if separate address table * 
join   addresses paya
on     i.payment_address_id = paya.address_id
join   addresses dela
on     i.delivery_address_id = dela.address_id
/**/
;






/**************************

        Addresses

**************************/

/* Find invoices with different payment & delivery addresses */
select * from invoices
--where  not json_equal ( payment_address, delivery_address )
--where  payment_address_id <> delivery_address_id
;





/* Find addresses used many times */
with reused_address as (
  select address_id, count ( distinct invoice_id ) invoices
  from   invoices
  unpivot ( 
    address_id for col in 
--    ( payment_address_id, delivery_address_id )
--    ( payment_address, delivery_address )
  )
  group  by address_id
  having count ( distinct invoice_id ) > 1
)
  select * from reused_address
  /* Uncomment if table *
  join   addresses
  using ( address_id )
  /* */
  ;




/* Separate address table - updates affect many invoices *
update addresses a
set    address = json ( ' {"address":"new address"} ' )
where  a.address.address = 'same address';

select invoice_id, paya.address, dela.address
from   invoices i
join   addresses paya
on     i.payment_address_id = paya.address_id
join   addresses dela
on     i.delivery_address_id = dela.address_id;

rollback;
/**/



/**************************

    Preventing updates 

**************************/

/* Can't change the invoice */
update invoices
set    customer_id = 314159
where  invoice_id = 1;


/* Can we remove it? */
delete invoices
where  invoice_id = 1;







/* Compare methods */
create blockchain table invoices_blch (
  invoice_id   integer generated as identity
    not null primary key  
, customer_id  integer not null
, payment_address_id  integer
, delivery_address_id integer
, payment_datetime    timestamp
) 
no drop until 0 days idle
no delete until 16 days after insert
hashing using "SHA2_512" version "v2";


create immutable table invoices_immu (
  invoice_id   integer generated as identity
    not null primary key  
, customer_id  integer not null
, payment_address_id  integer
, delivery_address_id integer
, payment_datetime    timestamp
) 
no drop until 0 days idle
no delete until 16 days after insert
version "v2";


create table invoices_heap (
  invoice_id   integer generated as identity
    not null primary key  
, customer_id  integer not null
, payment_address_id  integer
, delivery_address_id integer
, payment_datetime    timestamp
);

create trigger inhe_no_update 
before update on invoices_heap
begin
  raise_application_error ( -20001, q'|You can't update that!|' );
end;
/






insert all 
  into invoices_heap values ( default, x, x, x, null )
  into invoices_immu values ( default, x, x, x, null )
  into invoices_blch values ( default, x, x, x, null )
select level x from dual
connect by level <= 1000;

commit;




/* Blockchain tables have lots of hidden columns! */
select invoice_id, customer_id, payment_address_id, delivery_address_id, 
       orabctab_inst_id$, orabctab_chain_id$, orabctab_seq_num$, orabctab_creation_time$, 
       orabctab_user_number$, orabctab_hash$, orabctab_signature$, orabctab_signature_alg$, 
       orabctab_signature_cert$, orabctab_spare$
from   invoices_blch;

select invoice_id, customer_id, payment_address_id, delivery_address_id, 
       orabctab_inst_id$, orabctab_chain_id$, orabctab_seq_num$, orabctab_creation_time$, 
       orabctab_user_number$, orabctab_hash$, orabctab_signature$, orabctab_signature_alg$, 
       orabctab_signature_cert$, orabctab_spare$
from   invoices_immu;





/* Compare size */
select segment_name, bytes 
from   user_segments 
where  segment_name like 'INVOICES_%'
order  by bytes;






/* Can't update any rows */
update invoices_blch
set    customer_id = 0
where  invoice_id = 1;

update invoices_heap
set    customer_id = 0
where  invoice_id = 1;






/* ...but there may be some columns you want to change! */
update invoices_blch
set    payment_datetime = systimestamp
where  invoice_id = 1;

update invoices_heap
set    payment_datetime = systimestamp
where  invoice_id = 1;



/* Selective disabling */
create or replace trigger inhe_no_update 
before update of customer_id, payment_address_id, delivery_address_id 
on invoices_heap
begin
  raise_application_error ( -20001, q'|You can't update that!|' );
end;
/

/* Can now update payments on heap table */
update invoices_heap
set    payment_datetime = systimestamp
where  invoice_id = 1;

/* ..and NOT the customer */
update invoices_heap
set    customer_id = 0
where  invoice_id = 1;

select * from invoices_heap
where  invoice_id = 1;

/* ...but the blockchain table is still stuck! */
update invoices_blch
set    payment_datetime = systimestamp
where  invoice_id = 1;




/* Can we remove rows? */
delete invoices_blch
where  invoice_id = 1;

delete invoices_immu
where  invoice_id = 1;

delete invoices_heap
where  invoice_id = 1;










/* Uh-oh! */
select * from invoices_heap where customer_id = 0;

alter trigger inhe_no_update disable;

update invoices_heap
set    customer_id = 0;

alter trigger inhe_no_update enable;

select * from invoices_heap where customer_id = 0;









/* Immutable table for fixed details; heap for others */
create immutable table invoices_fixed (
  invoice_id   integer generated as identity
    not null primary key  
, customer_id  integer not null
, payment_address_id  integer
, delivery_address_id integer
) 
no drop until 0 days idle
no delete until 16 days after insert
version "v2";

create table invoices_editable (
  invoice_id   
    references invoices_fixed
    not null primary key  
, payment_datetime    timestamp
);

/* This is allowed */
update invoices_editable
set    payment_datetime = systimestamp
where  invoice_id = 1;

/* This is prevented */
update invoices_fixed
set    customer_id = 0
where  invoice_id = 1;





/**************************

     GUID vs sequence

**************************/

create table sequence_pk (
  pk integer generated as identity 
    constraint sequence_pk primary key
);
create table guid_pk (
  pk raw(16) default sys_guid() 
    constraint guid_pk primary key
);

-- Performance comparison
set serveroutput on
declare
  iterations pls_integer := 50000;
begin
  for tests in 1 .. 3 loop
    dbms_output.put_line ( ' ***** Run ' || tests || ' ****** ' );
    timing_pkg.set_start_time;
    for i in 1 .. iterations loop
      insert into sequence_pk values ( default );
    end loop;
    timing_pkg.calc_runtime ( 'Sequence', iterations );
    
    timing_pkg.set_start_time;
    for i in 1 .. iterations loop
      insert into guid_pk values ( default );
    end loop;
    timing_pkg.calc_runtime ( 'GUID', iterations );  
  end loop;
end;
/





-- Size comparison
with seq as (
  select sum ( vsize ( pk ) ) seq_size from sequence_pk
), guid as (
  select sum ( vsize ( pk ) ) guid_size from guid_pk
)
  select seq_size, guid_size, 
         round ( guid_size / seq_size, 2 ) ratio
  from   seq cross join guid;
 
/* Allocated space */ 
select segment_name, sum ( bytes ) / 1024 k 
from   user_segments
where  segment_name in ( 'GUID_PK', 'SEQUENCE_PK' )
group  by segment_name;





/* Number that's the same size as a GUID */
select 
  vsize ( 999999999999999999999999999999 ), -- 999 Octillion!
  vsize ( 123456789012345678901234567890 ), 
  vsize ( sys_guid() );








/**************************

      Currency units

**************************/

/* But what are the units?! */
select invoice_id, product_id, 
       quantity, unit_price,
       quantity * unit_price as total
from   invoice_items;








create table currencies (
  currency_code varchar2(3 char) primary key
, minor_units   integer
--, -- etc.
);


insert into currencies 
values ( 'GBP', 2 ), ( 'USD', 2 ), ( 'EUR', 2 ),
       ( 'JPY', 0 ), ( 'ISK', 0 ), -- no minor unit!
       ( 'TND', 3 ), ( 'KWD', 3 ), ( 'BHD', 3 ); -- three decimals!

commit;



create or replace function display_price (
  amount                number, 
  display_currency_code varchar2,
  amount_units          integer
) return number as
  display_price number;
begin
  
  select case
    when amount_units = minor_units then amount
    else ( amount / power ( 10, ( minor_units - amount_units ) ) )
  end 
  into   display_price
  from   currencies
  where  currency_code = display_currency_code;
  
  return display_price;
end;
/


/* Convert to display price */
select invoice_id, product_id, 
       display_price ( quantity * unit_price, 'GBP', :units )
from   invoice_items;









/* Annotate the column to help document it! */
alter table invoice_items 
  modify ( unit_price 
    annotations ( add or replace store_in_minor_unit true|false )
  );
  
select * from user_annotations_usage
where  column_name = 'UNIT_PRICE';

/**************************

      Invoice totals

**************************/

/* Cust totals when storing on header */
select customer_id, sum ( total_amount ) cust_total
from   invoices
group  by customer_id;




/* Calculate customer totals */
select customer_id, sum ( unit_price * quantity ) total
from   invoice_items
join   invoices
using  ( invoice_id )
group  by customer_id;






/* There was a bug in the total calculation! */
begin
  for i in 1 .. items.count loop
    -- need to increment each time! 
    invoice_total := items(i).quantity * items(i).unit_price;
  end loop;
end;
/





create materialized view log 
  on invoice_items 
  with rowid, primary key ( unit_price, quantity )
  including new values;
  
create materialized view invoice_totals 
refresh fast on commit
enable query rewrite
as 
  select invoice_id, sum ( unit_price * quantity ) total
  from   invoice_items
  group  by invoice_id;
  
  
/* Get the plan */
select customer_id, sum ( unit_price * quantity ) total
from   invoice_items
join   invoices
using  ( invoice_id )
group  by customer_id;
  
  
/**************************

           FIN

**************************/
  