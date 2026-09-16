-- Invoices PK - sequence or GUID?
-- No editing - trigger vs blockchain table => immutable!
-- data type for prices? major & minor or just minor?
-- Addresses? Join table vs store on invoice directly?
-- Invoice totals? Store vs calculate?

drop table currencies
  cascade constraints purge;
drop table invoices_fixed
  cascade constraints purge;
drop table invoices_editable 
  cascade constraints purge;
drop function display_price;

drop materialized view invoice_totals ;
drop table invoices_blch
  cascade constraints purge;
drop table invoices_immu
  cascade constraints purge;
drop table invoices_heap
  cascade constraints purge;

drop table sequence_pk
  cascade constraints purge;
drop table guid_pk
  cascade constraints purge;
drop table invoice_items
  cascade constraints purge;
drop table invoices
  cascade constraints purge;
drop table addresses
  cascade constraints purge;
drop table order_items
  cascade constraints purge;

drop domain currency force;
cl scr

