alter session set ddl_lock_timeout = 0;
drop table invoice_items_tmp
  cascade constraints purge;
drop table invoice_items
  cascade constraints purge;
drop table invoices
  cascade constraints purge;
cl scr
