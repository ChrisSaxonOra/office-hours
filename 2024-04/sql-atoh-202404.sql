/****************************


      order by basics


****************************/
@sql-atoh-202404-setup.sql

-- Ascending sort (default)
select * from quiz_results
where  quiz_id = 1
order  by user_id /* asc */;

-- Descending sort
select * from quiz_results
where  quiz_id = 1
order  by user_id desc;







-- Ties => non-deterministic
select * from quiz_results
where  quiz_id = 1
order  by pct_correct;


-- Add columns to resolve ties
select * from quiz_results
where  quiz_id = 1
order  by pct_correct, seconds_taken;





-- Winners = most correct, then fastest
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc, seconds_taken;


-- Above equivalent to:
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls first, seconds_taken asc nulls last;






-- Force nulls to bottom of results
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken nulls last;







-- Change winner => accuracy / speed
select pct_correct/seconds_taken score, r.* 
from   quiz_results r
where  quiz_id = 1
order  by pct_correct/seconds_taken desc nulls last;







-- Update score => accuracy squared / square root speed
select power(pct_correct,2)/sqrt(seconds_taken) score, r.* 
from   quiz_results r
where  quiz_id = 1
order  by pct_correct/seconds_taken desc nulls last;
-- Ooops!






-- order by alias
select power(pct_correct,2)/sqrt(seconds_taken) score, r.* 
from   quiz_results r
where  quiz_id = 1
order  by score desc nulls last;






/****************************


      Row limiting/Top-N


****************************/

-- 12c onwards syntax
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last
-- At most 3 rows
fetch  first 3 rows only;






-- Get all rows with the same value as the Nth row
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last
-- All rows with same PCT_CORRECT as row 3
fetch  first 3 rows with ties;





-- Ties => all sort columns equal
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
fetch  first 3 rows with ties;






-- Get top N% 
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
-- N => ceil ( count(*) * 3 / 100 ) => 309 * 3 / 100 => 9.27 => 10
fetch  first 3 percent rows only;






-- Check the performance
-- Order by sorts & fetches full result set
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken;

select * from dbms_xplan.display_cursor ( format => 'ALLSTATS LAST' );
-- primary key = ( quiz_id, user_id )







-- Performance of Top-N queries 
-- Fetches the full data set, then sorts top-N
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
fetch  first 3 rows only;

select * from dbms_xplan.display_cursor ( format => 'ALLSTATS LAST' );




-- Fetch 100 => sort 100 rows
select * from quiz_results
where  quiz_id = 1
order  by pct_correct
fetch  first 100 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');





-- Make an index it improve performance: Here's one I made earlier
-- create index qure_quiz_correct_i 
  -- on quiz_results ( quiz_id, pct_correct ) invisible;

-- make it available
alter index qure_quiz_correct_i visible;



-- Database only reads N rows!
select * from quiz_results
where  quiz_id = 1
order  by pct_correct 
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');




-- Database can also read the index in reverse
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');






-- Index must include all sort expressions to avoid sort
select * from quiz_results
where  quiz_id = 1
order  by pct_correct, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');




-- Here's another one I made earlier...
-- create index qure_quiz_correct_time_i
  -- on quiz_results ( quiz_id, pct_correct, seconds_taken );

alter index qure_quiz_correct_time_i visible;


select * from quiz_results
where  quiz_id = 1
order  by pct_correct, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');




-- ...but we can't mix asc/desc!
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');



-- Here's another one I made earlier...
-- create index qure_quiz_correct_desc_time_asc_i
  -- on quiz_results ( quiz_id, pct_correct desc, seconds_taken );

alter index qure_quiz_correct_desc_time_asc_i visible;


-- ... and we're back to a nosort!
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');






