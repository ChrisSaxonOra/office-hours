


/* Datetime literals */
select date'2023-01-17' date_literal,
       timestamp'2023-01-17 14:00:00.123456789' ts_literal,
       timestamp'2023-01-17 14:00:00 Europe/London' tstz_literal
from   dual;






/* A quick note on TRUNC */
select sysdate full_datetime,
       trunc ( sysdate, 'HH24' ) to_hour_start, 
       trunc ( sysdate ) to_day_start,
       trunc ( sysdate, 'YYYY' ) to_year_start
from   dual;











alter session set nls_date_format = 'DD-MON-YYYY';

select * from hr.employees
where  hire_date >= '01-JAN-2005';

alter session set nls_date_format = 'YYYYMMDD';

select * from hr.employees
where  hire_date >= '01-JAN-2005';






/* Be explicit! Use DD-MON-YYYY, even though session has YYYYMMDD */
select * from hr.employees
where  hire_date >= to_date (
  '01-JAN-2005', 'DD-MON-YYYY'
);




/* ...but only on string values!
*/
select * from hr.employees
where  hire_date >= to_date (
  sysdate, 'DD-MON-YYYY'
);
/* This is really 
  to_date ( to_char ( sysdate, 'YYYYMMDD' ), 'DD-MON-YYYY' )
*/










/* Set the formats */
alter session set nls_date_format = ' "DT" DD-MON-YYYY HH24:MI ';
alter session set nls_timestamp_format = ' "TS" DD-MON-YYYY HH24:MI ';
alter session set nls_timestamp_tz_format = ' "TSTZ" DD-MON-YYYY HH24:MI TZH:TZM ';

select * from nls_session_parameters
where  parameter like '%DATE%' or parameter like '%TIMESTAMP%';





/* Can still be language problems! */
alter session set nls_date_language = 'Spanish';

select * from hr.employees
where  hire_date >= to_date (
  '01-JAN-2005', 'DD-MON-YYYY'
);



/* Spanish month names */
select sysdate from dual;




/* Fully specified */
select * from hr.employees
where  hire_date >= to_date (
  '01-JAN-2005', 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE = English' 
);


alter session set nls_date_language = 'English';



/* Handling data in unexpected/unwanted formats 
   Conversion error defaults - default must be in target format
*/
select to_date (
          '01-JAN-2005'
            default '99991231' on conversion error, 
          'YYYYMMDD'
        ) 
from dual;


/* Default has to match target format */
select to_date (
          '01-JAN-2005'
            default '31-DEC-9999' on conversion error, 
          'YYYYMMDD'
        ) 
from dual;





/* Multi-format tester */
create or replace function string_to_date ( 
  date_string varchar2 
) return date as
  return_date date;
begin
  return_date := case
    when validate_conversion ( date_string as date, 'DD-MON-YYYY' ) = 1 
    then 
      to_date ( date_string, 'DD-MON-YYYY' )
    when validate_conversion ( date_string as date, 'YYYYMMDD' ) = 1 
    then 
      to_date ( date_string, 'YYYYMMDD' )
    when validate_conversion ( date_string as date, 'MMDDYYYY' ) = 1 
    then 
      to_date ( date_string, 'MMDDYYYY' )
  end;
  
  if return_date is null then
    raise_application_error ( -20001, 'Date in unhandled format' );
  end if;
  
  return return_date;
end;
/

/* Multiformat conversion */
var search_date varchar2(20);
col :search_date format a12

exec :search_date := '01-JAN-2005'
select :search_date, count(*) from hr.employees
where  hire_date >= string_to_date ( :search_date );

exec :search_date := '20050101'
select :search_date, count(*) from hr.employees
where  hire_date >= string_to_date ( :search_date );






/* What's going to happen here? */
with rws ( date_string ) as (
  select '17-January-23'   from dual union all
  select '17~January~2023' from dual union all
  select '17-Jan-2023'     from dual union all
  select '17012023'        from dual
)
  select date_string, to_date ( 
           date_string default null on conversion error, 
           'DD-MM-YYYY' 
         ) dt
  from   rws;





/* ...use FX modifier to make it exact */
with rws ( date_string  ) as (
  select '17-January-23'   from dual union all
  select '17~January~2023' from dual union all
  select '17-Jan-2023'     from dual union all
  select '17012023'        from dual
)
  select date_string , 
         to_date ( 
           date_string  default null on conversion error , 
           'FXDD-MM-YYYY' 
         ) exact_match
  from   rws;
  
  


/* Converting to string with explicit format */
select hire_date nls_session_date, 
       to_char ( hire_date, 'IYYY-IW' ) iso_year_week, 
       to_char ( hire_date, 'DY ddth Month YEAR' ) spell_date, 
       to_char ( hire_date, 'j RM w"w" q"q"' ) julian_dy__roman_mnth__mnth_week__qtr
