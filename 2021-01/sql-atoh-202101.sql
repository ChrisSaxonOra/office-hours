select * from co.orders;




select * from co.orders
pivot  (
  count(*) 
  for customer_id 
  in ( 1, 2, 3 )
);





select * from co.orders
where  customer_id in ( 1, 2, 3 ) -- doesn't work 
pivot  (
  count(*) 
  for customer_id 
  in ( 1, 2, 3 )
)
--where  customer_id in ( 1, 2, 3 ) -- neither does this 
where  "1" > 0 or "2" > 0 or "3" > 0
;




/* Remove implicit grouping */
with rws as (
  select customer_id from co.orders
  where  customer_id in ( 1, 2, 3 )
)
  select * from rws
  pivot  (
    count(*) 
    for customer_id 
    in ( 1 as "CUST_1", 2 as "CUST_2", 3 as "CUST_3" )
  );






/* This doesn't work... */
select * from co.orders
pivot  (
  count(*) 
  for to_char ( order_datetime, 'MON' )
  in ( 'Jan', 'Feb', 'Mar' )
);


  
  
/* Show totals per month */
with order_totals as (
  select to_char ( o.order_datetime, 'MON' ) order_month
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*)
    for order_month in (
      'JAN' JAN, 'FEB' FEB, 'MAR' MAR, 'APR' APR, 'MAY' MAY, 'JUN' JUN
    )
  );
/* What's the problem with results? */
  
  
  
  
  
  

/* Add year to subquery => implicit grouping in pivot */
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*)
    for order_month in (
      'JAN' JAN, 'FEB' FEB, 'MAR' MAR, 'APR' APR, 'MAY' MAY, 'JUN' JUN
    )
  )
--  group by order_year
  order by order_year;
  
  
  
  
/* Multiple aggregations */
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month,
         customer_id
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*) orders,
    count ( distinct customer_id ) customers
    for order_month in (
      'JAN' JAN, 'FEB' FEB, 'MAR' MAR
    )
  )
  order by order_year;
  
  
  
/* Multi-column pivot */
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month,
         customer_id
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*) orders
    for ( customer_id, order_month ) in (
      ( 1, 'JAN' ) jan_cust_1, 
      ( 1, 'FEB' ) feb_cust_1, 
      ( 2, 'FEB' ) feb_cust_2, 
      ( 3, 'MAR' ) mar_cust_3
    )
  )
  order by order_year;
  
  

/*********************************





*********************************/


/* Dymamic pivoting - doesn't work! */
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*) orders
    for order_month in (
      select to_char ( add_months ( sysdate, level - 1 ), 'MON' ) 
      from   dual 
      connect by level <= 3
    )
  );
  
  

set long 10000
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month
  from   co.orders o
)
  select xmlserialize ( document order_month_xml indent size = 2 )
  from   order_totals
  pivot  (
    count (*) orders
    for order_month in (
      select to_char ( add_months ( sysdate, level - 1 ), 'MON' ) 
      from   dual 
      connect by level <= 3
    )
  );
  
  


/* Standard column headings */
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         dense_rank () over ( -- careful with row_number() vs rank() vs dense_rank()!
           partition by extract ( year from o.order_datetime )
           order by to_char ( o.order_datetime, 'YYYYMM' ) 
         ) rn
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*) orders
    for rn in ( 1, 2, 3 )
  );
  
  
  
  
/* Add metadata */
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month,
         dense_rank () over ( -- careful with row_number() vs rank() vs dense_rank()!
           partition by extract ( year from o.order_datetime )
           order by to_char ( o.order_datetime, 'YYYYMM' ) 
         ) rn
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*) orders, max ( order_month ) mth
    for rn in ( 1, 2, 3 )
  );
  
  
  
select listagg ( 
           '''' || to_char ( add_months ( sysdate, level - 1 ), 'MON' ) || '''', ','
         ) within group ( order by 1 )
  from   dual 
  connect by level <= 3;
  
/* Dynamic SQL */
set serveroutput on
var cur refcursor;
declare
  pivot_values clob;
  stmt         clob;