-- ... but not if nulls are last :(
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');





-- Negated asc => desc nulls last
select * from quiz_results
where  quiz_id = 1
order  by -pct_correct, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');



-- Function-based index to support this
-- create index qure_quiz_correct_minus_time_i
  -- on quiz_results ( quiz_id, -pct_correct, seconds_taken );

alter index qure_quiz_correct_minus_time_i visible;

-- Back to a nosort!
select * from quiz_results
where  quiz_id = 1
order  by -pct_correct, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');




/****************************


      Pagination - N->M


****************************/

-- Get first 10 rows
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
fetch  first 10 rows only;





-- Get next 10 rows
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
-- Skip 10 rows, start at row 11
offset 10 rows 
fetch  first 10 rows only;

-- Get rows 301-310
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
offset 300 rows 
fetch  first 10 rows only;








-- Problem #1 - Consistent results
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
fetch  first 10 rows only;
-- Last row user id = 90660





-- Problem #1a - duplicate results
insert into quiz_results values ( 1, 0, sysdate, sysdate, 100, 30 );

-- Get next 10 rows
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
offset 10 rows 
fetch  first 10 rows only;
-- See user 90660 again!
-- First two rows, % correct = 98




-- Problem #1b - missing results
delete quiz_results
where  quiz_id = 1
and    pct_correct = 100;

-- 98% results missing from output
select * from quiz_results
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
offset 10 rows 
fetch  first 10 rows only;


-- Possible solution: Flashback query 
select * from quiz_results 
  -- Use first query time rather than offset
  as of timestamp sysdate - interval '60' second
where  quiz_id = 1
order  by pct_correct desc nulls last, seconds_taken
offset 10 rows 
fetch  first 10 rows only;


-- Revert back
rollback;






-- Problem #2 - Performance
set timing on
select * from quiz_results
order  by pct_correct desc nulls last, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');


-- ...gradually gets slower
select * from quiz_results
order  by pct_correct desc nulls last, seconds_taken
offset 100000 rows 
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');



-- ... and can hit performance cliff
select * from quiz_results
order  by pct_correct desc nulls last, seconds_taken
offset 750000 rows 
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor ( format => 'ALLSTATS LAST');







-- Rows 750011 on
-- Remember last values for sort cols & filter on these
-- => only sorting N rows again!
select * from quiz_results
where  pct_correct < 94.56 
or   ( pct_correct = 94.56 and seconds_taken >= 250 ) 
order  by pct_correct desc nulls last, seconds_taken
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor( format => 'ALLSTATS LAST');
-- But check the results carefully...






-- Include column(s) to make sort unique
select * from quiz_results
where pct_correct < 94.56 
or   ( pct_correct = 94.56 and seconds_taken > 250 )
or   ( pct_correct = 94.56 and seconds_taken = 250 and user_id > 26628 )
or   ( pct_correct = 94.56 and seconds_taken = 250 and user_id = 26628 and quiz_id > 5402346 )
order  by pct_correct desc nulls last, seconds_taken, user_id, quiz_id
fetch  first 10 rows only;

select * from dbms_xplan.display_cursor ( format => 'ALLSTATS LAST');





-- Why can't we just do this?
select * from quiz_results
where  pct_correct <= 94.56
and    seconds_taken >= 250
and    user_id >= 26628 
and    quiz_id > 5402346
order  by pct_correct desc nulls last, seconds_taken, user_id, quiz_id
fetch  first 10 rows only;







-- We've missed data!
select * from quiz_results
where pct_correct < 94.56 
or   ( pct_correct = 94.56 and seconds_taken > 250 )
or   ( pct_correct = 94.56 and seconds_taken = 250 and user_id > 26628 )
or   ( pct_correct = 94.56 and seconds_taken = 250 and user_id = 26628 and quiz_id > 5402346 )
order  by pct_correct desc nulls last, seconds_taken, user_id, quiz_id
fetch  first 10 rows only;








-- Verify 
select * from quiz_results
order  by pct_correct desc nulls last, seconds_taken, user_id, quiz_id
offset 750010 rows 
fetch  first 10 rows only;

/****************************


            Fin


****************************/









/****************************


         Top-N/group


****************************/


-- Top-N/group
with rws as (
  select qr.*, 
         row_number() over ( 
           partition by user_id 
           order by finish_date desc nulls last
         ) rn
  from   quiz_results qr
)
select * from rws
where  rn <= 3
order  by user_id, rn;




-- SELECT DISTINCT - can only order by selected expressions
select distinct pct_correct
from   quiz_results 
where  quiz_id = 1
order  by seconds_taken;


-- 
select * from (
  select pct_correct
  from   quiz_results 
  where  quiz_id = 1
)
order  by seconds_taken;



select distinct pct_correct
from   quiz_results 
where  quiz_id = 1
order  by pct_correct;

