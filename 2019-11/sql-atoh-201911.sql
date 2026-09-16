@C:\Users\csaxon\Documents\Scripts\sql-atoh-201911-setup.sql

select trunc ( start_date, 'mm' ) mth, count (*) 
from   appointments
group  by trunc ( start_date, 'mm' )
order  by mth;

info appointments;

var st_dt varchar2(12);
var en_dt varchar2(12);

exec :st_dt := '2019-01-01';
exec :en_dt := '2019-01-02';

select max ( a.consultant_id ) 
from   appointments a
where  a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );
                    
select child_number, rows_processed, is_bind_sensitive, is_bind_aware
from   v$sql
where  sql_text like 'select max ( a.consultant_id )%appointments a%'
order  by child_number;



exec :en_dt := '2020-01-01';

select max ( a.consultant_id ) 
from   appointments a
where  a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );

select child_number, rows_processed, is_bind_sensitive, is_bind_aware
from   v$sql
where  sql_text like 'select max ( a.consultant_id )%appointments a%'
order  by child_number;


var st_dt varchar2(12);
var en_dt varchar2(12);

exec :st_dt := '2020-01-01';
exec :en_dt := '2020-01-02';

select max ( a.consultant_id ) 
from   appointments a
where  a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );
                    
select * 
from   table(dbms_xplan.display_cursor(null, null, 'ROWSTATS LAST'));

select child_number, rows_processed, is_bind_sensitive, is_bind_aware
from   v$sql
where  sql_text like 'select max ( a.consultant_id )%appointments a%'
order  by child_number;



/**********************************/



select round ( avg ( count ( * ) ) )
from   appointments
group  by consultant_id;

exec :st_dt := '2019-01-01';
exec :en_dt := '2019-01-02';

select max ( a.end_date ) 
from   appointments a
where  a.consultant_id = 1
and    a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );

select index_name, clustering_factor 
from   user_indexes
where  table_name = 'APPOINTMENTS';

select child_number, rows_processed, is_bind_sensitive, is_bind_aware
from   v$sql
where  sql_text like 'select max ( a.end_date )%appointments a%'
order  by child_number;

exec :en_dt := '2020-01-01';

select max ( a.end_date ) 
from   appointments a
where  a.consultant_id = 1
and    a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );
                    
select max ( a.end_date ) 
from   appointments a
where  a.consultant_id = 1
and    a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );

select child_number, rows_processed, is_bind_sensitive, is_bind_aware
from   v$sql
where  sql_text like 'select max ( a.end_date )%appointments a%'
order  by child_number;





select count ( distinct a.end_date ) 
from   appointments a
where  a.consultant_id = 1;



/* How can we improve this? */
select max ( a.end_date ) 
from   appointments a
where  a.consultant_id = 1
and    a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );




drop index app_cons_date_i;
create index app_cons_date_i
  on appointments ( consultant_id, start_date );
           
select max ( a.end_date ) 
from   appointments a
where  a.consultant_id = 1
and    a.start_date between to_date ( :st_dt, 'YYYY-MM-DD' )
                    and to_date ( :en_dt, 'YYYY-MM-DD' );

drop index app_cons_date_st_en_i;
create index app_cons_date_st_en_i
  on appointments ( consultant_id, start_date, end_date );
  

alter index app_cons_date_st_en_i
  rebuild
  compress 1;
/**********************


***********************/

select * from periods;



select *
from   appointments a
join   periods p
on     a.start_date between p.date_from and p.date_to
where  p.period_name between '2019/01' and '2019/01'
and    p.period_type = 'P01';

select child_number, rows_processed, is_bind_sensitive, is_bind_aware
from   v$sql
where  sql_text like 'select *%appointments a%'
order  by child_number;


info appointments;



/* Index? */
create index per_type_name_i
  on periods ( 
    period_type, period_name, date_from, date_to 
  );

select *
from   appointments a
join   periods p
on     a.start_date between p.date_from and p.date_to
where  p.period_name between '2019/01' and '2019/01'
and    p.period_type = 'P01';







select /*+ dynamic_sampling ( 11 ) */*
from   appointments a
join   periods p
on     a.start_date between p.date_from and p.date_to
where  p.period_name between '2019/01' and '2019/01'
and    p.period_type = 'P01';



select /*+ dynamic_sampling ( 11 ) */*
from   appointments a
join   periods p
on     a.start_date between p.date_from and p.date_to
where  p.period_name between '2019/01' and '2019/02'
and    p.period_type = 'P01';




var per_start varchar2(20);
var per_end varchar2(20);
var per_name varchar2(20);

exec :per_start := '2019/01';
exec :per_end := '2019/01';
exec :per_name := '2019/01';


select count ( distinct a.end_date )
from   appointments a
join   periods p
on     a.start_date between p.date_from and p.date_to
where  p.period_name between :per_start and :per_end --= :per_name
and    p.period_type = 'P01';

select child_number, rows_processed, is_bind_sensitive, is_bind_aware
from   v$sql
where  sql_text like 'select count ( distinct a.end_date )%appointments a%:per_name%'
order  by child_number;


