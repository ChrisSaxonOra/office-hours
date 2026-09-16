
drop table calendar_dates
  cascade constraints purge;
drop table tickets
  cascade constraints purge;
drop table priorities
  cascade constraints purge;
cl scr  
CREATE TABLE calendar_dates (
    calendar_date        DATE NOT NULL
      check ( calendar_date = trunc ( calendar_date ) ),
    is_working_day       CHAR(1) NOT NULL,
    business_start_hour  INTEGER,
    business_close_hour  INTEGER
);

ALTER TABLE calendar_dates ADD CONSTRAINT calendar_dates_pk 
  PRIMARY KEY ( calendar_date );

CREATE TABLE priorities (
    priority_id          INTEGER NOT NULL,
    sla_hours            INTEGER NOT NULL,
    business_hours_only  CHAR(1) NOT NULL
);

ALTER TABLE priorities ADD CONSTRAINT priorities_pk PRIMARY KEY ( priority_id );

CREATE TABLE tickets (
    ticket_id        INTEGER NOT NULL,
    priority_id      INTEGER NOT NULL,
    raised_datetime  DATE NOT NULL,
    closed_datetime  DATE
);

ALTER TABLE tickets ADD CONSTRAINT tickets_pk PRIMARY KEY ( ticket_id );

ALTER TABLE tickets
    ADD CONSTRAINT tickets_priorities_fk FOREIGN KEY ( priority_id )
        REFERENCES priorities ( priority_id );
        
insert into priorities values ( 1, 4, 'N' );
insert into priorities values ( 2, 8, 'N' );
insert into priorities values ( 3, 22, 'Y' );
insert into priorities values ( 4, 44, 'Y' );
insert into priorities values ( 5, 55, 'Y' );


insert into calendar_dates
with dates as (
  select date'2009-12-31' + rownum dt
  from   dual
  connect by level <= 7300
)
  select dt, 
         case to_char ( dt, 'dy' )
           when 'sat' then 'N'
           when 'sun' then 'N'
           else 'Y'
         end, 
         case to_char ( dt, 'dy' )
           when 'sat' then null
           when 'sun' then null
           else 7
         end, 
         case to_char ( dt, 'dy' )
           when 'sat' then null
           when 'sun' then null
           else 18
         end
  from   dates;
  
insert into tickets values ( 3000, 3, timestamp'2020-04-08 12:00:00', null );
insert into tickets values ( 3001, 3, timestamp'2020-04-08 16:00:00', null );
insert into tickets values ( 4000, 4, timestamp'2020-04-08 12:00:00', null );
insert into tickets values ( 4001, 4, timestamp'2020-04-08 09:30:00', null );
insert into tickets values ( 4002, 4, timestamp'2020-04-08 16:00:00', null );

commit;





select * from tickets;









/* Generate dates */
select * 
from   tickets t
join   calendar_dates d
on     trunc ( raised_datetime ) <= calendar_date
and    raised_datetime + 20 > calendar_date
join   priorities p
on     t.priority_id = p.priority_id
where  p.business_hours_only = 'Y'
and    ticket_id = 4000;



/* Calculate working hours */
with days as (
  select 
    t.*,
    sum (
      ( calendar_date + ( business_close_hour / 24 ) ) -
      greatest (
        ( calendar_date + ( business_start_hour / 24 ) ) ,
         raised_datetime
      )
    ) over ( 
      partition by ticket_id
      order  by calendar_date
    ) * 24 tot,
    sum (
      ( calendar_date + ( business_close_hour / 24 ) ) -
      greatest (
        ( calendar_date + ( business_start_hour / 24 ) ) ,
        raised_datetime
      )
    ) over ( 
      partition by ticket_id
      order  by calendar_date
        rows between unbounded preceding and 1 preceding
    ) * 24 prev_tot, d.*, sla_hours
  from  tickets t
  join  calendar_dates d
  on    trunc ( raised_datetime ) <= calendar_date
  and   raised_datetime + 20 > calendar_date
  join  priorities p
  on    t.priority_id = p.priority_id
  where p.business_hours_only = 'Y'
  and    ticket_id = 4000
)
  select *
  from   days
  where  sla_hours >= prev_tot 
  and    sla_hours < tot;
  
  



