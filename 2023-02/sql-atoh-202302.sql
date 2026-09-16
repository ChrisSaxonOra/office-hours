@@sql-atoh-202302-setup


create table students (
  student_id    integer 
    constraint student_pk 
    primary key,
  email_address varchar2(320)
    constraint stud_email_u 
    unique,
  registration_number varchar2(100)
);




/* Tables can only have one PK! */
alter table students 
  add primary key ( registration_number );

/* Many UCs are possible */
alter table students 
  add unique ( registration_number );


/* See the constraints */
select constraint_name, constraint_type 
from   user_constraints
where  table_name = 'STUDENTS';




/* Add first row */
insert into students values ( 1, 'first.id@test.com', 'ABC123' );
commit;

select * from students;




/* Duplicates prevented! */
insert into students values ( 1, 'duplicate.id@test.com', 'DEF456' );
insert into students values ( 2, 'first.id@test.com', 'GHI879' );
insert into students values ( 3, 'duplicate.reg@test.com', 'ABC123' );




/* Nulls for UCs but not PKs */
insert into students values ( null, 'null.id@test.com', 'JKL123' );
insert into students values ( 4, null, null );
insert into students values ( 5, null, null );
commit;

select * from students;





/* Not case sensitive! */
insert into students values ( 6, 'FIRST.ID@TEST.COM', 'abc123' );

/* Case insensitive column counts */
with rws as (
  select 
    /* Enable case-insenstive comparison */
    email_address collate binary_ci email_ci,
    registration_number collate binary_ci reg_ci
  from   students
)
  select email_ci, reg_ci, count(*) 
  from   rws
  group  by email_ci, reg_ci
  having count(*) > 1;



/* Remove the duplicate */
delete students
where  student_id = 6;



/* Let's make email address case sensistive 
   Need to remove the existing constraint first
*/
alter table students 
  drop unique ( email_address );





/* Can't have function-based constraints */
alter table students 
  add unique ( email_address collate binary_ci );







/* Can create a unique FBI */
create unique index stud_email_u
  on students ( email_address collate binary_ci );


/* PKs and UCs create indexes by default */
select index_name, index_type, uniqueness,
       column_name, data_default
from   user_indexes
join   user_ind_columns using ( table_name, index_name )
join   user_tab_cols using ( table_name, column_name )
where  table_name = 'STUDENTS';




/* Now with case sensitivity! */
insert into students values ( 6, 'FIRST.ID@TEST.COM', 'ZZZ999' );





/* Let's emulate the unique func-based index */
drop index stud_email_u;


/* Make column case insenstive by default (12.2) */
alter table students
  modify email_address collate binary_ci;
  
  
/* Now constraint is also case insensitive! */
alter table students 
  add constraint stud_email_u
  unique ( email_address );

insert into students values ( 6, 'FIRST.ID@TEST.COM', 'abc123' );



/* Creates unique func index */
select index_name, index_type, uniqueness,
       column_name, data_default
from   user_indexes
join   user_ind_columns using ( table_name, index_name )
join   user_tab_cols using ( table_name, column_name )
where  table_name = 'STUDENTS';





/* By default dropping constraint removes index */
alter table students
  drop unique ( registration_number );

/* Remove constraint but preserve index */
alter table students
  drop primary key
  drop index;

select index_name, index_type, 
       column_name, data_default
from   user_indexes
join   user_ind_columns using ( table_name, index_name )
join   user_tab_cols using ( table_name, column_name )
where  table_name = 'STUDENTS';




/* Pick specific index to use for constraint */
alter table students
  add constraint student_pk
  primary key ( student_id );



/*****************************




*****************************/

create table courses (
  course_id   integer 
    constraint course_pk primary key,
  course_code varchar2(30)
    constraint cour_code_u unique
);

insert into courses values ( 1, 'SQL101' );
insert into courses values ( 2, 'PLSQL101' );
commit;


/* Foreign keys default to primary keys */
create table student_courses (
  student_id 
    constraint stco_student_fk
    references students,
  course_id  
    constraint stco_course_fk
    references courses,
  constraint student_course_pk
    primary key ( student_id, course_id )
);


/* Data types inherited from parent columns */
select column_name, data_type, data_length, data_precision, data_scale
from   user_tab_columns
where  table_name = 'STUDENT_COURSES';



