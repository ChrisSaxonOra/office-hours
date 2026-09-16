@sql-atoh-202405-setup


/* Create tables with the annotations */
create table customers (
  customer_id     integer not null primary key,
  customer_name   varchar2(100) not null,
  email           varchar2(320) not null,
  insert_datetime timestamp default systimestamp not null
    annotations (     
      system_generated, 
      allowed_reads '["filter", "sort"]' , 
      disallowed_writes '["insert", "update"]'  
    )
) annotations ( display_as 'Customer details', module 'accounts' );







create table orders (
  order_id        integer not null primary key,
  customer_id     references customers not null,
  email_address   varchar2(320) not null,
  insert_datetime timestamp default systimestamp not null
    annotations (     
      system_generated, 
      allowed_reads '["filter", "sort"]' , 
      disallowed_writes '["insert", "update"]'  
    )
) annotations ( display_as 'Order details', module 'orders' );







create table invoices (
  invoice_id      integer not null primary key,
  order_id        references orders not null,
  insert_datetime timestamp default systimestamp not null
    annotations (     
      system_generated, 
      allowed_read '["filter", "sort"]' , 
      disallowed_writes '["insert"]'  
    )
) annotations ( display_as 'Invoice details', module 'payment' );





/* Annotating indexes */
create index cust_ts_i on customers ( insert_datetime )
  annotations ( purpose 'To find new customers' );
