select count(*) from league_owner.games;

/* No access */
select count(*) from league_owner.locations;

/* Doesn't exist */
select count(*) from league_owner.players;












/* Can't insert or access procs */
insert into league_owner.players 
values ( 1, 'Tess Ting' );

select * from league_owner.games
where  league_owner.score_diff ( 
  home_team_score, away_team_score 
) >= 3;


alter session set current_schema = league_owner;

select count(*) from players;