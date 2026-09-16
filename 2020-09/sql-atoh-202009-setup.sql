drop materialized view daily_brick_summary;

drop table bricks
  cascade constraints purge;
  
drop table colours
  cascade constraints purge;
  
create table bricks (
  brick_id integer
    not null,
  insert_datetime date
    not null,
  colour varchar2(10)
    not null,
  shape  varchar2(10)
    not null,
  weight integer
    not null
);

create table colours (
  colour_name varchar2(10)
    not null,
  rgb_hex_value varchar2(6)
    not null
);

insert into colours 
  values ( 'red', 'FF0000' );
insert into colours 
  values ( 'blue', '0000FF' );
insert into colours 
  values ( 'green', '00FF00' );
insert into colours 
  values ( 'yellow', 'FFFF00' );

insert into bricks
with rws as (
  select level x from dual
  connect by level <= 10000
)
  select rownum,
         date'2001-08-03' + ( rownum / 14320 ),
         case ceil ( rownum / 25000000 )
           when 1 then 'red'
           when 2 then 'blue'
           when 3 then 'green'
           when 4 then 'yellow'
         end colour, 
         case mod ( rownum, 5 )
           when 0 then 'cube'
           when 1 then 'cylinder'
           when 2 then 'pyramid'
           when 3 then 'prism'
           when 4 then 'cone'
         end shape,
         round ( dbms_random.value ( 1, 10 ) )
  from   rws cross join rws;

commit;

alter table bricks 
  add primary key ( brick_id );
  
create index bric_date_colour_weight_i
  on bricks ( trunc ( insert_datetime ), colour, weight )
  invisible;
  
create index bric_date_i
  on bricks ( trunc ( insert_datetime ) )
  invisible;
  
create materialized view daily_brick_summary
as 
  select trunc ( insert_datetime ) insert_date, 
         colour,
         count (*) num_bricks,
         sum ( weight ) total_weight
  from   bricks
  group  by trunc ( insert_datetime ), colour;
  
alter table bricks
  inmemory 
  priority high
  memcompress for capacity low
  no inmemory ( brick_id );
  
select count ( shape ) from bricks;