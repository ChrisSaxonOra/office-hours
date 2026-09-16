

/* Select without FROM! */
select user, sys_context ( 'userenv', 'proxy_user' );


/* Trusty old dual is still available */
select user, sys_context ( 'userenv', 'proxy_user' ) from dual;










/*********************************************

            Create domains
       
Define permitted values for common attributes 

*********************************************/
create domain if not exists surrogate_id as 
  --
  integer not null
  ---
  annotations ( PK );
  
  
  
  
  
  
create domain if not exists game_score as 
  integer 
  --
  constraint zero_or_higher
    check ( game_score >= 0 )
  --
  order game_score * -1
  --
  annotations ( Title 'Points earned during games' );







create domain if not exists game_duration as 
  interval day(0) to second(0)
  --
  constraint gt_zero_duration
    check ( game_duration > interval '0' hour )
  --
  display to_char (
    extract ( hour from game_duration ) * 60 + 
    extract ( minute from game_duration ) + 
    round ( extract ( second from game_duration ) / 60 ) 
  ) || ' minutes' 
  --
  annotations ( Title 'Length of matches' );






create domain if not exists ci_name as 
  varchar2(255)
  --
  collate binary_ci
  --
  annotations ( Title 'Case insensitive names' );





/*****************************

       Create tables 

*****************************/

create table if not exists locations (
  location_id   surrogate_id
    constraint location_pk primary key,
  location_name varchar2(255) domain ci_name
    not null
    annotations ( Display 'Stadium name' )
) annotations ( Display 'Sporting stadiums' );

desc locations;






/* Table exists => do nothing; NOT create or replace */
create table if not exists locations (
  different_colulmns json 
) annotations ( Display 'Sporting stadiums' );

desc locations;







create table if not exists teams (
  team_id   int domain surrogate_id
    constraint teams_pk primary key
    annotations ( Display 'Team ID' ),
  --
  team_name varchar2(255) domain ci_name
    constraint teams_c unique not null
    annotations ( UC ),
  --
  home_stadium 
    references locations ( location_id ) not null
    annotations ( FK 'locations' )
) annotations ( Display 'Team details' );
  
  
  
  
  
  
  
create table if not exists games (
  home_team_id          references teams ( team_id ) not null,
  away_team_id          references teams ( team_id ) not null,
  location_id           references locations ( location_id ) not null,
  game_start_time       timestamp not null,
  scheduled_game_length game_duration not null,
  actual_game_length    game_duration,
  home_team_score       integer,
  away_team_score       integer,
  constraint games_pk 
    primary key ( home_team_id, away_team_id, game_start_time ),
  constraint games_location_u 
    unique ( location_id, game_start_time )
);




/* Check the domains */
select table_name, column_name, domain_name, 
       data_type, tc.nullable, search_condition_vc
from   user_tab_cols tc
left join ( 
  select c.table_name, column_name, search_condition_vc
  from   user_constraints c
  join   user_cons_columns cc
  on     c.table_name = cc.table_name
  and    c.constraint_name = cc.constraint_name
  where  c.constraint_type = 'C' and search_condition_vc not like '%NOT NULL%'
  and    c.table_name in ( 'GAMES', 'TEAMS', 'LOCATIONS' )
) cs
using  ( table_name, column_name )
where  table_name in ( 'GAMES', 'TEAMS', 'LOCATIONS' )
order  by table_name, column_id;








/* Whooops, we forgot to use the score domains! */
alter table games
  modify ( 
    home_team_score domain game_score,  
    away_team_score domain game_score 
  );




/* Check the domains again */
select table_name, column_name, domain_name, 
       data_type, tc.nullable, search_condition_vc
from   user_tab_cols tc
left join ( 
  select c.table_name, column_name, search_condition_vc
  from   user_constraints c
  join   user_cons_columns cc
  on     c.table_name = cc.table_name
  and    c.constraint_name = cc.constraint_name
  where  c.constraint_type = 'C' and search_condition_vc not like '%NOT NULL%'
  and    c.table_name in ( 'GAMES', 'TEAMS', 'LOCATIONS' )
) cs
using  ( table_name, column_name )
where  table_name in ( 'GAMES', 'TEAMS', 'LOCATIONS' )
order  by table_name, column_id;