begin
  select listagg ( 
           '''' || to_char ( add_months ( sysdate, level - 1 ), 'MON' ) || '''', ','
         ) within group ( order by 1 )
  into   pivot_values
  from   dual 
  connect by level <= 3;
  
  stmt := q'!
  with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month
  from   co.orders o
)
  select * from order_totals
  pivot (
    count (*) orders
    for order_month in ( !' || pivot_values || ' )
  )';
  
  dbms_output.put_line ( stmt );
  
  open :cur for stmt;

end;
/
print :cur


  
  
  
/**********************************





**********************************/

/* Rollup pivot */
with order_totals as (
  select extract ( year from o.order_datetime ) order_year,
         to_char ( o.order_datetime, 'MON' ) order_month
  from   co.orders o
)
  select order_year, sum ( jan ), sum ( feb ), sum ( mar ), 
         sum ( jan ) + sum ( feb ) + sum ( mar ) year_tot
  from   order_totals
  pivot (
    count (*)
    for order_month in (
      'JAN' JAN, 'FEB' FEB, 'MAR' MAR
    )
  )
  group by rollup ( order_year )
  order by order_year;  



/* Rollup in subquery */
with order_totals as (
  select count (*) orders,
         case grouping_id ( to_char ( o.order_datetime, 'MON' ) ) 
           when 1 then 'Total'
           else to_char ( o.order_datetime, 'MON' ) 
         end order_month,
         case grouping_id ( extract ( year from o.order_datetime ) )
           when 1 then 'Total'
           else to_char ( extract ( year from o.order_datetime ) )
         end order_year
  from   co.orders o
  group  by rollup ( extract ( year from o.order_datetime ) ),
         rollup ( to_char ( o.order_datetime, 'MON' ) )
         
)
  select * from order_totals
  pivot (
    sum ( orders )
    for order_month in (
      'JAN' JAN, 'FEB' FEB, 'MAR' MAR, 'Total' tot
    )
  )
  order by order_year;
  
  
/**********************************





**********************************/

drop table year_month_sales 
  cascade constraints purge;
create table year_month_sales as
  with order_totals as (
    select extract ( year from o.order_datetime ) order_year,
           to_char ( o.order_datetime, 'MON' ) order_month
    from   co.orders o
  )
    select * from order_totals
    pivot (
      count (*)
      for order_month in (
        'JAN' JAN, 'FEB' FEB, 'MAR' MAR, 'APR' APR, 'MAY' MAY, 'JUN' JUN,
        'JUL' JUL, 'AUG' AUG, 'SEP' SEP, 'OCT' OCT, 'NOV' NOV, 'DEC' DEC
      )
    )
    order by order_year;
    
    
select * from year_month_sales;

select * from year_month_sales
unpivot (
  orders
  for sale_month 
  in ( jan, feb, mar )
);





select * from co.orders
unpivot (
  col_value
  for col_name 
  in ( order_datetime, customer_id, order_status, store_id )
);


with rws as (
  select order_id, 
         to_char ( order_datetime, 'yyyy-mm-dd' ) order_datetime, 
         to_char ( customer_id ) customer_id , 
         order_status, 
         to_char ( store_id ) store_id
  from   co.orders
)
  select * from rws
  unpivot (
    col_value
    for col_name 
    in ( order_datetime, customer_id, order_status, store_id )
  );




with rws as (
  select order_year, jan, feb, mar, apr from year_month_sales
)
  select * from rws
  unpivot (
    ( month_1, month_2 )
    for sale_month
    in ( ( jan, feb ), ( mar, apr ) as 'Mar Apr' )
  );

/**********************************





**********************************/

/* Transpose! */
select * from year_month_sales
unpivot (
  orders
  for sale_month 
  in ( 
    jan, feb, mar, apr, may, jun, 
    jul, aug, sep, oct, nov, dec 
  )
)
pivot (
  sum ( orders ) 
  for order_year in (
    2018, 2019
  )
);



/**********************************





**********************************/

select customer_id , src_col, src_val, min ( tab )
from  (
select customer_id, src_col, src_val,
       0  old_c, 1  new_c, 't1' tab
from customers 
unpivot ( 
  src_val
  for src_col
  in  ( full_name, email_address )
)
union all
select customer_id, src_col, src_val,
       1  old_c, 0  new_c, 't2' tab 
from co.customers 
unpivot ( 
  src_val
  for src_col
  in  ( full_name, email_address )
)
)
group  by customer_id, src_col, src_val
having sum ( old_c ) <> sum ( new_c )
order  by 1, 2;
