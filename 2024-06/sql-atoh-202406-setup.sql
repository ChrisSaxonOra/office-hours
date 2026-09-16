alter session set sql_transpiler = off;

drop table country_list
  cascade constraints purge;
drop table countries
  cascade constraints purge;
drop table ex_rates
  cascade constraints purge;
  
drop package currency_api;

create table ex_rates (
  currency_code varchar2(3 char)
    primary key,
  ex_rate number
    not null,
  minor_units integer
    not null
);
create table countries (
  country_code varchar2(2 char)
    primary key,
  currency_code
    references ex_rates
);

insert into ex_rates 
values ( 'USD', 1, 2 ), ( 'EUR', 1.0209, 2 ), ( 'GBP', 0.88857, 2 ), 
       ( 'INR', 82.755, 2 ), ( 'XTS', 0, 0 ), ( 'JPY', 149.85, 0 ), 
       ( 'CAD', 1.3691, 2 ), ( 'MXN', 20.063, 2 ), 
       ( 'SEK', 11.215, 2 ), ( 'DKK', 5.2273, 2 ), ( 'NOK', 10.613, 2 ), 
       ( 'BRL', 5.2273, 2 );

insert into countries 
values ( 'US', 'USD' ), ( 'GB', 'GBP' ), ( 'IN', 'INR' ), ( 'NL', 'EUR' ), 
       ( 'FR', 'EUR' ), ( 'DE', 'EUR' ), ( 'JP', 'JPY' ), ( 'XX', 'XTS' ), 
       ( 'PT', 'EUR' ), ( 'ES', 'EUR' ), ( 'DK', 'DKK' ), ( 'SE', 'SEK' ), 
       ( 'NO', 'NOK' ), ( 'IE', 'EUR' ), ( 'MX', 'MXN' ), ( 'BR', 'BRL' ), 
       ( 'CA', 'CAD' );

commit;

cl scr