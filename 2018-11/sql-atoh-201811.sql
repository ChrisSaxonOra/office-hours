/* reset */
alter table customer_addresses no flashback archive;
drop table customer_addresses  purge;
drop flashback archive address_archive;

create table customer_addresses (
  given_name     varchar2(100) not null,
  family_name    varchar2(100) not null,
  address        varchar2(1000) not null,
  moved_in_date  date not null,
  moved_out_date date
);

insert into customer_addresses values ('Chris', 'Saxon', 'The Shire', date'2000-01-01', null);
commit;

update customer_addresses 
set    moved_out_date = date'2015-09-01'
where  address = 'The Shire';

insert into customer_addresses values ('Chris', 'Saxon', 'Rivendell', date'2015-09-01', null);

commit;

select * from customer_addresses;

create flashback archive 
  address_archive tablespace users retention 1 day;

alter table customer_addresses 
  flashback archive address_archive;

select versions_startscn,
       versions_starttime,
       versions_endscn,
       versions_endtime,
       versions_xid,
       versions_operation
       ,DBMS_FLASHBACK_ARCHIVE.get_sys_context(versions_xid, 'USERENV','SESSION_USER') AS session_user
       ,DBMS_FLASHBACK_ARCHIVE.get_sys_context(versions_xid, 'USERENV','CLIENT_IDENTIFIER') 
from customer_addresses
  versions between scn minvalue and maxvalue
--  versions between timestamp minvalue and maxvalue
  ;
  
delete customer_addresses;
commit;

insert into customer_addresses values ('Chris', 'Saxon', 'The Shire', date'2000-01-01', null);
commit;

update customer_addresses 
set    moved_out_date = date'2015-09-01'
where  address = 'The Shire';

insert into customer_addresses values ('Chris', 'Saxon', 'Rivendell', date'2015-09-01', null);

commit;

select versions_operation, versions_xid, versions_endscn, versions_startscn, c.*-- min ( versions_startscn )
from customer_addresses 
  versions between scn minvalue and maxvalue c;

select versions_startscn,
       versions_starttime,
       versions_endscn,
       versions_endtime,
       versions_xid,
       versions_operation       ,
       DBMS_FLASHBACK_ARCHIVE.get_sys_context(versions_xid, 'USERENV','SESSION_USER') AS session_user,
       DBMS_FLASHBACK_ARCHIVE.get_sys_context(versions_xid, 'USERENV','CLIENT_IDENTIFIER') 
from customer_addresses
  versions between scn :min_scn and maxvalue;








drop table emp_mgr_relation cascade constraints purge;
create table emp_mgr_relation (
  emp_id varchar2(10),
  mgr_id varchar2(10),
  frm_dt date,
  to_dt  date
);

INSERT INTO emp_mgr_relation VALUES ('EMP1', 'MGR1', date'2018-01-01', date'2018-01-31');
INSERT INTO emp_mgr_relation VALUES ('EMP2', 'MGR2', date'2018-01-01', date'2018-01-31');
INSERT INTO emp_mgr_relation VALUES ('EMP3', 'MGR3', date'2018-01-01', date'2018-01-31');
INSERT INTO emp_mgr_relation VALUES ('EMP4', 'MGR4', date'2018-01-01', date'2018-01-31');
INSERT INTO emp_mgr_relation VALUES ('EMP5', 'MGR5', date'2018-01-01', date'2018-01-10');
INSERT INTO emp_mgr_relation VALUES ('EMP5', 'MGR1', date'2018-01-11', date'2018-01-15');
INSERT INTO emp_mgr_relation VALUES ('EMP5', 'MGR2', date'2018-01-16', date'2018-01-20');
INSERT INTO emp_mgr_relation VALUES ('EMP5', 'MGR3', date'2018-01-21', date'2018-01-25');
INSERT INTO emp_mgr_relation VALUES ('EMP5', 'MGR4', date'2018-01-26', date'2018-01-31');
INSERT INTO emp_mgr_relation VALUES ('EMP6', 'MGR6', date'2018-01-01', date'2018-01-15');
INSERT INTO emp_mgr_relation VALUES ('EMP6', 'MGR2', date'2018-01-18', date'2018-01-31');
COMMIT;

