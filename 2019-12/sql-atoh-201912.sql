@sql-atoh-201912-setup


/* What's wrong with this join? */
select c.*, pen_type, shape, toy_name  
from   colours c 
join   pens p 
on     c.colour = p.colour 
join   toys t 
on     c.colour = t.colour 
join   bricks b 
on     c.colour = b.colour;














--Fix the stats!
begin   
  dbms_stats.gather_table_stats ( null, 'bricks', no_invalidate => false ); 
  dbms_stats.gather_table_stats ( null, 'colours', no_invalidate => false ); 
end; 
/

select c.*, pen_type, shape, toy_name  
from   colours c 
join   pens p 
on     c.colour = p.colour 
join   toys t 
on     c.colour = t.colour 
join   bricks b 
on     c.colour = b.colour;








-- What about this plan?
select * 
from   colours  
natural join bricks 
where  colours.rgb_hex_value = 'FF0000' 
and    brick_id = 1;











/* Create some indexes! */
alter table bricks 
  add constraint bricks_pk 
  primary key ( brick_id );

create index colour_i  
  on colours ( colour );

select * 
from   colours  
natural join bricks 
where  colours.rgb_hex_value = 'FF0000' 
and    brick_id = 1;










select (  
         select count(*)  
         from   bricks b 
         where  b.colour = c.colour  
       ) brick# 
from   colours c;













-- Join! (colours.colour must be mandatory; otherwise outer join)
select count(*)  
from   colours c
join   bricks b 
on     b.colour = c.colour 
group  by c.colour;









-- Even better! (colours.colour must be mandatory)
select count(*)  
from   bricks b 
group  by b.colour;









create index brick_colour_i  
  on bricks ( colour );

select count(*)  
from   bricks b 
group  by b.colour;






select count(*)  
from   bricks b 
where  b.colour is not null 
group  by b.colour;

-- OR

alter table bricks 
  modify colour not null;

select count(*)  
from   bricks b 
group  by b.colour;  





select (  
         select count(*)  
         from   bricks b 
         where  b.colour = c.colour  
       ) brick# 
from   colours c;


