drop table running_log cascade constraints purge;
alter session set nls_date_format = ' DD Mon YYYY ';

create table running_log ( 
  run_date       date not null,  
  time_in_s      int  not null, 
  distance_in_km int  not null 
);

begin  
  delete running_log;
  insert into running_log values (date'2022-03-01', 310, 1);  
  insert into running_log values (date'2022-03-02', 1700, 5);  
  insert into running_log values (date'2022-03-03', 319, 1);  
  insert into running_log values (date'2022-03-06', 1572, 5);  
  insert into running_log values (date'2022-03-07', 280, 1);  
  insert into running_log values (date'2022-03-10', 287, 1);  
  insert into running_log values (date'2022-03-11', 242, 1);  
  insert into running_log values (date'2022-03-13', 1535, 5); 
  commit;  
end; 
/

select * from running_log;


select * from running_log  
match_recognize (  
  order by run_date 
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs  
  all rows per match
  pattern ( one_km )  
  define  
    one_km as distance_in_km = 1
);


select * from running_log  
match_recognize (  
  order by run_date  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs  
  all rows per match
    with unmatched rows
  pattern ( one_km+ )  
  define  
    one_km as distance_in_km = 1
);


select * from running_log  
match_recognize (  
  order by distance_in_km  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs  
  all rows per match
    with unmatched rows
  pattern ( one_km+ )  
  define  
    one_km as distance_in_km = 1
);



select * from running_log  
match_recognize (  
  order by run_date  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs
  all rows per match
    with unmatched rows
  pattern ( one_km{2, 4} )  
  define  
    one_km as distance_in_km = 1
);


/****************************/


select * from running_log  
match_recognize (  
  order by run_date  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs
  all rows per match
    with unmatched rows
  pattern ( one_km five_km )  
  define  
    one_km as distance_in_km = 1,
    five_km as distance_in_km = 5
);


select * from running_log  
match_recognize (  
  order by run_date  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs
  all rows per match
    with unmatched rows
  pattern ( one_km+ five_km )  
  define  
    one_km as distance_in_km = 1,
    five_km as distance_in_km = 5
);



select * from running_log  
match_recognize (  
  order by run_date  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs
  all rows per match
  pattern ( one_km five_km one_km )  
  define  
    one_km as distance_in_km = 1,
    five_km as distance_in_km = 5
);



select * from running_log  
match_recognize (  
  order by run_date  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs
  all rows per match
    with unmatched rows
  after match skip to last one_km
  pattern ( one_km five_km one_km{0,1} )  
  define  
    one_km as distance_in_km = 1,
    five_km as distance_in_km = 5
);


/****************************/

select * from running_log  
match_recognize (  
  order by run_date  
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs
  all rows per match
  pattern ( short_run long_run )  
  define  
    short_run as distance_in_km between 0 and 4,
    long_run  as distance_in_km > 4
);


select * from running_log  
match_recognize (  
  order by distance_in_km, run_date 
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs,
    final avg ( time_in_s / distance_in_km ) as mean_pace,
    final sum ( distance_in_km ) as total_distance
  all rows per match
  pattern ( short_run+ | long_run+ )  
  define  
    short_run as distance_in_km between 0 and 4,
    long_run  as distance_in_km > 4
);



select * from running_log  
match_recognize (  
  order by distance_in_km, run_date 
  measures   
    classifier() as var, 
    match_number() as grp,  
    final count (*) as total_runs,
    avg ( time_in_s / distance_in_km ) as mean_pace,
    sum ( distance_in_km ) as total_distance
  all rows per match
  pattern ( short_run* | long_run+ )  
  define  
    short_run as distance_in_km between 0 and 4,
    long_run  as distance_in_km > 4
);