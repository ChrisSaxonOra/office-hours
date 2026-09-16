--set sqlformat ansiconsole
/* setup */
drop table product_prices
  cascade constraints purge;
drop table order_items
  cascade constraints purge;
drop table customers
  cascade constraints purge;
drop table orders
  cascade constraints purge;
drop table invoices
  cascade constraints purge;
drop table addresses
  cascade constraints purge;
  
drop domain currency force;
drop domain insert_timestamp force;
drop domain address force;
drop domain gb_address force;
drop domain us_address force;
drop domain global_address force;
drop domain statuses force;

create table products (
  invoice_id        integer not null primary key,
  price             number(10, 2) not null,
  currency_code     char(3 char ),
  usd_exchange_rate number,
  insert_datetime   timestamp 
);
/* end setup */
cl scr