select /*+ dynamic_sampling ( 11 ) */*
from   appointments a
join   periods p
on     a.start_date between p.date_from and p.date_to
where  p.period_name between :per_start and :per_end
and    p.period_type = 'P01';

select child_number, rows_processed, is_bind_sensitive, is_bind_aware, sql_text
from   v$sql
where  sql_text like 'select /*+ dynamic_sampling ( 11 ) */%appointments a%:per_start%'
order  by child_number;

/*************************

**************************/
@C:\Users\csaxon\Documents\Scripts\sql-atoh-201911-setup.sql
;

select *
from   locations l
join   appointments a
on     a.location_id = l.location_id
join   periods p
on     a.start_date between p.date_from and p.date_to
where  l.location_name = 'ROOM001'
and    p.period_name between '2019/01' and '2019/01'
and    p.period_type = 'P01'
and    a.consultant_id = 1;






alter session set optimizer_adaptive_plans = true;

select *
from   locations l
join   appointments a
on     a.location_id = l.location_id
join   periods p
on     a.start_date between p.date_from and p.date_to
where  l.location_name = 'ROOM001'
and    p.period_name between '2019/01' and '2019/01'
and    p.period_type = 'P01'
and    a.consultant_id = 1;


set serveroutput off
alter session set statistics_level = all;
select *
from   locations l
join   appointments a
on     a.location_id = l.location_id
join   periods p
on     a.start_date between p.date_from and p.date_to
where  l.location_name = 'ROOM001'
and    p.period_name between '2019/01' and '2019/01'
and    p.period_type = 'P01'
and    a.consultant_id = 1;

select * 
from   table(dbms_xplan.display_cursor(null, null, 'ROWSTATS LAST +ADAPTIVE'));
















/*
SELECT
  sum(SAL_DXC.CEXREALPROG + SAL_DXC.CEXNONPROG),
  CM_T_PERIODO_DI.CODPERIODO,
  CM_T_PERIODO_DI.ANO,
  CM_T_PERIODO_DI.NUMMES
FROM
  CM_T_PERIODO_DI,
  CM_T_DXC_HE  SAL_DXC,
  CM_T_HOSPITAL_DI  CM_T_HOSPITAL_DI_IDHOSP
WHERE
  ( CM_T_HOSPITAL_DI_IDHOSP.IDHOSPITAL=SAL_DXC.IDHOSPITAL  )
  AND  ( SAL_DXC.IDDATASALTROZO between CM_T_PERIODO_DI.IDDATADESDE 
                                and  CM_T_PERIODO_DI.IDDATAHASTA 
  and SAL_DXC.TROZOFINMOV=1  )
  AND  CM_T_HOSPITAL_DI_IDHOSP.NOMHOSP  =  'C.H. DE OURENSE'
  AND  CM_T_PERIODO_DI.CODPERIODO  BETWEEN  '2019/01'  AND  '2019/10'
  AND  (CM_T_PERIODO_DI.TIPOPERIODO  =  'Meses' )
  )
GROUP BY
  CM_T_PERIODO_DI.CODPERIODO,
  CM_T_PERIODO_DI.ANO,
  CM_T_PERIODO_DI.NUMMES

------------------------------------------------------------------------------
| Id  | Operation                        | Name                      | Rows  |
------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                 |                           |    13 |
|   1 |  HASH GROUP BY                   |                           |    13 |
|   2 |   NESTED LOOPS                   |                           | 10922 |
|   3 |    NESTED LOOPS                  |                           | 10922 |
|   4 |     MERGE JOIN CARTESIAN         |                           |    14 |
|   5 |      TABLE ACCESS BY INDEX ROWID | CM_T_HOSPITAL_DI          |     1 |
|*  6 |       INDEX RANGE SCAN           | CM_T_HOSPITAL_DI_NOMHOSP  |     1 |
|   7 |      BUFFER SORT                 |                           |    14 |
|*  8 |       TABLE ACCESS BY INDEX ROWID| CM_T_PERIODO_DI           |    14 |
|*  9 |        INDEX RANGE SCAN          | CM_IX_PERIODO_TIPOPERIODO |   456 |
|* 10 |     INDEX RANGE SCAN             | CM_IX_DXC_IDDATATROZO     |   109 |
|* 11 |    TABLE ACCESS BY INDEX ROWID   | CM_T_DXC_HE               |   760 |
------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   6 - access("CM_T_HOSPITAL_DI_IDHOSP"."NOMHOSP"='C.H. DE OURENSE')
   8 - filter("CM_T_PERIODO_DI"."CODPERIODO">='2019/01' AND "CM_T_PERIODO_DI"."CODPERIODO"<='2019/10')
   9 - access("CM_T_PERIODO_DI"."TIPOPERIODO"='Meses')
  10 - access("SAL_DXC"."IDDATASALTROZO">="CM_T_PERIODO_DI"."IDDATADESDE" AND 
              "SAL_DXC"."IDDATASALTROZO"<="CM_T_PERIODO_DI"."IDDATAHASTA")
  11 - filter("SAL_DXC"."TROZOFINMOV"=1 AND "CM_T_HOSPITAL_DI_IDHOSP"."IDHOSPITAL"="SAL_DXC"."IDHOSPITAL
              ")
*/