select * from emp_mgr_relation
order  by 2, 3;

with dates as (
  select * from emp_mgr_relation
  unpivot (
    dt for ( src ) in ( frm_dt, to_dt )
  )
)
  select * from dates
  order  by mgr_id, dt;
  
alter session set nls_date_format = 'DD-MON-YYYY';
with dates as (
  select * from emp_mgr_relation
  unpivot (
    dt for ( src ) in ( frm_dt, to_dt )
  )
), ranges as (
  select emp_id, mgr_id, dt, dt st_dt, src, 
         lead ( dt ) over ( partition by mgr_id order by dt )  en_dt
  from   dates
)
  select * from ranges
  order  by mgr_id, dt;
  
with dates as (
  select * from emp_mgr_relation
  unpivot (
    dt for ( src ) in ( frm_dt, to_dt )
  )
), ranges as (
  select emp_id, mgr_id, dt, dt st_dt, src, 
         lead ( dt ) over ( partition by mgr_id order by dt )  en_dt
  from   dates
)
  select e.mgr_id, src, 
         case 
           when src = 'TO_DT' then st_dt + 1
           else st_dt
         end st_dt,
         case
           when src = 'TO_DT' or 
                lead ( src ) over ( 
                  partition by e.mgr_id order by st_dt 
                ) = 'TO_DT' or
                en_dt =  max ( en_dt ) over ( 
                           partition by e.mgr_id 
                         ) 
           then en_dt
           else
             en_dt - 1
         end en_dt,
         count(*) sub_ord_cn, 
         listagg ( e.emp_id, ',' ) 
           within group ( order by e.emp_id ) subordinates
  from   ranges r
  join   emp_mgr_relation e
  on     r.mgr_id = e.mgr_id
  and    e.frm_dt <= st_dt
  and    e.to_dt >= en_dt
  and    st_dt < en_dt
  group  by e.mgr_id, st_dt, en_dt, src
  order  by e.mgr_id, st_dt, en_dt;




with rcte1 (emp_id, mgr_id, dt, to_dt) as (
  select emp_id, mgr_id, frm_dt, to_dt
  from   emp_mgr_relation
  union all
  select emp_id, mgr_id, dt + 1, to_dt
  from   rcte1
  where  to_dt > dt
), cte2 (
  mgr_id, dt, sub_ord_cn, subordinates
) as (
  select mgr_id, dt, count(*), 
         listagg ( emp_id,  ',' ) 
           within group ( order by emp_id )    
  from   rcte1
  group by mgr_id, dt
), cte3 (
  mgr_id, dt, sub_ord_cn, subordinates, bucket
) as (
  select mgr_id, dt, sub_ord_cn, subordinates,
         row_number() over (
           partition by mgr_id, sub_ord_cn, subordinates 
           order by dt
         ) - row_number() over ( 
               partition by mgr_id 
               order by dt
             )
  from   cte2
)
  select mgr_id, min(dt) as frm_dt, max(dt) as to_dt, 
         sub_ord_cn, subordinates
  from   cte3
  group by mgr_id, bucket, sub_ord_cn, subordinates
  order by mgr_id, frm_dt;
  
   
  
  
