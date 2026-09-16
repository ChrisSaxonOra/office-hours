create or replace directory tmp as '/tmp';

drop table hybrid cascade constraints purge;
drop table t purge;
drop table t_ext cascade constraints purge;
drop table t_archive cascade constraints purge;
drop table t_ext_dmp;
drop table hr_ext cascade constraints purge;
drop table t2 purge;

begin
  utl_file.fremove ( 'TMP', 'tp0.dmp' );
exception
  when others then
    null;
end;
/

begin
  utl_file.fremove ( 'TMP', 'tp1.dmp' );
exception
  when others then
    null;
end;
/

begin
  utl_file.fremove ( 'TMP', 't.dmp' );
exception
  when others then
    null;
end;
/

begin
  utl_file.fremove ( 'TMP', 'hr.dmp' );
exception
  when others then
    null;
end;
/


  
create table t ( 
  c1 int not null, 
  c2 date not null, 
  c3 number not null, 
  c4 varchar2(20) not null
);

insert into t 
  select level c1, sysdate + level c2 ,
         round ( dbms_random.value ( 1, 100 ) ) c3,
         dbms_random.string ( 'a', 20 ) c4
  from   dual
  connect by level <= 50;
  
commit;


  
alter table t 
  modify partition by range ( c1 ) (
    partition p0 values less than ( 10 ),
    partition p1 values less than ( 20 ),
    partition p2 values less than ( 30 ),
    partition p3 values less than ( 40 ),
    partition p4 values less than ( 50 ),
    partition p5 values less than ( maxvalue ) 
);


create table t_ext_dmp ( 
  c1, c2, c3, c4 
) organization external (
  type oracle_datapump  
  default directory tmp
  location ( 'tp0.dmp' )
)
as
  select * 
  from   t partition ( p0 );
  
/* Column names must match those in the dmp; but can be a subset */
select * from external ( ( 
  c1 int, c2 date
) 
  type oracle_datapump
  default directory tmp
  location ( 'tp0.dmp' )
);

select * from external ( ( 
  c1 int, c2 date, c3 number
) 
  type oracle_datapump
  default directory tmp
  location ( 'tp0.dmp' )
);
  
  
select * from t_ext_dmp;




alter table t 
  drop partition p0;


/* Table must already be (non-interval) partitioned */ 
alter table t
  add external partition attributes (
    type oracle_datapump
    default directory tmp
  );
  
select partitioned, hybrid 
from   user_tables 
where  table_name = 'T';

select * from t_ext_dmp;

alter table t
  split partition p1 into (
    partition p0 values less than ( 10 ) 
      external location ( 'tp0.dmp' ),
    partition p1
  );
  
select * from t
where  c1 = 1;

select * from t
where  c1 = 20;

select * from t
where  c1 < 20;


update t
set    c3 = 100
where  c1 = 3;





create table t2 ( c1 primary key rely ) as 
  select c1 from t;
  

/* Unsupported */
alter table t
  add constraint fk
  foreign key ( c1 )
  references t2 ( c1 );

/* Constraints must be rely disable */
alter table t
  add constraint fk
  foreign key ( c1 )
  references t2 ( c1 )
  rely disable ;
  
  
  
  
alter session 
  set query_rewrite_integrity = trusted;
  
select t.* from t
join   t2
on     t.c1 = t2.c1;

/* Remove hybrid - drop external partition */
alter table t
  drop partition p0;

/* Then drop the attributes */
alter table t
  drop external partition attributes () ;








/* Can unload a query! */
create table hr_ext_2 (
  department_id, department_name,
  employee_id, first_name, last_name
) organization external (
  type oracle_datapump  
  default directory tmp
  location ( 'hr.dmp' )
)
as
  select d.department_id, d.department_name,
         e.employee_id, e.first_name, e.last_name
  from   hr.departments d
  join   hr.employees e
  on     d.department_id = e.department_id;
  
select * from external ( ( 
  employee_id int, first_name varchar2(100)
) 
  type oracle_datapump
  default directory tmp
  location ( 'hr.dmp' )
);


create table t_ext_dmp2 ( 
  c1, c2, c3, c4 
) organization external (
  type oracle_datapump  
  default directory tmp
  location ( 't_all.dmp' )
)
as
  select * 
  from   t;