from   hr.employees;  




/* Time formats */
select to_char ( sysdate, 'hh24:mi:ss' ) hour_min_sec,
       to_char ( sysdate, 'sssss' ) seconds_in_day,
       to_char ( systimestamp, 'FF' ) fractional_seconds,
       to_char ( systimestamp, 'tzr tzh:tzm' ) time_zone
from   dual;





/* Convert date <-> timestamp */
select cast ( sysdate as timestamp ) ts, 
       /* Implicit session time zone */
       cast ( sysdate as timestamp with time zone ) tstz,
       /* Lose any fractional seconds and time zone */
       cast ( systimestamp as date ) dt
from   dual;






/* Interval literals */
select interval '1' day,
       interval '12:34:56.123456789' hour to second(9),
       interval '99-1' year(9) to month
from   dual;





/* to_*interval - no format masks! 
   Either SQL or ISO formats
*/
select to_dsinterval ( '01 00:00:00' ) one_day_sql,
       to_dsinterval ( 'P1D' ) one_day_iso,
       --
       to_dsinterval ( '00 12:34:56.789' ) hr_mi_s_sql,
       to_dsinterval ( 'PT12H34M56.789S' ) hr_mi_s_iso,
       --
       to_yminterval ( '99-1' ) yr_mth_sql,
       to_yminterval ( 'P99Y1M' ) yr_mth_iso
from   dual;






/* Numbers to intervals */
select numtodsinterval ( 1, 'day' ) one_day,
       numtodsinterval ( 86400, 'second' ) one_day_in_s,
       --
       numtodsinterval ( 12, 'hour' )
         + numtodsinterval ( 34, 'minute' )
         + numtodsinterval ( 56, 'second' ) time_hms,
       numtodsinterval ( 45296/86400, 'day' ) time_in_day,
       --
       numtoyminterval ( 1189, 'month' ) ym_in_months,
       numtoyminterval ( 99.0833, 'year' ) ym_in_years
from   dual;



/*****************************

         Arithmetic

*****************************/


/* Adding/subtracting durations */
with vals as (
  select date'2023-01-01' start_date,
         timestamp'2023-01-01 00:00:00' start_timestamp
  from   dual
), rws as (
  select start_date + ( level / 6 ) dt_plus_number, 
         start_date + numtodsinterval ( level / 6, 'day' ) dt_plus_interval,
         start_timestamp + ( level / 6 ) ts_plus_number,
         start_timestamp + numtodsinterval ( level / 6, 'day' ) ts_plus_interval
  from   vals
  connect by level <= 10
)
  select * from rws;
  
  
  
/* Subtracting datetimes */
with vals as (
  select date'2023-01-01' start_date,
         timestamp'2023-01-01 00:00:00' start_timestamp
  from   dual
), rws as (
  select start_date, start_timestamp,
         start_date + ( level / 6 ) dt,
         start_timestamp + numtodsinterval ( level / 6, 'day' ) ts
  from   vals
  connect by level <= 10
)
  select dt - start_date, 
         dt - start_timestamp,
         ts - start_timestamp,
         ts - start_date
  from   rws;



/* Get duration difference in seconds (UNIX epoch) */
select *
from   ( 
  select ( sysdate - date'1970-01-01' ) * 86400 dt_epoch,
         systimestamp at time zone 'UTC' - timestamp'1970-01-01 00:00:00 UTC' epoch_dsi
  from dual
) cross apply (
  select extract ( day from epoch_dsi ) * 86400 +
         extract ( hour from epoch_dsi ) * 3600 +
         extract ( minute from epoch_dsi ) * 60 +
         extract ( second from epoch_dsi ) ts_epoch
  from   dual
);
/* For cross apply see 
https://blog.jooq.org/lateral-is-your-friend-to-create-local-column-variables-in-sql/
*/




/* Can't extract hour/min/second from date */
select extract ( hour from sysdate ) from dual;







/* Now the real fun begins! 
   Adding months => can't specify in terms of (fixed) days 
*/
select date'2023-01-01' + 31 jan_dt_plus_31,
       date'2023-02-01' + 31 feb_dt_plus_31,
       timestamp'2023-01-01 00:00:00' + interval '31' day jan_ts_plus_31,
       timestamp'2023-02-01 00:00:00' + interval '31' day feb_ts_plus_31
from   dual;





/* Add months */
select add_months ( date'2023-01-01', 1 ) jan_dt_plus_1,
       add_months ( date'2023-02-01', 1 ) feb_dt_plus_1,
       timestamp'2023-01-01 00:00:00' + interval '1' month jan_ts_plus_1,
       timestamp'2023-02-01 00:00:00' + interval '1' month feb_ts_plus_1
from   dual;




