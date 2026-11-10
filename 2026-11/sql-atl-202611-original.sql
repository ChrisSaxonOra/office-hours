@sql-atl-202611-setup.sql




/* Check data */
select * from activity_logs
order  by event_time;





/******************************

     Get yesterday's events

******************************/

select *
from   activity_logs
where  true 
-- and    datediff ( day, event_time, sysdate ) = 1
-- and    event_time >= trunc ( sysdate ) - 1
-- and    event_time <  trunc ( sysdate ) 
/







/* Now get last month's data */
select *
from   activity_logs
where  true 
-- and    datediff ( month, event_time, sysdate ) = 1
-- and    event_time >= add_months ( trunc ( sysdate, 'mm' ), -1 )
-- and    event_time <  add_months ( trunc ( sysdate, 'mm' ), 0 )
/







/* DATEADD (23.26.3) simplifies date arithmetic */
select *
from   activity_logs
/* Last month's data */
where  event_time >= dateadd ( 'month', -1, trunc ( sysdate, 'mm' ) )
and    event_time <  dateadd ( 'month',  0, trunc ( sysdate, 'mm' ) )
/

select *
from   activity_logs
/* Yesterday's data */
where  event_time >= dateadd ( 'day', -1, trunc ( sysdate, 'dd' ) )
and    event_time <  dateadd ( 'day',  0, trunc ( sysdate, 'dd' ) )
/




/******************************

         Pivot by hour

******************************/


-- PIVOT vs FILTER 
with activity_hours as (
  select extract ( hour from event_time ) hr
  from   activity_logs
)  
select 
-- *
/*  count (*) filter ( where hr = 0 ),
  count (*) filter ( where hr = 1 ),
  count (*) filter ( where hr = 2 ),
  count (*) filter ( where hr = 3 )  /**/
from activity_hours /*
pivot ( 
  count(*) for 
  hr in ( 0, 1, 2, 3 )
) /**/
/








/* Show hourly activity and unique user counts */
with activity_hours as (
  select extract ( hour from event_time ) hr, user_id
  from   activity_logs
)  
select 
*
/*  count (*) filter ( where hr = 0 ),
  count (*) filter ( where hr = 1 ),
  count (*) filter ( where hr = 2 ),
  count (*) filter ( where hr = 3 ), 
  count ( distinct user_id ) filter ( where hr = 0 ),
  count ( distinct user_id ) filter ( where hr = 1 ),
  count ( distinct user_id ) filter ( where hr = 2 ),
  count ( distinct user_id ) filter ( where hr = 3 )  /**/
from activity_hours /*
pivot ( 
  count(*) activities, count ( distinct user_id ) users for
  hr in ( 0, 1, 2, 3 )
) /**/
/



/* Day segment and device type counts => FILTER */
with activity_hours as (
  select extract ( hour from event_time ) hr, device_type
  from   activity_logs
)  
select 
  count (*) filter ( where device_type = 'mobile' ) mobile,
  count (*) filter ( where device_type = 'desktop' ) desktop,
  count (*) filter ( where device_type = 'tablet' ) tablet,
  count (*) filter ( where hr < 8 or hr >= 20 ) night,
  count (*) filter ( where hr between 8 and 11 ) morning,
  count (*) filter ( where hr between 12 and 16 ) afternoon,
  count (*) filter ( where hr between 17 and 19  ) evening
from activity_hours; 






/******************************

      30 minute sessions

******************************/


-- SESSIONS windowing table function
-- Group rows within 30 minutes of the last activity per user
select user_id, window_start, window_end, count(*) session_events
from   sessions ( 
  activity_logs partition by user_id, 
  columns ( event_time ),
  interval '30' minute
)
group  by all
order  by user_id, window_start;



-- MATCH_RECOGNIZE pattern matching
-- Group rows within 30 minutes of the last activity per user
select * 
from   activity_logs 
match_recognize (
  partition by user_id 
  order by event_time
  measures 
    first ( event_time ) as start_time,
    last ( event_time ) as end_time,
    count(*) as session_events
  pattern ( init within_30* )
  define 
    within_30 as event_time <= dateadd ( 'minute', 30, prev ( event_time ) )
);






/* Start sessions at login? */




select * 
from   activity_logs 
match_recognize (
  partition by user_id 
  order by event_time
  measures 
    first ( event_time ) as start_time,
    last ( event_time ) as end_time,
    count(*) as session_events
  pattern ( init within_30* )
  define 
    /* login is first activity in session */
    init as activity_type = 'login',
    within_30 as event_time <= dateadd ( 'minute', 30, prev ( event_time ) )
);




/******************************

        Reusing logic

******************************/

-- create or replace view activity_yesterday as
-- create or replace macro activity_yesterday as
-- ##activity query##

select * from activity_yesterday ()
/




-- create or replace view hourly_activity_count as
-- create or replace macro hourly_activity_count as
-- ##hour query##

select * from hourly_activity_count ()
/






-- create or replace view thirty_min_sessions as
-- create or replace macro thirty_min_sessions as
-- ##session query##

select * from thirty_min_sessions ()
/





/* But what if we want to vary session lengths? */









/* You can parameterize macros! 
   Custom session length */
create or replace macro n_min_sessions ( n integer ) as
select * 
from   activity_logs 
match_recognize (
  partition by user_id 
  order by event_time
  measures 
    first ( event_time ) as start_time,
    last ( event_time ) as end_time,
    count(*) as session_events
  pattern ( init within_30* )
  define 
    init,
    within_30 as event_time <= dateadd ( 'minute', n, prev ( event_time ) )
);

select * from n_min_sessions ( 5 );
select * from n_min_sessions ( 60 );





/******************************

             FIN

******************************/