/* Can only insert values that exist in parent tables */
insert into student_courses values ( 1, 1 );
insert into student_courses values ( 1, 2 );
insert into student_courses values ( 2, 99 );
insert into student_courses values ( 42, 2 );


select * from student_courses;



drop table student_courses
  cascade constraints purge;
  
/* But FKs can point to UCs too! */
create table student_courses (
  email_address 
    constraint stco_student_fk
    references students ( email_address ),
  course_code
    constraint stco_course_fk
    references courses ( course_code ),
  constraint student_course_pk
    primary key ( email_address, course_code )
);

select column_name, data_type, data_length, data_precision, data_scale
from   user_tab_columns
where  table_name = 'STUDENT_COURSES';

insert into student_courses values ( 'first.id@test.com', 'SQL101' );
insert into student_courses values ( 'first.id@test.com', 'ZZZZZZ' );
insert into student_courses values ( 'missing@test.com', 'SQL101' );

select * from student_courses;








/* So why not point FKs at UCs? 
   The cascading update problem! */
update students
set    email_address = 'new@test.com'
where  email_address = 'first.id@test.com';




/* Reset to use PK */
drop table student_courses
  cascade constraints purge;

create table student_courses (
  student_id 
    constraint stco_student_fk
    references students ( student_id ),
  course_id  
    constraint stco_course_fk
    references courses,
  constraint student_course_pk
    primary key ( student_id, course_id )
);

insert into student_courses values ( 1, 1 );
commit;

/* Can now update email address */
update students
set    email_address = 'new@test.com'
where  email_address = 'first.id@test.com';



/* Store exam results
   Student could sit many exams for a module
   1:M relationship STUDENT_COURSES -< STUDENT_COURSE_RESULTS
*/


/* Can inherit data type with composite FKs! */
create table student_course_results (
  student_course_result_id integer
    constraint student_course_result_pk
    primary key,
  student_id ,
  course_id  ,
  exam_id    integer,
  percent_correct number,
  constraint stcr_student_course_fk
    foreign key ( student_id, course_id )
    references student_courses,
  unique ( student_id, course_id, exam_id )
);


insert into student_course_results values ( 1, 1, 1, 1, 0 );
insert into student_course_results values ( 2, 99, 99, 1, 0 );

select * from student_course_results;





/* But beware partial nullable FKs... */
insert into student_course_results values ( 3, 99, null, 1, 0 );



/* ...you can insert orphaned rows! */
select * from student_course_results stcr
where  not exists (
  select * from student_courses stco
  where  stco.student_id = stcr.student_id
);


/*****************************




*****************************/

truncate table student_course_results;
  
  
/* Add NN check */
alter table student_course_results
  add constraint stcr_course_nn 
  check ( course_id is not null );  
  
/* Can't add out-of-line NN constraint */
alter table student_course_results
  add constraint stcr_student_nn
  student_id integer not null;
  
/* Change the column to be NN */
alter table student_course_results
  modify (
    student_id constraint stcr_student_nn not null
  );




/* NOT NULL & CHECK ( ... NOT NULL ) look the same... */
select constraint_name, constraint_type, search_condition 
from   user_constraints
where  table_name = 'STUDENT_COURSE_RESULTS'
and    constraint_type = 'C';
/* So why use NN? */






/* More specific error message */ 
insert into student_course_results values ( 1, 99, null, 1, 0 );
insert into student_course_results values ( 2, null, 99, 1, 0 );



/* Better dictionary data */
select column_name, nullable 
from   user_tab_columns
where  table_name = 'STUDENT_COURSE_RESULTS'
and    column_name in ( 'STUDENT_ID', 'COURSE_ID' );



/* Optimizer knows NN => all values are NN */
select * from student_course_results
where  student_id is null;

/* ...it doesn't with check constraints  */
select * from student_course_results
where  course_id is null;





/* But what if we want to make the FK optional?! 
   => set all its columns or none
   Make the columns optional first
*/
alter table student_course_results
  modify ( student_id null );
  
alter table student_course_results
  drop constraint stcr_course_nn;



/* Check constraint to validate both or neither are null */
alter table student_course_results
  add constraint stcr_student_course_both_neither_nn
  check (
    coalesce ( student_id, course_id ) is null
    or ( student_id is not null and course_id is not null )
  );

/* Optional multi-column FKs */
insert into student_course_results values ( 1, 1, 1, 1, 0 );
insert into student_course_results values ( 2, null, null, 1, 0 );

