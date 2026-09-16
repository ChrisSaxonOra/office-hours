alter session set nls_date_format = '  DD-MON-YYYY  ';
set echo off
drop table running_log
  cascade constraints purge;
drop table meeting_attendees
  cascade constraints purge;
drop table calendar_dates
  cascade constraints purge;

create table calendar_dates ( dt primary key ) as 
  select date'2019-12-31' + level dt 
  from   dual
  connect by level <= 366;  

create table running_log ( 
  run_date       date not null,  
  time_in_s      int  not null, 
  distance_in_km int  not null 
);

begin  
  insert into running_log values (date'2020-04-01', 310, 1);  
  insert into running_log values (date'2020-04-02', 1600, 5);  
  insert into running_log values (date'2020-04-03', 3580, 11);  
  insert into running_log values (date'2020-04-06', 1550, 5);  
  insert into running_log values (date'2020-04-07', 300, 1);  
  insert into running_log values (date'2020-04-10', 280, 1);  
  insert into running_log values (date'2020-04-13', 1530, 5);  
  insert into running_log values (date'2020-04-14', 295, 1);  
  insert into running_log values (date'2020-04-15', 292, 1);  
  
  insert into running_log values (date'2020-04-17', 1510, 5);  
  insert into running_log values (date'2020-04-18', 290, 1);  
  insert into running_log values (date'2020-04-19', 300, 1);  
  insert into running_log values (date'2020-04-20', 1545, 5);  
  insert into running_log values (date'2020-04-21', 595, 2);  
  insert into running_log values (date'2020-04-22', 280, 1);  
  commit;  
end; 
/



create table meeting_attendees (
  attendee_id integer
    not null,
  start_date date
    not null,
  end_date date,
  primary key ( 
    attendee_id, start_date
  )
);

insert into meeting_attendees 
  values ( 1, date'2020-06-17' + 9/24, date'2020-06-17' + 10/24 );
insert into meeting_attendees 
  values ( 1, date'2020-06-17' + 10/24, date'2020-06-17' + 10.5/24 );
insert into meeting_attendees 
  values ( 1, date'2020-06-17' + 11/24, date'2020-06-17' + 13/24 );
insert into meeting_attendees 
  values ( 1, date'2020-06-17' + 16/24, date'2020-06-17' + 17/24 );
  
insert into meeting_attendees 
  values ( 2, date'2020-06-17' + 9/24, date'2020-06-17' + 12/24 );
insert into meeting_attendees 
  values ( 2, date'2020-06-17' + 12.5/24, date'2020-06-17' + 13/24 );
insert into meeting_attendees 
  values ( 2, date'2020-06-17' + 13/24, date'2020-06-17' + 14/24 );
insert into meeting_attendees 
  values ( 2, date'2020-06-17' + 15/24, date'2020-06-17' + 17/24 );
  
commit;
set echo on
cl scr