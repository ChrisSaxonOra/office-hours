drop table t 
  cascade constraints purge;
drop table tchild1
  cascade constraints purge;
drop table tchild2
  cascade constraints purge;

exec dbms_random.seed ( 0 );
  
create table t as  
  select level c1, lpad ( 'x', 100, 'x' ) stuff from dual 
  connect by level <= 1000;
  
  
create table tchild1 as 
  select c1, c2, round ( dbms_random.value ( 0, 100 ) ) c3, 
         trunc ( sysdate, 'y' ) + ( rownum / 240 ) c4,
         lpad ( 'x', 500, 'x' ) stuff  
  from   t  
  cross join (  
    select mod ( level, 17 ) c2
    from   dual 
    connect by level <= 100
  ) 
  order by dbms_random.value;
  
create table tchild2 as 
  select c1, c2, round ( dbms_random.value ( 0, 100 ) ) c3, 
         trunc ( sysdate, 'y' ) + ( rownum / 240 ) c4,
         lpad ( 'x', 500, 'x' ) stuff  
  from   t  
  cross join (  
    select mod ( level, 17 ) c2
    from   dual 
    connect by level <= 100 
  ) 
  order by dbms_random.value;