--@C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202204-setup





select * from transactions
where  inc ( id ) = 2;


create or replace function inc ( p int ) 
  return int as
begin
  return p + 1;
end inc;
/








/*
create table transactions  (	
  id            number
    not null primary key, 
	trans_date    date not null, 
	customer_name varchar2(10) not null, 
	amount        number not null, 
	notes         varchar2(100) not null
);
*/







/* Get the EXPLAIN plan */
select * from transactions
where  inc ( id ) = 2;






select * from transactions
where  id = 2 - 1;



/***************************************




***************************************/


/*
create index date_i
  on transactions ( trans_date );
*/
select * from transactions
where  trans_date = trunc ( sysdate );







/* Find all the rows for a given day 
  TRUNC prevents trans_date index use
*/
select * from transactions
where  trunc ( trans_date ) = trunc ( sysdate );








/* Can full scan index in some cases */
select trans_date from transactions
where  trunc ( trans_date ) = trunc ( sysdate );





/*
create index trunc_date_i
  on transactions ( trunc ( trans_date ) )
  invisible;
*/
alter index trunc_date_i
  visible;
  
  
/* Expression in WHERE matches index */
select * from transactions
where  trunc ( trans_date ) = trunc ( sysdate );







/* Limited reuse for function-based index */
select * from transactions
where  trunc ( trans_date, 'hh24' ) = trunc ( sysdate, 'hh24' );







/* Rearrange - can use regular index! */
select * from transactions
where  trans_date >= trunc ( sysdate )
and    trans_date < trunc ( sysdate ) + 1;



select * from transactions
where  trans_date between trunc ( sysdate ) and trunc ( sysdate ) + 1 - 1/86400;





/* Change granularity */
select * from transactions
where  trans_date >= trunc ( sysdate, 'hh24' )
and    trans_date < trunc ( sysdate, 'hh24' ) + 1/24;



/***************************************





***************************************/

select * from transactions
where  customer_name in ( 'Chris', 'CHRIS', 'chris' )
order  by id;








/* Case insensitive search */
select * from transactions
where  customer_name collate binary_ci = 'Chris';






/* Can't rearrange */
select * from transactions
where  customer_name = 'Chris' collate binary_ci;







/* Format values on insert/update? */
select id, customer_name, customer_name_upper, trans_date
from   transactions
where  customer_name_upper = upper ( 'chris' )
order  by id;







/* Storing UPPER only is risky - what about McDonald? */







/*
create index ci_name_i 
  on transactions ( customer_name collate binary_ci )
  invisible;
*/
alter index ci_name_i 
  visible;

select * from transactions
where  customer_name collate binary_ci = 'Chris';








/* What about old-school case-insensitive search? */
select * from transactions
where  lower ( customer_name ) = lower ( 'chris' );






/*
alter table transactions
  add ( 
    customer_name_lower_vc
      invisible
      as ( lower ( customer_name ) )
  );
  
create index lower_name_i
  on transactions ( customer_name_lower_vc )
  invisible;
*/
alter table transactions
  modify customer_name_lower_vc
  visible;
alter index lower_name_i
  visible;
  
  

select * from transactions
where  customer_name_lower_vc = 'chris';





/* Can infer too! */
select * from transactions
where  lower ( customer_name ) = 'chris';







/* Can't create FBI matching virtual column expression */
create index lower_name_fbi
  on transactions ( lower ( customer_name ) );




/* Function-based indexes are really virtual columns + index */
select column_name, virtual_column, hidden_column, user_generated, 
       data_default
from   user_tab_cols
where  table_name = 'TRANSACTIONS';






/* Can use FBI columns... if you must */
select * from transactions
where  sys_nc00008$ = trunc ( sysdate );




/***************************************




***************************************/



create or replace function currency_conversion ( 
  amount number, ex_rate number
) 
  return number deterministic as
  converted_amount number;
begin

  if ex_rate = 0 then
    converted_amount := 0;  
  else
    converted_amount := floor (
      ( amount / ex_rate ) * 100
    ) / 100;
  end if;
  
  return converted_amount;
end currency_conversion;
/

/*
create index converted_amount_i
  on transactions ( currency_conversion ( amount, 1.5 ) )
  invisible;
*/

alter index converted_amount_i
  visible;

select *
from   transactions
where  currency_conversion ( amount, 1.5 ) = 2;







/* But what if we want to use a different ex rate? */
select *
from   transactions
where  currency_conversion ( amount, 2.5 ) = 2;





/* Compare
Standard (deterministic) PL/SQL function
Pragma UDF function
SQL macro 
*/
begin

  timing_pkg.set_start_time();
  for vals in (
    select *
    from   transactions
    where  currency_conversion ( amount, 2.5 ) = 2
  ) loop
    null;
  end loop;
  timing_pkg.calc_runtime( 'Pure PL/SQL' );
  
  timing_pkg.set_start_time();
  for vals in (
    select *
    from   transactions
    where  currency_conversion_udf ( amount, 2.5 ) = 2
  ) loop
    null;
  end loop;
  timing_pkg.calc_runtime( 'UDF' );
  
  timing_pkg.set_start_time();
  for vals in (
    select *
    from   transactions
    where  currency_conversion_macro ( amount, 2.5 ) = 2
  ) loop
    null;
  end loop;
  timing_pkg.calc_runtime( 'Macro' );
  
end;
/

create or replace function currency_conversion_udf ( 
  amount number, ex_rate number
) 
  return number deterministic as
  pragma udf;
  converted_amount number;
begin

  if ex_rate = 0 then
    converted_amount := 0;  
  else
    converted_amount := floor (
      ( amount / ex_rate ) * 100
    ) / 100;
  end if;
  
  return converted_amount;
end currency_conversion_udf;
/


create or replace function currency_conversion_macro ( 
  amount number, ex_rate number
) 
  return varchar2 sql_macro ( scalar ) as
  conversion_expression varchar2(1000);
begin

  conversion_expression := 'case ex_rate
    when 0 then 0
    else floor (
      ( amount / ex_rate ) * 100
    ) / 100
  end';
  
  return conversion_expression;
end currency_conversion_macro;
/
;





/* Macros & UDF have similar performance 
 - so why macros? 
   Full visibility of underlying expression!
*/
select *
from   transactions
where  currency_conversion_udf ( amount, 2.5 ) = 2;

select *
from   transactions
where  currency_conversion_macro ( amount, 2.5 ) = 2;
/* Macro resolves to this:

select *
from   transactions
where  case 2.5
  when 0 then 0
  else floor (
    ( amount / 2.5 ) * 100
  ) / 100
end = 2;
*/




/* Always returns zero => no rows fetched */
select *
from   transactions
where  currency_conversion_udf ( amount, 0 ) = 2;




/* Macro can spot this & optimize! */
select *
from   transactions
where  currency_conversion_macro ( amount, 0 ) = 2;






/* Can't use macro in index */
create index conversion_macro_i
  on transactions (
    currency_conversion_macro ( amount, 1.5 )
  );

  
/* Create it on the underlying expression */
/*
create index conversion_macro_i
  on transactions (
    case 1.5
      when 0 then 0
      else floor (
        ( amount / 2.5 ) * 100
      ) / 100
    end
  );
*/