insert into student_course_results values ( 3, 99, null, 1, 0 );
insert into student_course_results values ( 4, null, 99, 1, 0 );

select * from student_course_results;




/* Check to prevent impossible results */
alter table student_course_results 
  add constraint stcr_percent_correct_0_to_100
  check ( percent_correct between 0 and 100 );



truncate table student_course_results;
/* Constraints only reject FALSE rows */
insert into student_course_results values ( 1, 1, 1, 2, -9999 );
insert into student_course_results values ( 2, 1, 1, 3,  9999 );
insert into student_course_results values ( 3, 1, 1, 4,  null );



/* Queries only return rows with TRUE conditions */
select * from student_course_results
where  percent_correct between 0 and 100
or     percent_correct not between 0 and 100;


select * from student_course_results;




/* Optimizer can use check constraints in general */
select * from student_course_results
where  percent_correct < 0;



/*****************************




*****************************/

/* Dealing with junk data! */

drop table student_course_results 
  cascade constraints purge;
  
create table student_course_results (
  student_id integer,
  course_id  integer,
  exam_id    integer,
  percent_correct number
);

insert into student_course_results
  select student_id, course_id, 
         1, round ( dbms_random.value ( -100, 1000 ) )
  from   students 
  cross  join courses
  /* Insert duplicates */
  cross  join ( select * from dual connect by level <= 2 );

  
select * from student_course_results
order  by 1, 2, 3;





/* There's junk data - can't validate */
alter table student_course_results
  add constraint stcr_percent_c
  check ( percent_correct between 0 and 100 );
 
 
 
/* Run in ANOTHER session */
--insert into student_course_results 
--  values ( 1, 1, 1, 999 );

/* It's also a blocking operation */
alter table student_course_results
  add constraint stcr_percent_c
  check ( percent_correct between 0 and 100 );
  

/* NOVALIDATE is non-blocking DDL */
alter table student_course_results
  add constraint stcr_percent_c
  check ( percent_correct between 0 and 100 )
  novalidate;
  
/* No more junk! */
insert into student_course_results 
  values ( 1, 1, 1, 9999 );
commit;



update student_course_results
set    percent_correct = 0
where  percent_correct not between 0 and 100;

alter table student_course_results
  modify constraint stcr_percent_c
  validate;





/* Can NOVALIDATE not null constraints */
alter table student_course_results
  modify student_id 
  constraint stcr_student_nn not null 
  novalidate;
  
/* Can NOVALIDATE not null constraints */
alter table student_course_results
  modify constraint stcr_student_nn
  validate;


/* What about the duplicates?! */
alter table student_course_results
  add constraint student_course_result_pk
  primary key (  
    student_id, course_id, exam_id 
  )
  novalidate;
  
  
  
  
  
/* Need non-unique index to police constraint! */  
alter table student_course_results
  add constraint student_course_result_pk
  primary key ( 
    student_id, course_id, exam_id 
  )
  using index (
    /* Can create new index or use existing here */
    create index stcr_student_course_date_i
      on student_course_results ( 
      student_id, course_id, exam_id 
    ) 
  )
  novalidate;
  
/* Duplicates now prevented */
insert into student_course_results values ( 5, 5, 5, 1 );
insert into student_course_results values ( 5, 5, 5, 99 );


/* Remove duplicates to validate it */
delete student_course_results
where  rowid not in ( 
  select min ( rowid )
  from   student_course_results
  group  by student_id, course_id, exam_id
);

alter table student_course_results
  modify constraint student_course_result_pk
  validate;




/* What about copying constraints with CTAS? */
create table student_course_results_backup as 
  select * from student_course_results;
  
select * from student_courses;
  
/* Only not null constraints copied */
select constraint_name, table_name, constraint_type, search_condition 
from   user_constraints
where  table_name like 'STUDENT_COURSE_RESULT%'
order  by 1, 2;



create table student_course_results_backup_constraints (
  student_id,
  course_id,
  exam_id not null,
  percent_correct check ( percent_correct between 0 and 100 ),
  primary key ( student_id, course_id, exam_id )
) as 
  select * from student_course_results
  where  nvl ( percent_correct, -1 ) between 0 and 100;
  
select constraint_name, table_name, constraint_type, search_condition 
from   user_constraints
where  table_name = 'STUDENT_COURSE_RESULTS_BACKUP_CONSTRAINTS'
order  by 1, 2;


/*****************************




*****************************/