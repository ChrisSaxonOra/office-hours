/* Reconnect! */
@sql-atoh-201902-setup


/* Basic query */
select trunc(i.paid_date) , 
       round(sum((il.quantity * il.unit_price)/ex_rate), 2) value
--
from   invoices i
join   invoice_lines il
on     i.invoice_id = il.invoice_id
join   states s
on     i.state_code = s.abbreviation 
join   countries c
on     s.country = c.iso_code_2
join   exchange_rates ex
on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
--
where  i.paid_date >= date'2018-09-01'
and    i.paid_date < date'2018-09-02'
group  by trunc ( i.paid_date ) ;







/* Using DB links */
select trunc(i.paid_date) , 
       round(sum((il.quantity * il.unit_price)/ex_rate), 2) value
--
from   invoices@loopback i
join   invoice_lines@loopback il
on     i.invoice_id = il.invoice_id
join   states s
on     i.state_code = s.abbreviation 
join   countries c
on     s.country = c.iso_code_2
join   exchange_rates@loopback ex
on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
--
where  i.paid_date >= date'2018-09-01'
and    i.paid_date < date'2018-09-02'
group  by trunc(i.paid_date) ;
  

/* Get SQL id */
select sql_id, sql_text from v$sql
where  sql_text = 
  'SELECT "INVOICE_ID","QUANTITY","UNIT_PRICE" FROM "INVOICE_LINES" "IL" WHERE :1="INVOICE_ID"';


/* No stats :( */
select * 
from   table(
  dbms_xplan.display_cursor (
    'g117sm7hzdg1m', null, 'IOSTATS LAST'
  )
);



select /*+ gather_plan_statistics */
       trunc(i.paid_date) , 
       round(sum((il.quantity * il.unit_price)/ex_rate), 2) value
--
from   invoices@loopback i
join   invoice_lines@loopback il
on     i.invoice_id = il.invoice_id
join   states s
on     i.state_code = s.abbreviation 
join   countries c
on     s.country = c.iso_code_2
join   exchange_rates@loopback ex
on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
--
where  i.paid_date >= date'2018-09-01'
and    i.paid_date < date'2018-09-02'
group  by trunc(i.paid_date) ;




/* Still no stats... */
select * 
from   table (
  dbms_xplan.display_cursor (
    'g117sm7hzdg1m', null, 'IOSTATS LAST'
  )
);






create or replace procedure set_stats_level as
begin
  execute immediate
    'alter session set statistics_level = all';
end;
/

/* Enable stats at remote DB */
exec set_stats_level@loopback;





select trunc(i.paid_date) , 
       round(sum((il.quantity * il.unit_price)/ex_rate), 2) value
--
from   invoices@loopback i
join   invoice_lines@loopback il
on     i.invoice_id = il.invoice_id
join   states s
on     i.state_code = s.abbreviation 
join   countries c
on     s.country = c.iso_code_2
join   exchange_rates@loopback ex
on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
--
where  i.paid_date >= date'2018-09-01'
and    i.paid_date < date'2018-09-02'
group  by trunc(i.paid_date) ;


/* Finally! */ 
select * 
from   table (
  dbms_xplan.display_cursor (
    'g117sm7hzdg1m', 1, 'IOSTATS LAST'
  )
);

select * 
from   table (
  dbms_xplan.display_cursor (
    'g117sm7hzdg1m', 1, 'IOSTATS ALL'
  )
);



/* Where's the plan? */
select /*+ driving_site ( i ) */
       trunc(i.paid_date) , 
       round(sum((il.quantity * il.unit_price)/ex_rate), 2) value
--
from   invoices@loopback i
join   invoice_lines@loopback il
on     i.invoice_id = il.invoice_id
join   states s
on     i.state_code = s.abbreviation 
join   countries c
on     s.country = c.iso_code_2
join   exchange_rates@loopback ex
on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
--
where  i.paid_date >= date'2018-09-01'
and    i.paid_date < date'2018-09-02'
group  by trunc(i.paid_date) ;

