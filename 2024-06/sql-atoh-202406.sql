@sql-atoh-202406-setup

/* Output multiples of 3 and 5 */
declare 
  upper_bound pls_integer := 100;
  fizz        pls_integer := 3;
  buzz        pls_integer := 5;
begin
  for n in 0 .. upper_bound 
  loop
    dbms_output.put_line ( n );
    if mod ( n, fizz ) = 0 
    and mod ( n, buzz ) = 0 then
      dbms_output.put_line ( 'FizzBuzz ' || n );
    end if;
  end loop;
end;
/






/* Output multiples of 3 and 5
   Enter loop for multiples of 3 & 5 */
declare 
  upper_bound pls_integer := 100;
  fizz        pls_integer := 3;
  buzz        pls_integer := 5;
begin
  for n in 0 .. upper_bound 
    by fizz 
    when mod ( n, buzz ) = 0
  loop
    dbms_output.put_line ( n );
    if mod ( n, fizz ) = 0 
    and mod ( n, buzz ) = 0 then
      dbms_output.put_line ( 'FizzBuzz ' || n );
    end if;
  end loop;
end;
/




declare 
  upper_bound pls_integer := 100;
  fizz        pls_integer := 3;
  buzz        pls_integer := 5;
begin
  for n in 0 .. upper_bound 
    by ( fizz * buzz )
  loop
    dbms_output.put_line ( 'FizzBuzz ' || n );
  end loop;
end;
/

















/* Non-integer increments */
begin
  for n number in 0 .. 1 
    by 0.1
  loop
    dbms_output.put_line ( n );
  end loop;
end;
/





/* Iterate through dates */
begin
  for dt date in date'1999-12-31', date'2024-06-18'
  loop
    dbms_output.put_line ( dt );
  end loop;
end;
/



/* Iterate through strings */
begin
  for country varchar2(2) in 'GB', 'US', 'IN' 
  loop
    dbms_output.put_line ( country );
  end loop;
end;
/






/* Display powers of 2 - repeat expression */
declare 
  upper_bound pls_integer := 100;
  exponent    pls_integer := 2;
begin

  for powers in 1, 
    repeat powers * exponent 
    while powers < upper_bound
  loop
    dbms_output.put_line ( 'Val = ' || powers );  
  end loop;

end;
/




/* Powers - mutable index: 
   AVOID! ONLY do this if there's NO alternative */
declare 
  upper_bound pls_integer := 100;
  exponent    pls_integer := 2; -- 3
begin

  for powers mutable in 1 .. upper_bound loop
    dbms_output.put_line ( 'Val = ' || powers );  
    powers := ( powers * exponent ) - 1; -- value is still incremented!
  end loop;

end;
/








/* Fibonnaci numbers */
declare 
  upper_bound pls_integer := 100;
  prev_n      pls_integer;
  prev_prev_n pls_integer;
begin

  for fibs in 0, 1,
    repeat prev_prev_n + prev_n
    while fibs < upper_bound
  loop
    dbms_output.put_line ( 'Val = ' || fibs );  
    prev_prev_n := prev_n;
    prev_n := fibs;
  end loop;

end;
/






/* Multiples of 3 & 5, Fibonnaci numbers & powers in one loop! */
declare 
  upper_bound pls_integer := 100;
  prev_n      pls_integer;
  prev_prev_n pls_integer;
  exponent    pls_integer := 2;
  fizz        pls_integer := 3;
  buzz        pls_integer := 5;
begin

  for n in 0 .. upper_bound 
    by ( fizz * buzz ),
    0, 1,
    repeat prev_prev_n + prev_n
    while n < upper_bound,
    1, 
    repeat n * exponent 
    while n < upper_bound
  loop
    dbms_output.put_line ( 'Val = ' || n );  
    prev_prev_n := prev_n;
    prev_n := n;
  end loop;

end;
/


/************************************




************************************/

select * from countries;
select * from ex_rates;


/* Currency conversion function */ 
create or replace function ex_rate_conversion ( 
  price number, ex_rate number, minor_units integer
) 
  return number deterministic as
begin
  return ceil ( price * ex_rate ) - ( 1 / power ( 10, minor_units ) ) ;
end ex_rate_conversion;
/







/* Check the plan */
select /* function */
  currency_code,  ex_rate_conversion ( 9.99, ex_rate, minor_units )
from   countries 
join   ex_rates
using  ( currency_code )
where  ex_rate_conversion ( 9.99, ex_rate, minor_units ) >= 10;






/* Turn it into a macro */
create or replace function ex_rate_conversion_macro ( 
  price number, ex_rate number, minor_units integer
) 
  return clob sql_macro ( scalar ) as
