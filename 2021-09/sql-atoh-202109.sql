/* Generate 1,000 rows with values [0, 100] */
with rws as (
  select dbms_random.value ( 0, 100 ) x
  from   dual connect by level <= 1000
)
  select * from rws;
  
  
  
  
  

/* 4 groups, same number of rows in each (quartiles) */
with rws as (
  select dbms_random.value ( 0, 100 ) x
  from   dual connect by level <= 1000
), grps as (
  select x, 
         ntile ( 4 ) over ( order by x ) grp
  from   rws
)
  select grp, count (*) row#, 
         round ( min ( x ), 1 ) lower_bound, 
         round ( max ( x ), 1 ) upper_bound
  from   grps
  group  by grp order by grp;
  
  
  
  
/* Quartiles - normal distribution */  
with rws as (
  select ( 10 * dbms_random.normal ) + 50 x
  from   dual connect by level <= 1000
), grps as (
  select x, 
         ntile ( 4 ) over ( order by x ) grp
  from   rws
)
  select grp, count(*), 
         round ( min ( x ), 1 ), 
         round ( max ( x ), 1 )
  from   grps
  group  by grp order  by grp;
  
  


/* Spit into intervals of consistent size */
with rws as (
  select dbms_random.value ( 0, 100 ) x
  from   dual connect by level <= 1000
), grps as (
  select x, 
         -- intervals [0, 25), [25, 50), [50, 75), [75, 100)
         width_bucket ( x, 0, 100, 4 ) bucket
  from   rws
)
  select bucket, count(*), 
         round ( min ( x ), 1 ), 
         round ( max ( x ), 1 )
  from   grps
  group  by bucket order by bucket;
  
  
  
  
/* Normal distribution with equal intervals */
with rws as (
  select ( 10 * dbms_random.normal ) + 50 x
  from   dual connect by level <= 1000
), grps as (
  select x, 
         width_bucket ( x, 0, 100, 4 ) bucket
  from   rws
)
  select bucket, count(*), 
         round ( min ( x ), 1 ), 
         round ( max ( x ), 1 )
  from   grps
  group  by bucket order by bucket;
  
  
  
  
/* Generate range dynamically */
with rws as (
  select ( 10 * dbms_random.normal ) + 50 x
  from   dual connect by level <= 1000
), grps as (
  select x, width_bucket ( 
           x, 
           min ( x ) over () + 1, 
           max ( x ) over () + /*1, --/**/0,
           4 
         ) bucket
  from   rws
)
  select bucket, count(*), 
         round ( min ( x ), 1 ), 
         round ( max ( x ), 1 ),
         round ( max ( x ) - min ( x ), 1 ) bucket_range
  from   grps
  group  by bucket order by bucket;
  
  
  
  
/* Bucket by starting letter */
with rws as (
  select initcap ( dbms_random.string ( 'u', 10 ) ) x
  from   dual connect by level <= 1000 
), ranks as (
  select x, substr ( x, 1, 1 ) letter,
         dense_rank () over ( order by substr ( x, 1, 1 ) ) dr
  from   rws
)
  select * from ranks;
  


with rws as (
  select initcap ( dbms_random.string ( 'u', 10 ) ) x
  from   dual connect by level <= 1000 
), ranks as (
  select x, substr ( x, 1, 1 ) letter,
         dense_rank () over ( order by substr ( x, 1, 1 ) ) dr
  from   rws
), grps as ( 
  select x, letter, width_bucket ( 
           dr, 1, 27, 4 
         ) grp
  from   ranks
)
  select min ( letter ), max ( letter ),
         count ( distinct letter ) value#,
         count (*) row#,
         min ( x ), max ( x ) 
  from   grps
  group  by grp order by grp;
  
  
  
/* Bar chart of jobs */
select job_id, count(*) from hr.employees
group  by job_id
order  by job_id;
/* How to group these? */


/* Bucket by string - all rows with same string in same bucket */ 
with rws as (
  select dense_rank () over ( order by job_id ) dr, e.*
  from   hr.employees e
), grps as (
  select r.*, 
         width_bucket ( dr, 1, max ( dr ) over () + 1, 4 ) bucket
  from   rws r
)
  select bucket,
         count ( distinct job_id ) job_count,
         count(*) row_count, 
         listagg ( distinct job_id, ',' )  
           within group ( order by job_id ) jobs
  from   grps
  group  by bucket;




/* Be careful with character data! */
with rws as (
  select first_name x
  from   hr.employees
), ranks as (
  select x, substr ( x, 1, 1 ) letter,
         dense_rank () over ( order by substr ( x, 1, 1 ) ) dr
  from   rws
), grps as ( 
  select x, letter, width_bucket ( 
           dr, 1, 27, 4 
         ) grp
  from   ranks
)
  select * from ranks;
  select min ( letter ), max ( letter ),
         count ( distinct letter ) value#,
         count (*) row#,
         min ( x ), max ( x ) 
  from   grps
  group  by grp order by grp;