create index orde_cust_ts_i on orders ( customer_id, insert_datetime )
  annotations ( purpose q'|To get a customer's recent orders|' );
create index invo_order_ts_i on invoices ( order_id, insert_datetime )
  annotations ( purpose q'|To get an order's recent invoices|' );
  





/* View annotations */
select object_type, object_name, column_name, annotation_name, annotation_value
from   user_annotations_usage
where  object_name in ( 'CUSTOMERS', 'ORDERS', 'INVOICES' )
or     object_name like '%TS_I'
order  by annotation_name, object_name; 







/* Change annotations */
alter table invoices modify (
  insert_datetime 
    annotations (     
      drop allowed_read, -- remove
      add allowed_reads '["filter", "sort"]', -- insert
      add or replace disallowed_writes '["insert", "update"]' -- change 
    )
);




/* View changes */
select object_type, object_name, column_name, annotation_name, annotation_value
from   user_annotations_usage
where  object_name in ( 'INVOICES' )
order  by annotation_name, object_name; 








/*****************************

      Use case domains

*****************************/
@sql-atoh-202405-setup

/* Create insert timestamp domain */
create usecase domain insert_timestamp as
  timestamp 
  default systimestamp
  not null
  annotations (     
    system_generated, 
    allowed_reads '["filter", "sort"]' , 
    disallowed_writes '["insert", "update"]'  
  );

select * from user_domains
where  name = 'INSERT_TIMESTAMP';








/* Create tables with the domains */
create table customers (
  customer_id     integer not null primary key,
  customer_name   varchar2(100) not null,
  email           varchar2(320) not null,
  insert_datetime insert_timestamp
) annotations ( display_as 'Customer details', module 'accounts' );




create table orders (
  order_id        integer not null primary key,
  customer_id     references customers not null,
  email_address   varchar2(320) not null,
  insert_datetime domain insert_timestamp,
  order_status    integer not null
) annotations ( display_as 'Order details', module 'orders' );





create table invoices (
  invoice_id      integer not null primary key,
  order_id        references orders not null,
  insert_datetime timestamp domain insert_timestamp,
  invoice_status  integer not null
) annotations ( display_as 'Invoice details', module 'payment' );





/* Default value & NOT NULL applied to the columns */
select table_name, column_name, data_type, data_default, nullable
from   user_tab_cols
where  domain_name = 'INSERT_TIMESTAMP';
 
 
/* View annotations */
select object_name, annotation_name, annotation_value, domain_name
from   user_annotations_usage
where  domain_name = 'INSERT_TIMESTAMP'
order  by annotation_name, object_name; 







/* View built-in domains */
select d.name, search_condition
from   all_domains d
left   join all_domain_constraints dc
on     d.owner = dc.domain_owner
and    d.name = dc.domain_name
where  owner = 'SYS';






/* Associate EMAIL_D with columns */
alter table orders
  modify ( 
    email_address domain sys.email_d 
  );
  
alter table customers
  modify ( email )
  add domain sys.email_d;



/* View email domain columns */
select table_name, column_name
from   user_tab_cols
where  domain_name = 'EMAIL_D';




/* Inherited constraint from domain */
insert into customers ( customer_id, customer_name, email )
values ( 1, 'Tess Ting', 'tess@ting.com' );

/* Invalid values rejected */
insert into customers ( customer_id, customer_name, email )
values ( 2, 'Invalid Email', 'invalid.email' );

select * from customers;




/*****************************

        enum domains

*****************************/
create domain statuses as enum ( 
  opened, closed, cancelled, refunded
);


/* View the ENUM names and values */
select * from statuses;



drop domain statuses;
create domain statuses as enum ( 
  opened    = 'OPEN',   closed   = 'CLOSE', 
  cancelled = 'CANCEL', refunded = 'REFUND'
);

select * from statuses;




drop domain statuses;
create domain statuses as enum ( 
  opened, closed, cancelled, refunded, shipped
) default 1;





alter table orders
  modify ( order_status )
  add domain statuses;

alter table invoices
  modify ( invoice_status )
  add domain statuses ;

drop domain statuses force preserve;

alter table invoices
  modify ( invoice_status )
  drop domain ;



/* Constraint from enum */
select constraint_name, table_name, search_condition 
from   user_constraints 
where  table_name in ( 'ORDERS', 'INVOICES' )
and    constraint_type = 'C'
and    search_condition_vc like '%STATUS%';





/* These all insert the same value for ORDER_STATUS */
insert into orders values
  ( 1, 1, 'test@test.com', default, 1 ),
  ( 2, 1, 'test@test.com', default, statuses.opened ),
  ( 3, 1, 'test@test.com', default, default );

commit;

/* View the status value and name */
select order_status, domain_display ( order_status ) status_name
from   orders;





insert into orders values
  ( 4, 1, 'test@test.com', default, statuses.closed ),
  ( 5, 1, 'test@test.com', default, statuses.cancelled ),
  ( 6, 1, 'test@test.com', default, statuses.refunded );

update orders 
set    order_status = statuses.closed
where  order_status = statuses.opened;



select order_status, domain_display ( order_status ) status_name,
  case order_status 
    when statuses.opened then 'Pending'
    else 'Complete'
  end outstanding
from   orders;

rollback;








/*****************************

      Multicol domains

*****************************/


/* Multi-column domains - show me the money! */
create domain currency as (
  amount            as number(10,2),
  iso_currency_code as char(3 char) strict,
  exchange_rate     as number
);





create table product_prices (
  product_id        integer,
  currency_code     char (4 char), -- length mismatch! This will error
  price             integer,        
  usd_exchange_rate number(*,6),   
  domain currency ( price, currency_code, usd_exchange_rate )
);



create table product_prices (
  product_id        integer,
  currency_code     char (12 byte), -- monetary value 4:1 bytes:char
  price             integer,        -- monetary value
  usd_exchange_rate number(*,6),    -- monetary value
  domain currency ( price, currency_code, usd_exchange_rate )
);




create table order_items (
  order_id          integer, 
  product_id        integer,
  total_paid        number,        -- monetary value
  currency_code     char (3 char), -- monetary value
  usd_exchange_rate number         -- monetary value
);
  
alter table order_items 
  modify ( total_paid, currency_code, usd_exchange_rate )
  add domain currency;
  
  
  

/* Find the monetary values */
select table_name, column_name
from   user_tab_cols
where  domain_name = 'CURRENCY'
order  by table_name;



insert into order_items
values (1, 1,    9.99, 'USD', 1 ),
       (2, 2,    8.99, 'GBP', 1.27 ),
       (3, 3,    8.99, 'EUR', 1.09 ),
       (4, 4, 1399,    'JPY', 0.00697 ),
       (5, 5,  825.00, 'INR', 0.01207 );
       
commit;



       
/* Sort by value misleading => want to convert to standard currency */           
select order_id, product_id, 
       total_paid, currency_code, usd_exchange_rate
from   order_items
order  by total_paid;



          
/* Sort in normalized currency */
alter domain currency 
  add order amount * exchange_rate;

/* Display in normalized currency with  */
alter domain currency 
  add display '(' || iso_currency_code || ')' || 
      to_char ( round ( amount * exchange_rate, 2 ), '999G999G990D00' );

  


       
       
       
/* Display and sort the values in standard currency (USD) using domain expressions */
select order_id, product_id, total_paid,
       domain_display ( total_paid, currency_code, usd_exchange_rate ) usd_amount
from   order_items
order  by domain_order ( total_paid, currency_code, usd_exchange_rate );







/*****************************

      Flexible domains

*****************************/

/* Address flex domains - create country sub domains first */
create domain us_address as (
  line_1  as varchar2(255 char) not null,
  town    as varchar2(255 char) not null,
  state   as varchar2(255 char) not null,
  zipcode as varchar2(10 char) not null
) constraint us_address_c check ( 
  regexp_like ( zipcode, '^[0-9]{5}(-[0-9]{4}){0,1}$' ) 
);


/* British addresses */
create domain gb_address as ( 
  street   as varchar2(255 char) not null,
  locality as varchar2(255 char),
  town     as varchar2(255 char) not null,
  postcode as varchar2(10 char) not null
) constraint gb_postcode_c check (
  regexp_like ( 
    postcode, '^[A-Z]{1,2}[0-9]{1,2}[A-Z]{0,1} [0-9]{1,2}[A-Z]{2}$' 
  )
);
  
  
/* Default address */
create domain global_address as ( 
  line_1   as varchar2(255 char) not null,
  line_2   as varchar2(255 char),
  line_3   as varchar2(255 char),
  line_4   as varchar2(255 char),
  postcode as varchar2(10 char)
); 
  
  
  
/* Flexible supertype domain */
create flexible domain address (
  line_1, line_2, line_3, line_4, postal_code      
)
choose domain using ( country_code varchar2(2 char) )
from (
  case country_code
    when 'GB' then gb_address ( line_1, line_2, line_3, postal_code )
    when 'US' then us_address ( line_1, line_2, line_3, postal_code )
    else global_address ( line_1, line_2, line_3, line_4, postal_code )
  end
);


create table addresses (
  line_1         varchar2(255) not null,
  line_2         varchar2(255),
  line_3         varchar2(255),
  line_4         varchar2(255),
  country_code   varchar2(2 char) not null,
  postal_code    varchar2(10 char), 
  domain address ( 
    line_1, line_2, line_3, line_4, postal_code 
  ) using ( country_code )
);






/* Valid addresses */
begin 
  -- Great Britian
  insert into addresses ( line_1, line_3, country_code, postal_code ) 
  values ( '10 Big street', 'London', 'GB', 'N1 2LA' );
  -- United States
  insert into addresses ( line_1, line_2, line_3, country_code, postal_code ) 
  values ( '10 another road', 'Las Vegas', 'NV', 'US', '87654-3210' );  
  -- Tuvalu
  insert into addresses ( line_1, country_code ) 
  values ( '10 Main street', 'TV' );  
end;
/

select * from addresses;




-- UK address with US zip code
insert into addresses ( line_1, line_3, country_code, postal_code ) 
values ( '10 Big street', 'London', 'GB', '12345-6789' );

-- US address without state 
insert into addresses ( line_1, line_2, country_code, postal_code ) 
values ( '10 another road', 'Las Vegas', 'US', '87654-3210' );  

select * from addresses a;
