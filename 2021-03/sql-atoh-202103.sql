select level as n from dual
connect by level <= :N;


select date'2021-01-01'
         + level - 1 as dt
from   dual
connect by level <= :N;


select date'2021-01-01'
         + level - 1 as dt
from   dual
connect by level <= 365;







with rws as (
  select min ( order_datetime ) mn_dt,
         max ( order_datetime ) mx_dt
  from   co.orders o
), dates as (
  select trunc ( mn_dt ) + level - 1 dt
  from   rws
  connect by level <= (
    extract ( day from ( mx_dt - mn_dt ) ) + 1
  )
)
  select dt, count(order_datetime) from dates
  left join co.orders
  on     dt <= order_datetime
  and    dt + 1 > order_datetime
  group  by dt
  order  by dt;
  
  
with stor as (
  select store_id, order_datetime
  from   co.orders o
  where  store_id = 23
), rws as (
  select min ( trunc ( order_datetime ) ) mn_dt,
         max ( trunc ( order_datetime ) ) mx_dt
  from   stor
)
  select dt, count ( order_datetime ) from (
    select mn_dt + level - 1 as dt
    from   rws 
    connect by level <= mx_dt - mn_dt + 1
  )
  left join stor
  on     dt <= order_datetime
  and    dt + 1 > order_datetime
  group  by dt
  order  by dt;
  

/* Generate all then filter */
with rws as (
  select date'2021-01-01'
           + level - 1 as dt
  from   dual
  connect by level <= (
    date'2022-01-01' - date'2021-01-01'
  )  
)
  select * from rws
  where  to_char ( dt, 'FMDay' ) = 'Monday';
  


  
/* Only generate needed days */
with rws as (
  select next_day ( date'2021-01-01' - 1, 'Friday' )
           + ( level - 1 ) * 7 as dt
  from   dual
  connect by level <= (
    ( date'2021-12-31' - next_day ( date'2021-01-01' - 1, 'Friday' ) + 7 ) / 7
  )  
)
  select dt from rws;
  
  
  
with rws as (
  select next_day ( date'2021-01-01' - 1, 'Saturday' )
           + ( level - 1 ) * 7 as dt
  from   dual
  connect by level <= (
    ( date'2021-12-31' - next_day ( date'2021-01-01' - 1, 'Saturday' ) + 7 ) / 7
  )  
)
  select dt from rws;
  

alter session set nls_language = Spanish;

select next_day ( date'2021-01-01', 'Friday' ) from dual;

alter session set nls_language = English;

select next_day ( date'2021-01-01', 'Viernes' ) from dual;
  
  
select add_months ( 
         date'2021-01-01',
         level - 1
       ) as dt
from   dual
connect by level <= months_between (
  date'2021-12-31',
  date'2021-01-01' 
) + 1;



select add_months ( 
         date'2021-01-15',
         level - 1
       ) as dt
from   dual
connect by level <= months_between (
  date'2022-01-15',
  date'2021-01-15' 
) + 1;


/* Month offset */
with mths as (
  select add_months ( 
           date'2021-01-15',
           level - 1
         ) as dt
  from   dual
  connect by level <= months_between (
    date'2022-01-15',
    date'2021-01-15' 
  ) + 1
)
  select case rownum 
           when 1 then dt
           else trunc ( dt, 'mm' ) 
         end start_date,
         lead ( 
           trunc ( dt, 'mm' ) - 1,
           1, dt
         ) over ( 
           order by dt 
         ) end_date
  from   mths;
  



select date'2021-01-01'
         + numtoyminterval ( level - 1, 'year' ) as dt
from   dual
connect by level <= ( months_between (
  date'2022-12-31',
  date'2020-01-01'
) / 12 ) + 1;
  
  

/* SQL Macros! */
create or replace package date_mgr as 

  function generate_days ( 
    start_date date, end_date date,
    day_increment integer default 1
  ) 
    return varchar2 sql_macro;
  
  function generate_months ( 
    start_date date, end_date date,
    month_increment integer default 1
  ) 
    return varchar2 sql_macro;
    
  function generate_years ( 
    start_date date, end_date date,
    year_increment integer default 1
  ) 
    return varchar2 sql_macro;

end date_mgr;
/

