cl scr
drop table transactions purge;
alter session set nls_date_format = 'dd-Mon-yyyy hh24:mi';
exec dbms_random.seed (0);
create table transactions ( 
  id primary key, trans_date not null, customer_name not null, 
  amount not null, notes not null, customer_name_upper not null 
) as 
with rws as (
  select level x, 
         case level
           when 1 then 'CHRIS'
           else dbms_random.string ( 'a', 10 ) 
         end str
  from   dual
  connect by level <= 10000
)
  select 
    rownum id, 
    date'2020-01-01' + ( rownum / 10000 ) dt, 
    case mod ( rownum, 3 )
      when 0 then cast ( upper ( r2.str ) as varchar2(10) )
      when 1 then cast ( lower ( r2.str ) as varchar2(10) )
      when 2 then cast ( initcap ( r2.str ) as varchar2(10) )
    end,
    mod ( rownum, 100000 ) / 25,
    rpad ( 'stuff', 100, 'f' ), 
    cast ( upper ( r2.str ) as varchar2(10) )
  from   rws r1
  cross  join rws r2
  where  rownum <= 10000000
  order  by dt, dbms_random.value;
  
alter table transactions
  add ( 
    customer_name_lower_vc
      invisible
      as ( lower ( customer_name ) )
  );

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

create index date_i
  on transactions ( trans_date );
create index name_i
  on transactions ( customer_name );
create index upper_name_i
  on transactions ( customer_name_upper );
  
create index trunc_date_i
  on transactions ( trunc ( trans_date ) )
  invisible;
create index ci_name_i 
  on transactions ( customer_name collate binary_ci )
  invisible;
create index lower_name_i
  on transactions ( customer_name_lower_vc )
  invisible;
create index converted_amount_i
  on transactions ( currency_conversion ( amount, 1.5 ) )
  invisible;

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


exec dbms_stats.gather_table_stats ( user, 'transactions' ) ;
set echo on
set timing on