/* View the annotations details */
select object_name, column_name, annotation_name, annotation_value
from   user_annotations_usage
where  object_name in ( 'LOCATIONS', 'TEAMS', 'GAMES' )
order  by object_name, annotation_name;




/* Add the annotations for GAMES */
alter table if exists games 
  modify (
    home_team_id          annotations ( FK 'teams', PK ),
    away_team_id          annotations ( FK 'teams', PK ),
    location_id           annotations ( FK 'locations', UC ),
    game_start_time       annotations ( UC, PK, Display 'Kick-off time' ),
    scheduled_game_length annotations ( Display 'Scheduled length' ),
    actual_game_length    annotations ( Display 'Time played' ),
    home_team_score       annotations ( Display 'Home team goals' ),
    away_team_score       annotations ( Display 'Away team goals' )
);



/* Check the display annotations */
select object_name, column_name, annotation_value 
from   all_annotations_usage
where  annotation_name = 'DISPLAY';



/* Find the FKs via annotations */
select object_name, column_name, annotation_value 
from   all_annotations_usage
where  annotation_name = 'FK';




/* But why not just use comments? */



/* How to handle multiple attributes with comments? */
comment on column teams.team_id is
  '[ { "name" : "PK" }, { "name" : "DISPLAY", "value" : "Team ID" } ]';
  
  
  
  

/* More types supported */
create index game_home_team_i on
  games ( home_team_id ); 
  
comment on index game_home_team_i is 
  'This throws an error';

alter index game_home_team_i
  annotations ( FK 'index' );



create domain currency as (
  amount as number, currency_code as char(3 char)
);



/**************************

       Data Load

**************************/

/* Single row inserts 
  - Slow if adding many rows
  - Fiddly if you need to change column list
insert into locations values ( 1, 'Winner stadium' );
insert into locations values ( 2, 'Big park' );
insert into locations values ( 3, 'Loser road' );
insert into locations values ( 4, 'Small street' );
insert into locations values ( 5, 'Old town lane' ); 
insert into locations values ( 6, 'Giant stadium' );
*/






/* Table values constructor - insert many rows in one statement */
insert into locations ( location_id, location_name )
values ( 1, 'Winner stadium' ), 
       ( 2, 'Big park' ), 
       ( 3, 'Loser road' ), 
       ( 4, 'Small street' ), 
       ( 5, 'Old town lane' ), 
       ( 6, 'Giant stadium' );
       
      
      
      
/* TVC to generate data - teams list */
declare
  v varchar2(100);
begin
merge into teams t
using ( 
select * from ( 
  values ( 1, 'Champions United', 1 ), 
         ( 2, 'Runner-up City', 2 ), 
         ( 3, 'Relegated Athletic', 3 ), 
         ( 4, 'Underdogs United', 4 ), 
         ( 5, 'Midtable Town', 5 ), 
         ( 6, 'Upstart FC', 6 ) 
) t ( team_id, team_name, home_stadium )
) v
on ( t.team_id = v.team_id )
when not matched then insert values ( v.team_id, v.team_name, v.home_stadium )
returning old team_name into v; 
end;
/
       
       
       
       
/* Insert TVC data */
insert into teams ( team_id, team_name, home_stadium ) 
select team_id, team_name, home_stadium from ( 
  values ( 1, 'Champions United', 1 ), 
         ( 2, 'Runner-up City', 2 ), 
         ( 3, 'Relegated Athletic', 3 ), 
         ( 4, 'Underdogs United', 4 ), 
         ( 5, 'Midtable Town', 5 ), 
         ( 6, 'Upstart FC', 6 ) 
) t ( team_id, team_name, home_stadium )
join  locations 
on    home_stadium = location_id;




