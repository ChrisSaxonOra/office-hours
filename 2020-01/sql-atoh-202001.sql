@sql-atoh-202001-setup




select * from card_deck;


info+ card_deck







/* Equality */
select count(*)
from   card_deck d1
join   card_deck d2
on     d1.suit = d2.suit
and    d1.card_value = d2.card_value;








/* Range */
select count(*)
from   card_deck d1
join   card_deck d2
on     d1.suit < d2.suit
and    d1.card_value < d2.card_value;






/* Inequality */
select count(*)
from   card_deck d1
join   card_deck d2
on     d1.suit <> d2.suit
and    d1.card_value <> d2.card_value;









/* Random Top-N */
select *
from   card_deck d1
join   card_deck d2
on     d1.suit = d2.suit
and    d1.card_value = d2.card_value

fetch  first 5 rows only;







/* Sorted Top-N search */
select *
from   card_deck d1
join   card_deck d2
on     d1.suit = d2.suit
and    d1.card_value = d2.card_value
order  by d1.card_value
fetch  first 5 rows only;









drop index card_value_suit_i ;
create index card_value_suit_i 
  on card_deck ( card_value, suit );

/* Top-N join+sort on first col of index */
select *
from   card_deck d1
join   card_deck d2
on     d1.suit = d2.suit
and    d1.card_value = d2.card_value
order  by d1.card_value
fetch first 5 rows only;






select *
from   card_deck d1
join   card_deck d2
on     d1.suit = d2.suit
and    d1.card_value = d2.card_value
order  by d1.notes
fetch first 5 rows only;












/* Filtering & Joining 

info+ card_deck
*/
select *
from   card_deck d1
join   card_deck d2
on     d1.card_value = d2.card_value
and    d1.suit = d2.suit
where  d1.damaged = 'Y';






update card_deck
set    damaged = 'Y'
where  card_id between 1 and 10;

commit;


select *
from   card_deck d1
join   card_deck d2
on     d1.card_value = d2.card_value
and    d1.suit = d2.suit
where  d1.damaged = 'Y';

select * 
from   table(dbms_xplan.display_cursor(null, null, 'ROWSTATS LAST'));

exec dbms_stats.gather_table_stats ( user, 'card_deck', no_invalidate => false ) ;

select * 
from   card_deck d1
join   card_deck d2
on     d1.suit = d2.suit
and    d1.card_value = d2.card_value
where  d1.damaged = 'Y';

select * 
from   table(dbms_xplan.display_cursor(null, null, 'ROWSTATS LAST'));


select * 
from   card_deck d1
join   card_deck d2
on     d1.suit = d2.suit
and    d1.card_value = d2.card_value
where  d1.damaged = 'Y';

select * 
from   table(dbms_xplan.display_cursor(null, null, 'ROWSTATS LAST +ADAPTIVE'));











create unique index card_notes_u 
  on card_deck ( notes );


select *
from   card_deck d1
join   card_deck d2
on     d1.card_value = d2.card_value
where  d1.notes = 'SQL is awesome!';


select * 
from   table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST +ADAPTIVE'));