with days as (
  select 
    t.*,
    sum (
      ( calendar_date + ( business_close_hour / 24 ) ) -
      greatest (
        ( calendar_date + ( business_start_hour / 24 ) ) ,
         raised_datetime
      )
    ) over ( 
      partition by ticket_id
      order  by calendar_date
    ) * 24 tot,
    sum (
      ( calendar_date + ( business_close_hour / 24 ) ) -
      greatest (
        ( calendar_date + ( business_start_hour / 24 ) ) ,
        raised_datetime
      )
    ) over ( 
      partition by ticket_id
      order  by calendar_date
        rows between unbounded preceding and 1 preceding
    ) * 24 prev_tot, d.*, sla_hours
  from  tickets t
  join  calendar_dates d
  on    trunc ( raised_datetime ) <= calendar_date
  and   raised_datetime + 20 > calendar_date
  join  priorities p
  on    t.priority_id = p.priority_id
  where p.business_hours_only = 'Y'
)
  select ticket_id,
         priority_id,
         raised_datetime,
         calendar_date + ( business_start_hour / 24 ) + 
           ( ( sla_hours - prev_tot ) / 24 ) breach_datetime,
         round ( prev_tot, 1 ) prev_tot, round ( tot, 1 ) tot,
         sla_hours
  from   days d
  where  sla_hours >= prev_tot 
  and    sla_hours < tot
  order  by ticket_id;
  
  
  
  
/* Early finish on Good Friday */
update calendar_dates
set    is_working_day = 'Y', 
       business_start_hour = 7, 
       business_close_hour = 12
where  calendar_date in ( date '2020-04-10' );




 
/* Good Friday & Easter Monday non-working days */ 
update calendar_dates
set    is_working_day = 'N', 
       business_start_hour = null, 
       business_close_hour = null
where  calendar_date in ( date '2020-04-10', date '2020-04-13' );






















truncate table tickets;

insert into tickets
with rws as (
  select mod ( level, 5 ) + 1 priority,
         sysdate - floor ( level / 100 ) - ( mod ( level, 24 ) / 24 ) dt
  from   dual
  connect by level <= 10000
)
  select row_number() over ( order by dt ), priority, dt, 
         case round (  mod ( sin ( 1 / row_number() over ( order by dt desc ) ) * 100, 7 ) ) 
           when 0 then dt + ( priority / 24 )
         end
  from   rws
  order  by dt;
  
exec dbms_stats.gather_table_stats ( user, 'tickets' ) ;
exec dbms_stats.gather_table_stats ( user, 'calendar_dates' ) ;
exec dbms_stats.gather_table_stats ( user, 'priorities' ) ;

create index ticket_dt_i on tickets ( raised_datetime ); 
drop index ticket_i;
create index ticket_i on tickets ( raised_datetime, priority_id, ticket_id );
create index ticket_i on tickets ( closed_datetime, raised_datetime, priority_id, ticket_id );
create index priority_hours on priorities ( business_hours_only, priority_id );



with possible_tickets as (
  select raised_datetime, priority_id, ticket_id
  from   tickets
  where  closed_datetime is null
), days as (
  select 
    t.*,
    sum (
      ( calendar_date + ( business_close_hour / 24 ) ) -
      greatest (
        ( calendar_date + ( business_start_hour / 24 ) ) ,
         raised_datetime
      )
    ) over ( 
      partition by ticket_id
      order  by calendar_date
    ) * 24 tot,
    sum (
      ( calendar_date + ( business_close_hour / 24 ) ) -
      greatest (
        ( calendar_date + ( business_start_hour / 24 ) ) ,
        raised_datetime
      )
    ) over ( 
      partition by ticket_id
      order  by calendar_date
        rows between unbounded preceding and 1 preceding
    ) * 24 prev_tot, d.*, sla_hours
  from  possible_tickets t
  join  calendar_dates d
  on    trunc ( raised_datetime ) <= calendar_date
  and   raised_datetime + 20 > calendar_date
  join  priorities p
  on    t.priority_id = p.priority_id
  where p.business_hours_only = 'Y'
--  and   t.raised_datetime >= sysdate - 20
  and   d.calendar_date between sysdate - 20 and sysdate + 20
), all_hours as (
  select t.*,
         t.raised_datetime + ( sla_hours / 24 ) breach_datetime
  from   possible_tickets t
  join   priorities p
  on     t.priority_id = p.priority_id
  where  p.business_hours_only = 'N'
), business_hours as (
  select ticket_id,
         priority_id,
         raised_datetime,
         calendar_date + ( business_start_hour / 24 ) + 
           ( ( sla_hours - prev_tot ) / 24 ) breach_datetime,
         prev_tot, tot
  from   days d
  where  sla_hours >= prev_tot 
  and    sla_hours < tot
)
  select ticket_id, priority_id, raised_datetime, breach_datetime 
  from   all_hours
  where  breach_datetime < trunc ( sysdate ) + 1
  union all
  select ticket_id, priority_id, raised_datetime, breach_datetime 
  from   business_hours
  where  breach_datetime < trunc ( sysdate ) + 1
  order  by breach_datetime;
  