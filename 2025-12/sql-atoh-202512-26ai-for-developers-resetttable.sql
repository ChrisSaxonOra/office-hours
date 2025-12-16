create or replace package body test_data 
as 
  
  test_date timestamp;
  function get_test_date return timestamp as
  begin
    return test_date;
  end;

begin
  test_date := cast ( trunc ( systimestamp ) as timestamp );
end;
/

alter package test_data compile body;






create or replace package body test_data 
  resettable -- Continue without raising ORA-4068
as 
  
  test_date timestamp;
  function get_test_date return timestamp as
  begin
    return test_date;
  end;

begin
  test_date := cast ( trunc ( systimestamp ) as timestamp );
end;
/

alter package test_data compile body;