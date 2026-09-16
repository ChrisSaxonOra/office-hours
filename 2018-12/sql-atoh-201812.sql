insert into extb (
  exdate, excode, excrcode, exrate
)
  select mmen, ( 
           select excode
           from   exfirmtb
           where  excrcode in (
             '05', '005'
           )
         ),
         mmcode,
         mmrate
  from   dual
  where  not exists (
    select *
    from   extb
    where  exdate = mmen
    and    excrcode in ( '05', '005' )
  );
  
drop table t cascade constraints purge;
drop table t2 cascade constraints purge;
create table t (
  c1 int, c2 int, c3 int
);

create table t2 (
  c2 int, c3 int
);

insert into t2 values ( 1, 0 );
commit;

insert into t ( c1, c2, c3 ) 
  select :c1, :c2, 
        ( select c3 from t2 
        where  c2 in ( 1, 2 ) ) c3
  from   dual
  where  not exists (
    select null from t
    where  c1 = :c1
    and    c2 in ( 1, 2 )
  );
  
select * from t;

merge into t 
using ( select :c1 c1, 0 c2 from dual ) curr
on    ( t.c1 = curr.c1 and t.c2 = curr.c2 )
when not matched then 
  insert ( t.c1, t.c2 )
  values ( curr.c1, curr.c2 );
  
  
drop table t cascade constraints purge;
create table t (
  c1 int, c2 date
) partition by range ( c2 )
  interval ( interval '1' month ) (
  partition p0 values less than ( date'2018-01-01' ) 
);

insert into t 
  select level c1, 
         date'2017-12-31' + level c2
  from   dual
  connect by level <= 100;

commit;

select partition_name, high_value
from   user_tab_partitions
where  table_name = 'T';
/*
PARTITION_NAME   HIGH_VALUE                                                                            
P0               TO_DATE(' 2018-01-01 00:00:00', ... 
SYS_P5095        TO_DATE(' 2018-02-01 00:00:00', ... 
SYS_P5096        TO_DATE(' 2018-03-01 00:00:00', ... 
SYS_P5097        TO_DATE(' 2018-04-01 00:00:00', ... 
SYS_P5098        TO_DATE(' 2018-05-01 00:00:00', ... 
*/
declare
  high_val date;
begin
  for parts in ( 
    select * from user_tab_partitions
    where  table_name = 'T'
    and    partition_name like 'SYS%'
  ) loop
    execute immediate 'select ' || parts.high_value || ' from dual' into high_val;
    dbms_output.put_line ( 
      'alter table t rename partition ' || parts.partition_name || 
      ' to P' || to_char ( high_val, 'YYYY_MM_DD' )
    );
  end loop;
end;
/

select max(uo.subobject_name)
from   t partition for ( sysdate ), 
    user_objects uo
where  dbms_rowid.rowid_object(t.rowid) = 
    uo.data_object_id;

select max(partition_name) keep (
         dense_rank last order by partition_position
       )
from   user_tab_partitions 
where  table_name = 'T';

select partition_name, interval
from   user_tab_partitions
where  table_name = 'T';

/*
PARTITION_NAME   INTERVAL   
P0               NO         
SYS_P5095        YES        
SYS_P5096        YES        
SYS_P5097        YES        
SYS_P5098        YES 
*/

alter table t set interval ( 
  interval '1' month 
);

alter table t drop partition p0;

select partition_name, interval
from   user_tab_partitions
where  table_name = 'T';

/*
PARTITION_NAME   INTERVAL   
SYS_P5095        NO         
SYS_P5096        YES        
SYS_P5097        YES        
SYS_P5098        YES
*/