/* Insert match data */
insert into games ( 
  home_team_id, away_team_id, location_id, 
  game_start_time, scheduled_game_length
)
with game_details as (
  select 
    floor ( systimestamp - 42, 'iw' ) + interval '6 15' day to hour first_date,
    interval '90' minute scheduled_game_length 
), all_games as (
  select home.team_id home_team_id, away.team_id away_team_id, loca.location_id,
         scheduled_game_length, first_date
  from   teams home
  join   teams away
  on     home.team_id <> away.team_id
  join   locations loca
  on     loca.location_id = home.home_stadium
  cross join game_details
  order  by dbms_random.value
)
  select home_team_id, away_team_id, location_id, 
         first_date + 
           numtodsinterval ( 
             ( floor ( ( rownum - 1 ) / 2 ) * 7 ) +
               ( case mod ( rownum, 2 ) when 0 then 6 else 7 end ), 
             'day' 
           ) start_date,
         scheduled_game_length
  from   all_games a
  order  by start_date;

commit;





/* Check the data */
/* Case-insensitive search from domain */
select * from locations
where  location_name like '%STADIUM%';




select * from teams
where  team_name like '%united';




select home_team_id, away_team_id, location_id,
       scheduled_game_length
from   games g;





/* Use domain formatting for duration */
select home_team_id, away_team_id, location_id,
       scheduled_game_length,
       domain_display ( scheduled_game_length ) game_minutes
from   games g;






/*****************************

        Enter results

*****************************/

/* Can't have negative scores => constraint from domain (23c) */
update games 
set    home_team_score = -1;





/* Enter some results */
update games
set    home_team_score = floor ( dbms_random.value ( 0, 5 ) ),
       away_team_score = floor ( dbms_random.value ( 0, 5 ) ),
       actual_game_length = 
         scheduled_game_length 
           + numtodsinterval ( dbms_random.value ( 0, 10 ), 'minute' )
where  game_start_time < systimestamp;

commit;






/* Report total time played/month */
select trunc ( game_start_time, 'mm' ) games_month, 
       actual_game_length
from   games
group  by trunc ( game_start_time, 'mm' );







/* Sum over interval; group by alias; floor & ceil for datetimes (23c) */
select floor ( game_start_time, 'mm' ) games_month, 
       sum ( actual_game_length ) actual_duration, 
       floor ( sum ( actual_game_length ), 'hh' ) round_down_hour, 
       ceil ( sum ( actual_game_length ), 'mi' ) round_up_minute
from   games
group  by games_month;







/* View results; use domain sorting */
select game_start_time,
       home.team_name, home_team_score, 
       away.team_name, away_team_score,
       domain_order ( home_team_score ) home_sort,
       domain_order ( away_team_score ) away_sort
from   games
join   teams home
on     home_team_id = home.team_id
join   teams away
on     away_team_id = away.team_id
where  game_start_time < systimestamp
order  by domain_order ( home_team_score ),
          domain_order ( away_team_score );





-- Champions United moves to new home stadium; 
-- update their future home games to this new location
insert into locations 
  values ( 7, 'New stadium' );

update teams
set    home_stadium = 7
where  team_id = 1;

commit;
/* Need to update future games to new location */




/* Correlated update to change the locations */
update games g
set    g.location_id = ( 
          select t.home_stadium from teams t
          where  g.home_team_id = t.team_id
          and    t.team_id = 1
       ),
       g.game_start_time = g.game_start_time + interval '1' hour         
where  g.home_team_id = 1
and    g.game_start_time > systimestamp;  
/* But what's changed? */

rollback;



set serveroutput on
declare
  type game_changes is record (
    away_team_id   integer,
    old_start_time timestamp,
    new_start_time timestamp,
    old_location   integer,
    new_location   integer
  );
  type game_changes_arr 
    is table of game_changes
    index by pls_integer;
  
  away_teams dbms_sql.number_table;
  game_start_times dbms_sql.timestamp_table;
  
  changes game_changes_arr;