with dates as (
  select * from emp_mgr_relation
  unpivot (
    dt for ( src ) in ( frm_dt, to_dt )
  )
), ranges as (
  select emp_id, mgr_id, dt, dt st_dt, src, 
         lead ( dt ) over ( partition by mgr_id order by dt )  en_dt
  from   dates
), rcte1 (emp_id, mgr_id, dt, to_dt) as (
  select emp_id, mgr_id, frm_dt, to_dt
  from   emp_mgr_relation
  union all
  select emp_id, mgr_id, dt + 1, to_dt
  from   rcte1
  where  to_dt > dt
), cte2 (
  mgr_id, dt, sub_ord_cn, subordinates
) as (
  select mgr_id, dt, count(*), 
         listagg ( emp_id,  ',' ) 
           within group ( order by emp_id )    
  from   rcte1
  group by mgr_id, dt
), cte3 (
  mgr_id, dt, sub_ord_cn, subordinates, bucket
) as (
  select mgr_id, dt, sub_ord_cn, subordinates,
         row_number() over (
           partition by mgr_id, sub_ord_cn, subordinates 
           order by dt
         ) - row_number() over ( 
               partition by mgr_id 
               order by dt
             )
  from   cte2
)
  select e.mgr_id, 
         case 
           when src = 'TO_DT' then st_dt + 1
           else st_dt
         end st_dt,
         case
           when src = 'TO_DT' or 
                lead ( src ) over ( 
                  partition by e.mgr_id order by st_dt 
                ) = 'TO_DT' or
                en_dt = 
                  max ( en_dt ) over ( 
                    partition by e.mgr_id 
                  ) 
           then en_dt
           else
             en_dt - 1
         end en_dt,
         count(*) sub_ord_cn, 
         listagg ( e.emp_id, ',' ) 
           within group ( order by e.emp_id ) subordinates
  from   ranges r
  join   emp_mgr_relation e
  on     r.mgr_id = e.mgr_id
  and    e.frm_dt <= st_dt
  and    e.to_dt >= en_dt
  and    st_dt < en_dt
  group  by e.mgr_id, st_dt, en_dt, src
  minus
  select mgr_id, min(dt) as frm_dt, max(dt) as to_dt, 
         sub_ord_cn, subordinates
  from   cte3
  group by mgr_id, bucket, sub_ord_cn, subordinates;
  order by mgr_id, frm_dt;  
  
  
select mgr_id,
       final_slice_from dt_frm,
       final_slice_to dt_to,
       regexp_count(emps, ',') + 1 sub_ord_cnt,
       emps sub_ordinates
from   (
  select mgr_id,
         final_slice_from,
         final_slice_to,
         (select listagg(emp_id, ',') within group(order by emp_id)
            from emp_mgr_relation y
           where y.mgr_id = r.mgr_id
             and (final_slice_from between y.frm_dt and y.to_dt or
                 final_slice_to between y.frm_dt and y.to_dt)
          ) emps
  from   (
      select mgr_id,
             slice_from + frm_dt_adj final_slice_from,
             slice_to + to_dt_adj final_slice_to
      from   (
        select mgr_id,
               slice_from,
               slice_to,
               frm_dt_flg,
               to_dt_flg,
               decode(nvl(frm_dt_flg, '#'), '#', 1, 0) frm_dt_adj,
               decode(nvl(to_dt_flg, '#'), '#', -1, 0) to_dt_adj
        from (
          select a.mgr_id,
                 a.slice_from,
                 a.slice_to,
                 (select 'Y'
                  from dual
                  where exists (
                    select 1
                    from   emp_mgr_relation e
                    where  a.mgr_id = e.mgr_id
                    and    a.slice_from = e.frm_dt
                  )
                 ) frm_dt_flg,
                 (select 'Y'
                  from   dual
                  where  exists (
                    select 1
                    from   emp_mgr_relation d
                    where  a.mgr_id = d.mgr_id
                    and    a.slice_to = d.to_dt
                  )
                 ) to_dt_flg
          from (
            select mgr_id,
                   dt slice_from,
                   lead(dt, 1) over(partition by mgr_id order by dt) slice_to
            from (
              select distinct mgr_id, frm_dt dt
              from   emp_mgr_relation
              union
              select distinct mgr_id, to_dt
              from emp_mgr_relation
            )
          ) a
          where slice_to is not null
        )
      )
  ) r
)