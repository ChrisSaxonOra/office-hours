cl scr
set echo off
set feed off
drop table card_deck
  cascade constraints purge;

create table card_deck (
  card_id    integer,
  card_value varchar2(10),
  suit       varchar2(10),
  damaged    varchar2(1),
  notes      varchar2(50)
) ;

create index card_damaged_i
  on card_deck ( damaged );

insert into card_deck ( card_id, card_value, suit, damaged, notes )
  select level,
         case mod(rownum, 13)+1
           when 1 then 'Ace'
           when 11 then 'Jack'
           when 12 then 'Queen'
           when 13 then 'King'
           else to_char(mod(rownum, 13)+1)
         end case, 
         case ceil(rownum/13)
           when 1 then 'spades'
           when 2 then 'clubs'
           when 3 then 'hearts'
           when 4 then 'diamonds'
         end case, 
         case
           when rownum = 1 then 'Y'
           else 'N'
         end damaged, 
         case
           when rownum = 2 then 'SQL is awesome!'
           else dbms_random.string ( 'a', 50 )
         end notes
  from   dual
  connect by level <= 52
  order  by dbms_random.value;

commit;

select count(*) from card_deck
where  damaged = 'Y';

exec dbms_stats.gather_table_stats ( user, 'card_deck', options => 'gather auto' ) ;

set serveroutput off
alter session set statistics_level = all;

set feed on 
set echo on