create or replace package body date_mgr as 
  
  function generate_days ( 
    start_date date, end_date date,
    day_increment integer default 1
  ) 
    return varchar2 sql_macro as
    stmt varchar2(4000);
  begin
    
    stmt := 'select start_date
             + ( level - 1 ) * day_increment as dt
    from   dual
    connect by level <= (
      ( ( end_date - start_date ) + day_increment ) / day_increment
    )';
  
    dbms_output.put_line ( stmt );
  
    return stmt;
    
  end generate_days;
  
  function generate_months ( 
    start_date date, end_date date,
    month_increment integer default 1
  ) 
    return varchar2 sql_macro as
    stmt varchar2(4000);
  begin
    
    stmt := '
    select add_months ( 
             start_date,
             ( level - 1 ) * month_increment
           ) as dt
    from   dual
    connect by level <= ( months_between (
      end_date,
      start_date
    ) + month_increment ) / month_increment';
  
    dbms_output.put_line ( stmt );
  
    return stmt;
    
  end generate_months;
  
  function generate_years ( 
    start_date date, end_date date,
    year_increment integer default 1
  ) 
    return varchar2 sql_macro as
    stmt varchar2(4000);
  begin
    
    stmt := q'!
    select start_date
             + numtoyminterval ( ( level - 1 ) * year_increment, 'year' ) as dt
    from   dual
    connect by level <= ( ( months_between (
      end_date,
      start_date
    ) / 12 ) + year_increment ) / year_increment!';
  
    dbms_output.put_line ( stmt );
  
    return stmt;
    
  end generate_years;
    
end date_mgr;
/


/* Inclusive or exclusive end dates? */
select * from date_mgr.generate_days (
  date'2021-01-01', 
  date'2021-01-31'
);



/* Every Friday in 2021 */ 
select * from date_mgr.generate_days (
  next_day ( date'2021-01-01' - 1, 'Friday' ), 
  date'2021-12-31', 
  7
);


select * from date_mgr.generate_days (
  next_day ( date'2021-01-01' - 1, 'Saturday' ), 
  date'2021-12-31', 
  7
);


/* Every other Monday */
select * from date_mgr.generate_days (
  next_day ( date'2021-01-01' - 1, 'Monday' ), 
  date'2021-12-31', 
  14
);


/* Every 10th day */
select * from date_mgr.generate_days (
  date'2021-01-01', 
  date'2021-12-31', 
  10
);

select * from date_mgr.generate_months (
  next_day ( date'2021-01-01' - 1, 'Monday' ), 
  date'2021-12-31'
);


/* Generate quarters */
select * from date_mgr.generate_months (
  date'2021-01-01', 
  date'2021-12-31', 
  3
);

/* 28th Feb - month end or 28th day? */
select * from date_mgr.generate_months (
  date'2021-01-28', 
  date'2021-12-31'
);

select * from date_mgr.generate_years (
  date'2020-01-01', 
  date'2022-12-31'
);


with stor as (
  select store_id, order_datetime
  from   co.orders o
  where  store_id = 23
), rws as (
  select min ( trunc ( order_datetime ) ) mn_dt,
         max ( trunc ( order_datetime ) ) mx_dt
  from   stor
)
  select dt, count ( order_datetime ) from (
    select *
    from   rws 
    cross join date_mgr.generate_days ( mn_dt, mx_dt )
  )
  left join stor
  on     dt <= order_datetime
  and    dt + 1 > order_datetime
  group  by dt
  order  by dt;



/*********************************




*********************************/


drop table calendar_dates
  cascade constraints purge;
create table calendar_dates (
  calendar_date date
    check ( calendar_date = trunc ( calendar_date ) )
    not null
    primary key,
  is_working_day integer
    check ( is_working_day in ( 0, 1 ) )
    not null,
  day_of_week varchar2(10 char)
) organization index;

insert into calendar_dates ( 
  calendar_date, is_working_day, day_of_week 
)
  select dt, 
         case
           when to_char ( dt, 'dy', 'nls_date_language = english' ) 
             in ( 'sat', 'sun' ) then 0
           else 1
         end,
         to_char ( dt, 'FMDay', 'nls_date_language = english' )
  from   generate_dates (
    date'2021-01-01', date'2021-12-31', 1
  );

/* Set UK public holidays to be non-working days */
update calendar_dates
set    is_working_day = 0
where  calendar_date in ( 
  date'2021-01-01',
  date'2021-04-02',
  date'2021-04-05',
  date'2021-05-03',
  date'2021-05-31',
  date'2021-08-30',
  date'2021-12-27',
  date'2021-12-28'
);

exec dbms_stats.gather_table_stats ( user, 'calendar_dates' ) ;

/* Get all Mondays */
select calendar_date from calendar_dates
where  day_of_week = 'Monday'
and    calendar_date between date'2021-01-01' and date'2021-12-31';


/* Get working Mondays */
select calendar_date from calendar_dates
where  day_of_week = 'Monday'
and    calendar_date between date'2021-01-01' and date'2021-12-31'
and    is_working_day = 1;

select calendar_date from calendar_dates
where  day_of_week = 'Monday'
and    calendar_date between date'2021-01-01' and date'2021-12-31'
and    is_working_day = 0;





select * from calendar_dates
where  calendar_date between trunc ( sysdate - 28 ) 
                     and trunc ( sysdate ) - 1;

select * from generate_dates (
  trunc ( sysdate - 28 ), trunc ( sysdate ) - 1
);

select * 
from   table(dbms_xplan.display_cursor(:LIVESQL_LAST_SQL_ID, format => 'BASIC LAST +ROWS'));