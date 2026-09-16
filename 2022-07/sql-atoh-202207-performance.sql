set serveroutput on
begin
  timing_pkg.set_start_time;
  indate_data();
  timing_pkg.calc_runtime ( 'insert-update inserts' );
  remove_half();
  timing_pkg.set_start_time;
  indate_data();
  timing_pkg.calc_runtime ( 'insert-update 50:50' );
  timing_pkg.set_start_time;
  indate_data();
  timing_pkg.calc_runtime ( 'insert-update updates' );
  
  execute immediate 'alter table customers_dim move including rows where customer_id < 1 online';
  
  timing_pkg.set_start_time;
  upsert_data();
  timing_pkg.calc_runtime ( 'update-insert inserts' );
  remove_half();
  timing_pkg.set_start_time;
  upsert_data();
  timing_pkg.calc_runtime ( 'update-insert 50:50' );
  timing_pkg.set_start_time;
  upsert_data();
  timing_pkg.calc_runtime ( 'update-insert updates' );
  
  execute immediate 'alter table customers_dim move including rows where customer_id < 1 online';
  
  timing_pkg.set_start_time;
  merge_data();
  timing_pkg.calc_runtime ( 'merge inserts' );
  remove_half();
  timing_pkg.set_start_time;
  merge_data();
  timing_pkg.calc_runtime ( 'merge 50:50' );
  timing_pkg.set_start_time;
  merge_data();
  timing_pkg.calc_runtime ( 'merge updates' );
  
  execute immediate 'alter table customers_dim move including rows where customer_id < 1 online';
  
end;
/
/
/
/
/