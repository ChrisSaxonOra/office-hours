/*declare
  start_time pls_integer;
  grade varchar2(10);
begin
  start_time := dbms_utility.get_time();
  for rws number in 0 .. 100 by 0.00001 loop
    grade := case rws
      when 100 then 'A*' -- implicit = 100
      when in ( 50, 60, 70, 80, 90 ) then 'boundary'
      when > 90 then 'A'
      when > 80 then 'B'
      when > 70 then 'C'
      when > 60 then 'D'
      when > 50 then 'E'
      when is null, 0 then 'U' -- implicit = 0
      else 'F'
    end;
  end loop;
  DBMS_OUTPUT.put_line ( 'CASE expression : ' || ( DBMS_UTILITY.get_time - start_time ) );
  
  start_time := dbms_utility.get_time();
  for rws number in 0 .. 100 by 0.00001 loop
    case
    when rws = 100 then 
      grade := 'A*';
    when rws in ( 50, 60, 70, 80, 90 ) then 
      grade := 'boundary';
    when rws > 90 then 
      grade := 'A';
    when rws > 80 then 
      grade := 'B';
    when rws > 70 then 
      grade := 'C';
    when rws > 60 then 
      grade := 'D';
    when rws > 50 then 
      grade := 'E';
    when rws is null or rws = 0 then 
      grade := 'U';
    else 
      grade := 'F';
    end case;
  end loop;
  DBMS_OUTPUT.put_line ( 'CASE statement : ' || ( DBMS_UTILITY.get_time - start_time ) );
  
  start_time := dbms_utility.get_time();
  for rws number in 0 .. 100 by 0.00001 loop
    if rws = 100 then 
      grade := 'A*';
    elsif rws in ( 50, 60, 70, 80, 90 ) then 
      grade := 'boundary';
    elsif rws > 90 then 
      grade := 'A';
    elsif rws > 80 then 
      grade := 'B';
    elsif rws > 70 then 
      grade := 'C';
    elsif rws > 60 then 
      grade := 'D';
    elsif rws > 50 then 
      grade := 'E';
    elsif rws is null or rws = 0 then 
      grade := 'U';
    else 
      grade := 'F';
    end if;
  end loop;
  DBMS_OUTPUT.put_line ( 'IF : ' || ( DBMS_UTILITY.get_time - start_time ) );
end;
/





declare
  start_time pls_integer;
  grade varchar2(10);
begin
  start_time := dbms_utility.get_time();
  for rws number in 0 .. 100 by 0.00001 loop
    grade := case rws
      when > 50 then 'E'
      when > 60 then 'D'
      when > 70 then 'C'
      when > 80 then 'B'
      when > 90 then 'A'
      when 100 then 'A*' -- implicit = 100
      when in ( 50, 60, 70, 80, 90 ) then 'boundary'
      when is null, 0 then 'U' -- implicit = 0
      else 'F'
    end;
  end loop;
  DBMS_OUTPUT.put_line ( 'CASE expression : ' || ( DBMS_UTILITY.get_time - start_time ) );
  
  start_time := dbms_utility.get_time();
  for rws number in 0 .. 100 by 0.00001 loop
    case
    when rws > 50 then 
      grade := 'E';
    when rws > 60 then 
      grade := 'D';
    when rws > 70 then 
      grade := 'C';
    when rws > 80 then 
      grade := 'B';
    when rws > 90 then 
      grade := 'A';
    when rws = 100 then 
      grade := 'A*';
    when rws in ( 50, 60, 70, 80, 90 ) then 
      grade := 'boundary';
    when rws is null or rws = 0 then 
      grade := 'U';
    else 
      grade := 'F';
    end case;
  end loop;
  DBMS_OUTPUT.put_line ( 'CASE statement : ' || ( DBMS_UTILITY.get_time - start_time ) );
  
  start_time := dbms_utility.get_time();
  for rws number in 0 .. 100 by 0.00001 loop
    if rws > 50 then 
      grade := 'E';
    elsif rws > 60 then 
      grade := 'D';
    elsif rws > 70 then 
      grade := 'C';
    elsif rws > 80 then 
      grade := 'B';
    elsif rws = 100 then 
      grade := 'A*';
    elsif rws > 90 then 
      grade := 'A';
    elsif rws in ( 50, 60, 70, 80, 90 ) then 
      grade := 'boundary';
    elsif rws is null or rws = 0 then 
      grade := 'U';
    else 
      grade := 'F';
    end if;
  end loop;
  DBMS_OUTPUT.put_line ( 'IF : ' || ( DBMS_UTILITY.get_time - start_time ) );
end;
/




select case
         when percent_correct >= 50 and percent_correct < 60 then 'E'
         when percent_correct >= 60 and percent_correct < 70 then 'D'
         when percent_correct >= 70 and percent_correct < 80 then 'C'
         when percent_correct >= 80 and percent_correct < 90 then 'B'
         when percent_correct >= 90 then 'A'
         else 'F'
       end grade, count(*)
from   exam_results
group  by grade
order  by count(*) desc;



declare
  start_time pls_integer;
  grade varchar2(10);
begin
  
  start_time := dbms_utility.get_time();
  for rws in (
    select percent_correct
    from   exam_results cross join ( select * from dual connect by level <= 10000 )
  ) loop
    grade := case
             when rws.percent_correct >= 70 and rws.percent_correct < 80 then 'C'
             when rws.percent_correct >= 60 and rws.percent_correct < 70 then 'D'
             when rws.percent_correct >= 50 and rws.percent_correct < 60 then 'E'
             when rws.percent_correct >= 80 and rws.percent_correct < 90 then 'B'
             when rws.percent_correct >= 90 then 'A'
             else 'F'
           end;
  end loop;
  dbms_output.put_line ( 'Prioritized : ' || ( dbms_utility.get_time - start_time ) );
  
  
  start_time := dbms_utility.get_time();
  for rws in (
    select percent_correct
    from   exam_results cross join ( select * from dual connect by level <= 10000 )
  ) loop
    grade := case
             when rws.percent_correct >= 90 then 'A'
             when rws.percent_correct >= 80 and rws.percent_correct < 90 then 'B'
             when rws.percent_correct >= 70 and rws.percent_correct < 80 then 'C'
             when rws.percent_correct >= 60 and rws.percent_correct < 70 then 'D'
             when rws.percent_correct >= 50 and rws.percent_correct < 60 then 'E'
             else 'F'
           end;
  end loop;
  dbms_output.put_line ( 'A-E AND : ' || ( dbms_utility.get_time - start_time ) );
  
  start_time := dbms_utility.get_time();
  for rws in (
    select percent_correct
    from   exam_results cross join ( select * from dual connect by level <= 10000 )
  ) loop
    grade := case
             when rws.percent_correct >= 90 then 'A'
             when rws.percent_correct >= 80 then 'B'
             when rws.percent_correct >= 70 then 'C'
             when rws.percent_correct >= 60 then 'D'
             when rws.percent_correct >= 50 then 'E'
             else 'F'
           end ;
  end loop;
  dbms_output.put_line ( 'A-E : ' || ( dbms_utility.get_time - start_time ) );
  
end;
/
*/
drop view exam_result_outcomes;
drop table exam_grades
  cascade constraints purge;
drop table exam_results
  cascade constraints purge;
  
create table exam_results (
  student_id integer not null,
  exam_id    integer not null,
  percent_correct number(5, 2)
    constraint exre_pct_0_100_c 
    check ( percent_correct between 0 and 100 ),
  constraint exam_result_pk 
    primary key ( student_id, exam_id )
);

begin 
  insert into exam_results
  with rws as (
    select level - 1 x from dual
    connect by level <= 1000
  )
    select mod ( x, 100 ) + 1,
           floor ( x / 100 ) + 1,
           round ( least ( greatest ( ( dbms_random.normal * 10 ) + 70, 0 ), 100 ), 2 )
    from   rws;
  
  /* Test student & exam */
  insert into exam_results values ( 0, 1, 100 );
  insert into exam_results values ( 1, 0, 100 );
  insert into exam_results values ( 0, 0, 100 );
  insert into exam_results values ( 0, 2, null );
  insert into exam_results values ( 2, 0, null );
  
  commit;
end;
/

cl scr