/* So what happens at month end? */
select add_months ( date'2023-01-31', 1 ) jan_dt_plus_1,
       add_months ( date'2023-02-28', 1 ) feb_dt_plus_1
from   dual;





/* But beware for intervals! */
select timestamp'2023-01-31 00:00:00' + interval '1' month 
from   dual;






/* So we'll add month instead? */
select add_months ( timestamp'2023-01-31 00:00:00', 1 )
from   dual;




  
/* Add months to 28th */  
with rws as (
  select add_months ( date'2023-01-28', level - 1 ) dt
  from   dual
  connect by level <= 10
)
  select * from rws;
  
  

/* But what if we start with 28th Feb? */
with rws as (
  select add_months ( date'2023-02-28', level - 1 ) dt
  from   dual
  connect by level <= 10
)
  select * from rws;
  




/* Add to end of month
   Get start of month
   Add N months 
   Get last day in month 
*/
with rws as (
  select /* Get last day in month */
         last_day (  
           /* Add months on */
           add_months (
             /* Get start of month */
             trunc ( date'2023-01-31', 'mm' ), 
             level - 1 
           ) 
         ) dt
  from   dual
  connect by level <= 10
)
  select * from rws;
  
  





/* ...but it only returns DATEs! */
select trunc ( systimestamp, 'mm' ),
       last_day ( systimestamp )
from   dual;




  
  
/* Add to end of month 
   Add one day (1st next month)
   Add N month (1st Nth next month)
   Subtract one day (last day of Nth month)
*/
with rws as (
  select /* 1st next month */
         ( timestamp'2023-01-31 00:00:00' + interval '1' day )
         /* Add the months */
           + numtoyminterval ( level - 1, 'month' )  
         /* Subtract one day to go back to the end */
           - interval '1' day 
           ts
  from   dual
  connect by level <= 10
)
  select * from rws;
  
  
  

/* Check with end of Feb */
with rws as (
  select last_day (  
           add_months (
             trunc ( date'2023-02-28', 'mm' ), 
             level - 1 
           ) 
         ) dt,
         ( timestamp'2023-02-28 00:00:00' + interval '1' day )
           + numtoyminterval ( level - 1, 'month' )  
           - interval '1' day 
           ts
  from   dual
  connect by level <= 10
)
  select * from rws;



/* Months between dates */
with vals as (
  select date'2023-01-01' start_date
  from   dual
), rws as (
  select start_date, 
         add_months ( start_date, level - 1 ) month_date
  from   vals
  connect by level <= 10
)
  select months_between ( month_date, start_date ) 
  from   rws;





/* Months between dates - fractional with 31 day months */
with vals as (
  select date'2023-01-01' start_date from dual
), rws as (
  select start_date, 
         add_months ( start_date + 15, level - 1 ) month_date
  from   vals
  connect by level <= 10
)
  select month_date, 
         months_between ( month_date, start_date ) months,
         15 / 31 fraction
  from   rws;


/* Month & days? */
with vals as (
  select date'2023-02-28' start_date
  from   dual
), rws as (
  select start_date, start_date + level - 1 dt
  from   vals
  connect by level <= 10
)
  select dt, 
         months_between ( dt, start_date ),
         months_between ( dt, start_date ) * 31 days_between
  from   rws;



/* TS + YM interval - round up from 16th */
with vals as (
  select timestamp'2023-01-01 00:00:00' start_ts
  from   dual
), rws as (
  select start_ts, 
         start_ts + numtoyminterval ( level - 1, 'month' ) start_month, 
         start_ts + numtoyminterval ( level - 1, 'month' ) + interval '14 23:59:59' day to second mid_month_15, 
         start_ts + numtoyminterval ( level - 1, 'month' ) + interval '15' day mid_month_16
  from   vals
  connect by level <= 10
)
  select start_month,
         ( start_month - start_ts ) year to month start_ym, 
         mid_month_15, 
         ( mid_month_15 - start_ts ) year to month mid_15_ym, 
         mid_month_16, 
         ( mid_month_16 - start_ts ) year to month mid_16_ym
  from   rws;
  




/* Can add any compatible intervals... */
select interval '1' day + 
         interval '1' hour + 
         interval '1' minute + 
         interval '1' second + 
         interval '0.1' second ds_int, 
       interval '1' year + 
         interval '1' month ym_int
from   dual;



/* ...but YM & DS intervals are incompatible */
select interval '1' month + interval '1' day 
from   dual;




/****************************

         Time zones

****************************/

alter session set time_zone = 'Europe/London';

select sysdate, systimestamp, dbtimezone,
       current_date, current_timestamp, sessiontimezone
from   dual;



alter session set time_zone = 'Asia/Kolkata';

select sysdate, systimestamp, dbtimezone,
       current_date, current_timestamp, sessiontimezone
from   dual;


