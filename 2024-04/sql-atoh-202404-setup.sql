alter index qure_quiz_correct_desc_time_asc_i invisible;
alter index qure_quiz_correct_time_i invisible;
alter index qure_quiz_correct_i invisible;
alter index qure_quiz_correct_minus_time_i invisible;
alter session set statistics_level = all;
set serveroutput off
alter index qure_user_date_i invisible;
alter index qure_user_i visible;