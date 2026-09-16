--@"C:\Users\CSAXON\Oracle Content - Accounts\Oracle Content\Scripts\sql-atoh-202201-setup"
--cl scr








/* Partition by */
select window_id, group_column, 
       sum ( window_id ) over ( w ) sm,
       count ( window_id ) over ( w ) ct
from   windows
window w as (
  partition by group_column 
)
order  by window_id;














/* Order by */
select window_id id, sort_column sc,
       sum ( window_id ) over ( w rows unbounded preceding ) sm_rws,
       sum ( window_id ) over ( w range unbounded preceding ) sm_rnge,
       sum ( window_id ) over ( w groups unbounded preceding ) sm_grps,
       count ( window_id ) over ( w rows unbounded preceding ) ct_rws,
       count ( window_id ) over ( w range unbounded preceding ) ct_rnge,
       count ( window_id ) over ( w groups unbounded preceding ) ct_grps
from   windows
window w as (
  order by sort_column
);








/* order by ... 1 preceding and 1 following */
select window_id id, sort_column sc,
       sum ( window_id ) over ( w rows between 1 preceding and 1 following ) sm_rws,
       sum ( window_id ) over ( w range between 1 preceding and 1 following ) sm_rnge,
       sum ( window_id ) over ( w groups between 1 preceding and 1 following ) sm_grps,
       count ( window_id ) over ( w rows between 1 preceding and 1 following ) ct_rws,
       count ( window_id ) over ( w range between 1 preceding and 1 following ) ct_rnge,
       count ( window_id ) over ( w groups between 1 preceding and 1 following ) ct_grps
from   windows
window w as (
  order by sort_column 
);







/* order by rows 1 preceding and 1 following exclude ... */
select window_id, sort_column sc, 
       sum ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude no others
       ) sm_none, 
       sum ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude current row 
       ) sm_current,
       sum ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude ties 
       ) sm_ties,
       sum ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude group 
       ) sm_group
from   windows
window w as ( order by sort_column );

/* order by rows 1 preceding and 1 following exclude ... */
select window_id, sort_column sc, 
       count ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude no others
       ) ct_none, 
       count ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude current row 
       ) ct_current,
       count ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude ties 
       ) ct_ties,
       count ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude group 
       ) ct_group
from   windows
window w as ( order by sort_column );








/* partition by order by */
select window_id id, group_column gc, sort_column sc,
       sum ( window_id ) over ( w rows unbounded preceding ) sm_rws,
       sum ( window_id ) over ( w range unbounded preceding ) sm_rng,
       sum ( window_id ) over ( w groups unbounded preceding ) sm_grp,
       count ( window_id ) over ( w rows unbounded preceding ) ct_rws,
       count ( window_id ) over ( w range unbounded preceding ) ct_rng,
       count ( window_id ) over ( w groups unbounded preceding ) ct_grp
from   windows
window w as (
  partition by group_column 
  order by sort_column 
)
order  by window_id;






/* lag/lead */
select window_id id, group_column gc, sort_column sc,
       lag ( window_id ) over ( ord ) lg,
       lead ( window_id ) over ( ord ) ld,
       lag ( window_id, 2 ) over ( ord ) lg_2,
       lead ( window_id, 2 ) over ( ord ) ld_2,
       lag ( window_id ) over ( grp_ord ) lg_grp,
       lead ( window_id ) over ( grp_ord ) ld_grp
from   windows
window ord as (
  order by sort_column 
), grp_ord as (
  partition by group_column
  order by sort_column 
)
order  by window_id;








/* lag/lead partition by */
select window_id, group_column, sort_column,
       lag ( window_id ) over ( w ) lg,
       lead ( window_id ) over ( w ) ld
from   windows
window w as (
  partition by group_column 
  order by sort_column 
)
order  by window_id;



























/* order by rows 1 preceding and 1 following exclude ... */
select window_id, sort_column sc,
       sum ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude current row 
       ) sm_curr,
       sum ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude group 
       ) sm_grp,
       sum ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude ties 
       ) sm_ties,
       count ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude current row 
       ) ct_curr,
       count ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude group 
       ) ct_grp,
       count ( window_id ) over ( w 
         rows between 1 preceding and 1 following exclude ties 
       ) ct_ties
from   windows
window w as ( 
  order by sort_column 
);

select distinct mapping_name from window_mappings;