alter session set time_zone = 'UTC';

drop table t 
  cascade constraints purge;

/* Dealing with time zones */  
create table t (
  id      integer generated as identity,
  sess_tz varchar2(128),
  ts      timestamp,
  ts_tz   timestamp with time zone,
  ts_ltz  timestamp with local time zone
);

alter session set time_zone = 'Europe/London';

insert into t ( sess_tz, ts, ts_tz, ts_ltz )
with rws as (
  select timestamp'2023-01-01 00:00:00' ts from dual union all
  select timestamp'2023-09-01 00:00:00' ts from dual union all
  select timestamp'2023-01-01 00:00:00 Asia/Kolkata' ts from dual union all
  select timestamp'2023-09-01 00:00:00 Asia/Kolkata' ts from dual 
)
  select sessiontimezone, ts, ts, ts from rws;

alter session set time_zone = 'UTC';

insert into t ( sess_tz, ts, ts_tz, ts_ltz )
with rws as (
  select timestamp'2023-01-01 00:00:00' ts from dual union all
  select timestamp'2023-09-01 00:00:00' ts from dual union all
  select timestamp'2023-01-01 00:00:00 Asia/Kolkata' ts from dual union all
  select timestamp'2023-09-01 00:00:00 Asia/Kolkata' ts from dual 
)
  select sessiontimezone, ts, ts, ts from rws;

alter session set time_zone = 'Asia/Kolkata';

insert into t ( sess_tz, ts, ts_tz, ts_ltz )
with rws as (
  select timestamp'2023-01-01 00:00:00' ts from dual union all
  select timestamp'2023-09-01 00:00:00' ts from dual union all
  select timestamp'2023-01-01 00:00:00 Asia/Kolkata' ts from dual union all
  select timestamp'2023-09-01 00:00:00 Asia/Kolkata' ts from dual 
)
  select sessiontimezone, ts, ts, ts from rws;
  
commit;

alter session set time_zone = 'UTC';

select *
from   t
order  by id, ts_tz;

alter session set time_zone = 'Asia/Kolkata';

select *
from   t
order  by id, ts_ltz;


alter session set time_zone = 'UTC';

/* Add time zone to timestamp */
select from_tz ( timestamp'2023-01-01 00:00:00', 'Asia/Kolkata' ) ts_to_tstz,
       from_tz ( cast ( sysdate as timestamp ), 'Asia/Kolkata' ) dt_to_tstz
from   dual;




/* Must be timestamp WITHOUT time zone */
select from_tz ( systimestamp, 'Asia/Kolkata' ) ts_to_tstz
from   dual;






select from_tz ( cast ( systimestamp as timestamp ), 'Asia/Kolkata' ) ts_to_tstz
from   dual;



alter session set time_zone = 'UTC';

/* Convert one time zone to another */
select timestamp'2023-01-01 00:00:00 Asia/Kolkata' at time zone 'UTC' ts_to_tz,
       timestamp'2023-01-01 00:00:00' at local ts_to_local,
       /* Implict TS -> TSTZ with session time zone conversion! */
       timestamp'2023-01-01 00:00:00' at time zone 'UTC' tz_to_tz
from   dual;

alter session set time_zone = 'Asia/Kolkata';

select timestamp'2023-01-01 00:00:00 Asia/Kolkata' at time zone 'UTC' tz_to_tz,
       timestamp'2023-01-01 00:00:00' at local ts_to_local,
       /* Implict TS -> TSTZ with session time zone conversion! */
       timestamp'2023-01-01 00:00:00' at time zone 'UTC' ts_to_tz
from   dual;






/* TZ aware date => date conversion... */
select new_time ( date'2023-01-01', 'PST', 'GMT' ) dt_to_dt
from   dual;




/* ...but very limited zone support */
select new_time ( date'2022-01-01', 'PST', 'UTC' ) dt_to_dt
from   dual;





/* Daylight savings aware with TZ names */
select timestamp'2023-03-27 00:00:00 Europe/London' 
         - timestamp'2023-03-26 00:00:00 Europe/London' clocks_forward,
       timestamp'2023-03-27 00:00:00 +00:00' 
         - timestamp'2023-03-26 00:00:00 +00:00' clocks_not_forward,
       timestamp'2023-10-30 00:00:00 Europe/London' 
         - timestamp'2023-10-29 00:00:00 Europe/London' clocks_back,
       timestamp'2023-10-30 00:00:00 +00:00' 
         - timestamp'2023-10-29 00:00:00 +00:00' clocks_not_back
from   dual;



select timestamp'2023-06-01 00:00:00 Europe/London' - timestamp'2023-01-01 00:00:00 Europe/London' with_tz,
       timestamp'2023-06-01 00:00:00' - timestamp'2023-01-01 00:00:00' without_tz
from   dual;