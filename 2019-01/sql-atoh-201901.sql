drop table skip_sum purge;
  
create table skip_sum (
  rn number 
, skip_flag number 
, val number 
, rows_to_sum number 
);
  
insert into skip_sum (rn,skip_flag,val,rows_to_sum) values (1,0,5.5,2);
insert into skip_sum (rn,skip_flag,val,rows_to_sum) values (2,0,3.5,3);
insert into skip_sum (rn,skip_flag,val,rows_to_sum) values (3,1,2.5,2);
insert into skip_sum (rn,skip_flag,val,rows_to_sum) values (4,0,6.5,0);
insert into skip_sum (rn,skip_flag,val,rows_to_sum) values (5,1,8,0);
insert into skip_sum (rn,skip_flag,val,rows_to_sum) values (6,0,3,0);
  
commit;

with calc as (
select s.*,
       lead ( 
         c1, decode ( rows_to_sum, 0, 1, rows_to_sum ), 999
       ) ignore nulls over ( 
         order by rn
       ) cnt_calc
from (
select s.*, 
       case when skip_flag = 1 then null else rn end c1
from   skip_sum s
) s
)
select c.*,
       val + 
       case
         when rows_to_sum > 0 then 
           sum (
            case when skip_flag = 0 then val end
           ) over ( 
             order by rn
             rows between 1 following and cnt_calc following
           ) 
         else 0
       end tot
from   calc c
order  by rn ;

select * from skip_sum;

/* Recursive with solution */
with cond_sum (
  rn, skip_flag, val, rows_to_sum, tot, rows_counted, root
) as (
  select rn, skip_flag, val, rows_to_sum,
         val tot, 0 rows_counted, rn root
  from   skip_sum
  union  all
  select ss.rn, ss.skip_flag, ss.val, cs.rows_to_sum,
         case
           when ss.skip_flag = 0 then
             ss.val + tot
           else 
             tot
         end, 
         case
           when ss.skip_flag = 0 then
             rows_counted + 1
           else 
             rows_counted
         end,
         cs.root
  from   cond_sum cs
  join   skip_sum ss
  on     ss.rn = cs.rn + 1
  and    cs.rows_to_sum > cs.rows_counted
), leaves as (
  select c.*,
         max ( rn ) over ( partition by root ) mx
  from   cond_sum c
)
  select * from leaves
  where  rn = mx
  order  by root;
  
/* Doesn't work: stops as soon as you a row to ignore */
select mno, cls, rn, val, sm, skip_flag, rws
from   skip_sum
match_recognize (
  order by rn
  measures 
    init.val + nvl ( sum ( to_sum.val ) , 0 ) sm,
    count ( to_sum.* ) rowct,
    classifier() cls,
    match_number() mno,
    first ( rows_to_sum ) rws
  all rows per match
  after match skip to next row
  pattern ( 
    init to_sum* 
  )
  define 
     to_sum as count(to_sum.*) <= first ( rows_to_sum )
            and skip_flag = 0
);

select mno, cls, rn, val, sm, skip_flag, rws
from   skip_sum
match_recognize (
  order by rn
  measures 
    init.val + nvl ( sum ( to_sum.val ) , 0 ) sm,
    count ( to_sum.* ) rowct,
    classifier() cls,
    match_number() mno,
    first ( rows_to_sum ) rws
  all rows per match
  after match skip to next row
  pattern ( 
    init ( to_sum | to_skip )* 
  )
  define 
     to_sum as count(to_sum.*) <= first ( rows_to_sum )
            and skip_flag = 0
    ,to_skip as count(to_sum.*) < first ( rows_to_sum )
);


select *
from   skip_sum
match_recognize (
  order by rn
  measures 
    first ( rn ) rn, 
    first ( val ) val,
    sum ( tot.val ) sm
  after match skip to next row
  pattern ( 
    init ( to_sum | to_skip )* 
  )
  subset tot = ( init, to_sum )
  define 
     to_sum as count(to_sum.*) <= first ( rows_to_sum )
            and skip_flag = 0
    ,to_skip as count(to_sum.*) < first ( rows_to_sum )
);





select * from (
  select object_type, object_name from dba_objects
)
pivot (
  count(*) ct, max(object_name) mx for object_type in (
    'TABLE' tb, 'VIEW' vw
  )
);


Update  tab_A ctf1 
Set    column_a=1
Where   ctf1.codSER = :a_valPAR_04  -- :a_codSER 
And ctf1.codMSV = :a_valPAR_05  -- :a_codMSV 
And ctf1.codIST = :a_valPAR_06   -- :a_codIST 
And ctf1.cafctp_Soa in  (
    select  cafctp_Soa  
    From    tab_A ctf2
    group by codser, codmsv, codIST,cafdir_Soa, cafctp_Soa 
    having count(*)>1
)