begin
  return ' ceil ( price * ex_rate ) - ( 1 / power ( 10, minor_units ) ) ';
end ex_rate_conversion_macro;
/


/* Check the plan now */
select /* macro */
  currency_code, ex_rate_conversion_macro ( 9.99, ex_rate, minor_units )
from   countries 
join   ex_rates
using  ( currency_code )
where  ex_rate_conversion_macro ( 9.99, ex_rate, minor_units ) >= 10;





/* Macro conversion ONLY in SQL */
exec dbms_output.put_line ( ex_rate_conversion_macro ( 9.99, 1.24, 2 ) );







/* Enable the transpiler */
alter session set sql_transpiler = on;

select /* transpiled */ 
  currency_code,  ex_rate_conversion ( 9.99, ex_rate, minor_units )
from   countries 
join   ex_rates
using  ( currency_code )
where  ex_rate_conversion ( 9.99, ex_rate, minor_units ) >= 10;








/* Function must have NO SQL statements or PL/SQL constructors */
create or replace function ex_rate_conversion ( 
  price number, ex_rate number, minor_units integer
) 
  return number deterministic as
  dummy dual%rowtype;
begin
  return ceil ( price * ex_rate ) - ( 1 / power ( 10, minor_units ) ) ;
end ex_rate_conversion;
/

select /* not transpiled */ 
  currency_code,  ex_rate_conversion ( 9.99, ex_rate, minor_units )
from   countries 
join   ex_rates
using  ( currency_code )
where  ex_rate_conversion ( 9.99, ex_rate, minor_units ) >= 10;





/* What's the use of scalar macros?
   Returning SQL expressions! */
create or replace function case_insensitive ( p varchar2 )
return int as
begin
  -- invalid PL/SQL expression
  return p collate binary_ci;
end;
/




create or replace function case_insensitive ( p varchar2 ) 
return clob sql_macro ( scalar ) as
begin
  -- valid SQL
  return ' p collate binary_ci ';
end;
/

select last_name from hr.employees
where  case_insensitive ( last_name ) = 'KING';



/************************************




************************************/

set serveroutput on
/* Extended case controls */
declare
  country_code varchar2(6) := 'GB';
begin
  -- Simple case expression; repeat values
  dbms_output.put_line ( 
    case upper ( country_code )
      when 'GB' then 'GBP'
      when 'DE' then 'EUR'
      when 'FR' then 'EUR'
      when 'IT' then 'EUR'
      when 'XA' then 'XXX'
    end
  );
  
  
  
  -- Searched case expression; repeat selector
  dbms_output.put_line ( 
    case 
      when upper ( country_code ) = 'GB' then 'GBP'
      when upper ( country_code ) in ( 'DE', 'FR', 'IT' ) then 'EUR'
      when upper ( country_code ) like 'X_' then 'XXX'
    end
  );
  
  
  
  
  
  -- Extended case expression
  dbms_output.put_line ( 
    case upper ( country_code )
      when 'GB' then 'GBP'
      when in ( 'DE', 'FR', 'IT' ) then 'EUR'
      when like 'X_' then 'XXX'
    end
  );
  
  
end;
/


/* JSON <> PL/SQL types - to varray and back */
declare
  jdata json := json ( '[1, 2, 3]' );
  type va is varray(10) of integer;
  arr1 va;
begin
  arr1 := json_value ( jdata, '$' returning va );
  for v in values of arr1 loop
    dbms_output.put_line ( v );
  end loop;
  dbms_output.put_line ( json_serialize ( json ( arr1 ) ) );
end;
/




/* JSON <> PL/SQL types - to nested table and back */
declare
  jdata json := json ( '[1, 2, 3]' );
  type nt is table of number;

  arr1 nt;
begin
  arr1 := json_value ( jdata, '$' returning nt );
  for v in values of arr1 loop
    dbms_output.put_line ( v );
  end loop;
  dbms_output.put_line ( json_serialize ( json ( arr1 ) ) );
end;
/




declare
  jdata json := json ( '[1, 2, 3]' );
  type nt is table of number;

  arr1 nt;
begin
  arr1 := json_value ( jdata, '$' returning nt );
  arr1.delete(2);
  for i in indices of arr1 loop
    dbms_output.put_line ( i );
  end loop;
  dbms_output.put_line ( json_serialize ( json ( arr1 ) ) );
end;
/








/* API to convert currencies */
create or replace package currency_api as 

  type country_prices is record (
    currency_code varchar2(3),
    amount number
  );
  type country_prices_arr 
    is table of country_prices
    index by varchar2(2);  
    
  procedure get_country_prices ( 
    countries in out country_prices_arr,
    price     in number
  );

end;
/