begin

  /* 
     Direct join to get new home location
     OLD/NEW returning clauses to find changed values 
   */
  update games g
  set    g.location_id = team.home_stadium,
         g.game_start_time = g.game_start_time + interval '1' hour
  from   teams team
  where  g.home_team_id = team.team_id
  and    g.game_start_time > systimestamp
  and    team.team_id = 1
  returning 
    new away_team_id, 
    old game_start_time, 
    game_start_time, --defaults to new
    old location_id, 
    new location_id
  bulk collect into changes;
  
  
  
  
  
  /* Iterate through the changes and display them (21c) */
  for game in values of changes loop
    dbms_output.put_line ( 
      game.away_team_id || ' game on ' ||
      game.old_start_time || ' at ' ||
      game.old_location || ' moved to ' ||
      game.new_start_time || ' at ' ||
      game.new_location     
    );
  end loop;
  
  
  
  
  
  /* Convert change array to JSON (23c) */
  dbms_output.put_line ( 
    json_serialize ( 
      json ( changes ) returning varchar2 pretty 
    )
  );
  
  
end;
/




/* 
   Function to say if home team won
*/
create or replace function home_win (
  home_score int, away_score int
)
  return boolean as
begin
  return home_score > away_score;
end home_win;
/





/* But to use in SQL you needed a wrapper function */
with function home_win_yn (
  home_score int, away_score int
)
  return varchar2 as 
begin
  return case 
    when home_win ( home_score, away_score) then 'Y'
    else 'N'
  end;
end;
select * from games
where  home_win_yn ( home_team_score, away_team_score ) = 'Y';
/





/* No more! You can use Boolean in SQL! */
select * from games
where  home_win ( home_team_score, away_team_score ) is true;






/* Lots of Boolean conversions */
select * from games
where  home_win ( home_team_score, away_team_score ) in ( true, 'Y', 'TRUE', 1, 'ON' );

       
       
       

/* Can select boolean expressions */
select 
  true, 
  1 = 2, 
  exists ( select null from games );






/* Add result flags as boolean virtual columns */
alter table games
  add ( 
    is_finished boolean 
      as ( actual_game_length is not null ),
    is_home_win boolean 
      as ( actual_game_length is not null and home_team_score > away_team_score ),
    is_draw boolean 
      as ( actual_game_length is not null and home_team_score = away_team_score )
  );
  
  
  
  
  
/* Return boolean values */
select is_home_win, is_draw, count(*)
from   games
where  is_finished --is true
group  by is_home_win, is_draw
order  by is_home_win, is_draw;







/* Function to find (absolute) goal difference */
create or replace function score_diff (
  home_score int, away_score int
)
  return int deterministic as
begin
  return abs ( home_score - away_score );
end score_diff;
/
;



/* View the plan */
select * from games
where  score_diff ( home_team_score, away_team_score ) >= 3;






/* Faster = true! */
alter session set sql_transpiler = 'ON';



select * from games
where  score_diff ( home_team_score, away_team_score ) >= 3;
/* View the plan */





/* Transpiling only for pure functions with no SQL statements or PL/SQL */
create or replace function score_diff (
  home_score int, away_score int
)
  return int deterministic as
  dummy dual%rowtype;
begin
  return abs ( home_score - away_score );
end score_diff;
/
;
select * from games
where  score_diff ( home_team_score, away_team_score ) >= 3;






/*************************

    Reporting access

*************************/

grant read on games -- READ => SELECT without FOR UPDATE
  to reporting_user;
  






/* Give reporting user query privileges 
   on all league_owner tables */  
grant read any table
  on schema league_owner 
  to reporting_user;
/* Run reporting queries */






/* Create new table - automatically have access! */
create table players (
  player_id   surrogate_id primary key,
  player_name varchar2(255) not null
);






/* Enable INSERT into every table */
grant 
  insert any table, 
  execute any procedure
  on schema league_owner 
  to reporting_user;
  
/* Disable INSERT into every table */  
revoke 
  insert any table, 
  execute any procedure
  on schema league_owner 
  from reporting_user;
  
  
merge into teams