/* Use ASCII character codes instead */
with rws as (
  select first_name x
  from   hr.employees
), ranks as (
  select x, substr ( x, 1, 1 ) letter,
         ascii ( substr ( x, 1, 1 ) ) - 64 dr
  from   rws
), grps as ( 
  select x, letter, width_bucket ( 
           dr, 1, 27, 4 
         ) grp
  from   ranks
)
  select min ( letter ), max ( letter ),
         count ( distinct letter ) value#,
         count (*) row#,
         min ( x ), max ( x ) 
  from   grps
  group  by grp order by grp;


/************************************************





************************************************/
  
  
/* N rows/bucket */
with rws as (
  select dbms_random.value ( 0, 100 ) x, level id, 7 n
  from   dual
  connect by level <= dbms_random.value ( 100, 1000 )
), grps as (
  select x, n,
         row_number () over ( order by id ) rn
  from   rws
)
  select ceil ( rn / n ), count(*),
         round ( min ( x ) ), round ( max ( x ) )
  from   grps
  group  by ceil ( rn / n ) order by ceil ( rn / n ); 
  
  
  
  
  
/* Split into values of 5 */
with rws as (
  select dbms_random.value ( 0, 100 ) x,
         5 interval_size
  from   dual connect by level <= 1000
), grps as (
  select floor ( x / interval_size ) * interval_size x,
         interval_size
  from   rws
)
  select x, x + interval_size,
         count(*)
  from   grps
  group  by x, interval_size
  order  by x;
  

alter session set nls_date_format = '  DD-MON HH24:MI  ';
alter session set nls_timestamp_format = '  DD-MON HH24:MI  ';

/* 5 min intervals */
with rws as (
  select timestamp'2021-09-01 00:00:00' + 
           numtodsinterval ( dbms_random.value ( 0, 120 ), 'minute' ) x,
         6 interval_mins
  from   dual connect by level <= 1000
), grps as (
  select x, interval_mins, trunc ( x ) dt,
         floor ( 
            -- convert to minutes past midnight
            ( extract ( hour from x ) + 1 ) * extract ( minute from x ) 
              / interval_mins 
         ) * interval_mins mins
  from   rws
)
  select dt + mins/1440 st, dt + ( mins + interval_mins ) / 1440 en, 
         count (*)
  from   grps
  group  by dt + mins/1440, dt + ( mins + interval_mins ) / 1440 order by dt + mins/1440;
  
  
/* What's the problem with these? */







/* Only works if there's a value in every interval! */
with rws as (
  select timestamp'2021-09-01 00:00:00' + 
           numtodsinterval ( dbms_random.value ( 0, 120 ), 'minute' ) x,
         5 interval_mins
  from   dual connect by level <= 10
), grps as (
  select x, interval_mins, trunc ( x ) dt,
         floor ( 
            -- convert to minutes past midnight
            ( extract ( hour from x ) + 1 ) * extract ( minute from x ) 
              / interval_mins 
         ) * interval_mins mins
  from   rws
)
  select dt + mins/1440 st, dt + ( mins + interval_mins ) / 1440 en, 
         count (*)
  from   grps
  group  by dt + mins/1440, dt + ( mins + interval_mins ) / 1440 order by dt + mins/1440;







/* General case
   Generate all the intervals first, 
   then outer join the data */
with intervals as (
  select 5 interval_size, 
         timestamp'2021-09-01 00:00:00' lower_bound, 
         120 total_minutes 
  from   dual
), grps as (
  select lower_bound + numtodsinterval ( ( level - 1 ) * interval_size, 'minute' ) mn_x,
         lower_bound + numtodsinterval ( level * interval_size, 'minute' ) mx_x,
         interval_size
  from   intervals
  connect by level <= ( 
    -- unknown data size; create a range for all possible values
    select max ( ceil ( total_minutes / interval_size ) ) 
    from   intervals
  )
), rws as (
  select lower_bound + 
           numtodsinterval ( dbms_random.value ( 0, 120 ), 'minute' ) x
  from   intervals connect by level <= 25
)
  select mn_x, mx_x, 
         count ( x ) rws_per_group 
  from   grps
  left join rws
  on     x >= mn_x
  and    x < mx_x
  group  by mn_x, mx_x order by mn_x;
  
  

/* General case - create the ranges, outer join data to this */
with intervals as (
  select 5 interval_size, 0 lower_bound, 100 upper_bound
  from   dual
), grps as (
  select ( level - 1 ) * interval_size mn_x,
         level * interval_size mx_x,
         interval_size
  from   intervals
  connect by level <= ( 
    -- unknown data size; create a range for all possible values
    select max ( ceil ( upper_bound / interval_size ) ) from intervals
  )
), rws as (
  select dbms_random.value ( lower_bound, upper_bound ) x
  from   intervals connect by level <= 25
)
  select mn_x, mx_x, 
         count ( x ) rws_per_group 
  from   grps
  left join rws
  on     x >= mn_x
  and    x < mx_x
  group  by mn_x, mx_x order by mn_x;


with rws as (
  select level x 
  from   dual
  connect by level <= 10
)
  select x, sum ( x ) over (), 
     ratio_to_report ( x ) over () , 
       x / sum ( x ) over ()
  from rws;
  
 
  
  