/* Original (pre-23ai) implementation */
create or replace package body currency_api as 
  
  procedure get_country_prices ( 
    countries in out country_prices_arr,
    price     in number
  ) as
    country varchar2(2);
  begin
    
    country := countries.first;
    while country is not null 
    loop
      
      select currency_code, 
             ex_rate_conversion ( price, ex_rate, minor_units )
      into   countries ( country ).currency_code,
             countries ( country ).amount
      from   countries 
      join   ex_rates
      using  ( currency_code )
      where  country_code = country;
      
      countries ( country ).amount := 
        case 
          when countries ( country ).currency_code in ( 'XXX', 'XTS' ) then 999999
          when countries ( country ).currency_code like 'XB_' then null
          else countries ( country ).amount
        end;
      
      country := countries.next ( country );
      
    end loop;
  end;

end;
/

/* Old-school way to call API */
declare 
  countries currency_api.country_prices_arr;
  country varchar2(2);
begin
  countries ( 'US' ) := null;
  countries ( 'GB' ) := null;
  countries ( 'DE' ) := null;
  countries ( 'IN' ) := null;
  countries ( 'XX' ) := null;
  
  currency_api.get_country_prices ( countries, 9.99 );
  
  country := countries.first;
  while country is not null 
  loop
    dbms_output.put_line ( 
      country || ' = ' || 
      nvl ( countries ( country ).currency_code, 'N/A' ) || 
      to_char ( countries ( country ).amount, '999,990.00' ) 
    );
    country := countries.next ( country );
  end loop;
end;
/







/* Update API for 23ai */
create or replace package body currency_api as 
  
  procedure get_country_prices ( 
    countries in out country_prices_arr,
    price     in number
  ) as
    country_arr dbms_sql.varchar2_table;
  begin

    /* Convert array so we can query it */
    country_arr := dbms_sql.varchar2_table (
      for c varchar2(2) in indices of countries
      sequence => c
    );

    countries := country_prices_arr (
      for rws in (
        select 
            column_value as country_code, currency_code,
            ex_rate_conversion ( price, ex_rate, minor_units ) as amount
        from   table ( country_arr ) ctry 
        left   join countries 
        on     country_code = column_value
        left   join ex_rates
        using  ( currency_code )
      ) 
      index rws.country_code 
      => country_prices ( rws.currency_code, rws.amount )
    );
    
    for i, v in pairs of countries loop
      countries (i).amount := 
        case v.currency_code 
          when in ( 'XXX', 'XTS' ) then 999999
          when like 'XB_' then null
          when is null then 0
          else v.amount
        end;
    end loop;
  
  end;

end;
/






/* Call API - 23ai style! */
declare
  countries_json json := json ( q'< { 
    "US" : null, "GB" : null, "IN" : null, "DE" : null, "XX" : null, "ZZ" : null 
  } >' );
  countries currency_api.country_prices_arr;
  
  price   number := 9.99;

begin

  /* Convert JSON object to PL/SQL array */
  countries := json_value ( 
    countries_json, 
    '$' returning currency_api.country_prices_arr 
  );

  currency_api.get_country_prices ( countries, 9.99 );

  for country, price in pairs of countries loop
    dbms_output.put_line ( 
      country || ' = ' || 
      nvl ( price.currency_code, 'N/A' ) || 
      to_char ( price.amount, '999,990.00' ) 
    );
  end loop;
  
  /* Get output as JSON */
  dbms_output.put_line ( 
    json_serialize ( json ( countries ) pretty )
  );
  
end;
/









/*************************************


                FIN


*************************************/





create or replace function ex_rate_conversion_macro ( 
  price number, ex_rate number, minor_units integer
) 
  return clob sql_macro ( scalar ) as
begin
  return ' ceil ( price * ex_rate ) - ( 1 / power ( 10, minor_units ) ) ';
end ex_rate_conversion_macro;
/




create or replace function first_not_null ( 
  v1 int, v2 int
) 
  return int as
begin
  return coalesce ( v1, v2 );
end first_not_null;
/

select first_not_null ( 1, 1/0 );




create or replace function first_not_null  ( 
  v1 int, v2 int
) 
  return varchar2 sql_macro ( scalar ) as
begin
  return ' coalesce ( v1, v2 ) ';
end first_not_null;
/

select first_not_null ( 1, 1/0 );







/* The macro becomes this */
select coalesce ( 1, 1/0 );





/* They're SQL macros, not PL/SQL macros */
begin 
  dbms_output.put_line ( 'Func  = ' || ex_rate_conversion ( 100, 1, 1 ) );
  dbms_output.put_line ( 'Macro = ' || ex_rate_conversion_macro ( 100, 1, 1 ) );
end;
/