/* No plan?! */
select * 
from   table(
  dbms_xplan.display_cursor (
    null, null, 'ALLSTATS LAST +REMOTE'
  )
);




/* Need to find remote SQL id*/
select * 
from   table(
  dbms_xplan.display_cursor (
    '49w6t4m1zajgk', null, 'ALLSTATS LAST'
  )
);







/* Subquery factoring - not enough itself */
with remote_invs as (
  select trunc(i.paid_date) paid,
         i.state_code,
         (il.quantity * il.unit_price) value
  from   invoices@loopback i
  join   invoice_lines@loopback il
  on     i.invoice_id = il.invoice_id
  where  i.paid_date >= date'2018-09-01'
  and    i.paid_date < date'2018-09-02'
)
  select paid , 
         round(sum((i.value)/ex_rate), 2) value
  from   remote_invs i
  join   states s
  on     i.state_code = s.abbreviation 
  join   countries c
  on     s.country = c.iso_code_2
  join   exchange_rates@loopback ex
  on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
  group  by i.paid ;
  
select * 
from   table (
  dbms_xplan.display_cursor (
    null, null, 'BASIC LAST +REMOTE'
  )
);


/* Need to add no_merge hint */
with remote_invs as (
  select /*+ no_merge */trunc(i.paid_date) paid,
         i.state_code,
         (il.quantity * il.unit_price) value
  from   invoices@loopback i
  join   invoice_lines@loopback il
  on     i.invoice_id = il.invoice_id
  where  i.paid_date >= date'2018-09-01'
  and    i.paid_date < date'2018-09-02'
)
  select paid , 
         round(sum((i.value)/ex_rate), 2) value
  from   remote_invs i
  join   states s
  on     i.state_code = s.abbreviation 
  join   countries c
  on     s.country = c.iso_code_2
  join   exchange_rates@loopback ex
  on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
  group  by i.paid ;
  
select * 
from   table (
  dbms_xplan.display_cursor (
    null, null, 'BASIC LAST +REMOTE'
  )
);




select sql_id from v$sql
where  sql_text = q'|SELECT /*+ NO_MERGE */ "A1"."INVOICE_ID","A1"."PAID_DATE","A1"."STATE_CODE","A2"."INVOICE_ID","A2"."QUANTITY","A2"."UNIT_PRICE" FROM "INVOICES" "A1","INVOICE_LINES" "A2" WHERE "A1"."INVOICE_ID"="A2"."INVOICE_ID" AND "A1"."PAID_DATE"<TO_DATE(' 2018-09-02 00:00:00', 'syyyy-mm-dd hh24:mi:ss') AND "A1"."PAID_DATE">=TO_DATE(' 2018-09-01 00:00:00', 'syyyy-mm-dd hh24:mi:ss')|';

select * 
from   table (
  dbms_xplan.display_cursor (
    '6fau4pcdj6wp2', null, 'IOSTATS ALL'
  )
);



/* Materialized views! */
/*
create materialized view remote_invoices 
build immediate 
disable query rewrite 
as
  select trunc(i.paid_date) paid,
         i.state_code,
         sum ( il.quantity * il.unit_price ) value
  from   invoices@loopback i
  join   invoice_lines@loopback il
  on     i.invoice_id = il.invoice_id
  group  by trunc(i.paid_date),
         i.state_code;
  
create index mv_state_paid_i 
  on remote_invoices ( state_code, paid );
*/
select * from remote_invoices;





with invs as (
  select paid,
         state_code,
         value
  from   remote_invoices
  where  paid >= date'2018-09-01'
  and    paid < date'2018-09-02'
)
  select paid , 
         round(sum((i.value)/ex_rate), 2) value
  from   invs i
  join   states s
  on     i.state_code = s.abbreviation 
  join   countries c
  on     s.country = c.iso_code_2
  join   exchange_rates@loopback ex
  on     ex.CURRENCY_CODE = c.CURRENCY_ALPHA_CODE
  group  by i.paid ;