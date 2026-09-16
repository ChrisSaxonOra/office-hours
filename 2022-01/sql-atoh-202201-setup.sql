
drop table windows
  cascade constraints purge;
drop table window_mappings
  cascade constraints purge;

create table windows (	
  window_id    number(*,0), 
	group_column number(*,0), 
	sort_column  number(*,0)
);

create table window_mappings (
  mapping_name varchar2(100),
  window_id    integer,
  target_id    integer,
  primary key (
    mapping_name, window_id, target_id
  )
);


begin 
  insert into windows (window_id,group_column,sort_column) values (1,1,1);
  insert into windows (window_id,group_column,sort_column) values (2,2,1);
  insert into windows (window_id,group_column,sort_column) values (3,2,1);
  insert into windows (window_id,group_column,sort_column) values (4,1,2);
  insert into windows (window_id,group_column,sort_column) values (5,2,2);
  insert into windows (window_id,group_column,sort_column) values (6,3,4);
end;
/

/* PARTITION BY */
begin 
  insert into window_mappings 
    values ( 'PARTITION BY', 1, 1  );
  insert into window_mappings 
    values ( 'PARTITION BY', 1, 4  );
  insert into window_mappings 
    values ( 'PARTITION BY', 4, 1  );
  insert into window_mappings 
    values ( 'PARTITION BY', 4, 4  );
  insert into window_mappings 
    values ( 'PARTITION BY', 4, 6  );
    
  insert into window_mappings 
    values ( 'PARTITION BY', 6, 6  );

  insert into window_mappings 
    values ( 'PARTITION BY', 2, 2 );
  insert into window_mappings 
    values ( 'PARTITION BY', 2, 3 );
  insert into window_mappings 
    values ( 'PARTITION BY', 2, 5 );
  insert into window_mappings 
    values ( 'PARTITION BY', 3, 2 );
  insert into window_mappings 
    values ( 'PARTITION BY', 3, 3 );
  insert into window_mappings 
    values ( 'PARTITION BY', 3, 5 );
  insert into window_mappings 
    values ( 'PARTITION BY', 5, 2 );
  insert into window_mappings 
    values ( 'PARTITION BY', 5, 3 );
  insert into window_mappings 
    values ( 'PARTITION BY', 5, 5 );
    
end;
/

/* ORDER BY CURRENT ROW */
begin 
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 1, 1  );

  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 2, 1  );
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 2, 2  );

  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 3, 1  );
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 3, 2  );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 3, 3 );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 4, 1 );
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 4, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 4, 4 );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 5, 1 );
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 5, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 5, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 5, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 5, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 6, 1 );
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 6, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 6, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 6, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 6, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS CURRENT ROW', 6, 6 );
    

  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 1, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 1, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 1, 3 );

  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 2, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 2, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 2, 3 );

  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 3, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 3, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 3, 3 );
    
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 4, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 4, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 4, 4 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 4, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 5, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 5, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 5, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 5, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 5, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 6, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 6, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 6, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 6, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 6, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE CURRENT ROW', 6, 6 );    
    

  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 1, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 1, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 1, 3 );

  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 2, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 2, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 2, 3 );

  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 3, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 3, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 3, 3 );
    
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 4, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 4, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 4, 4 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 4, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 5, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 5, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 5, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 5, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 5, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 6, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 6, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 6, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 6, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 6, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS CURRENT ROW', 6, 6 ); 
end;
/


/* ORDER BY 1 PRECEDING AND 1 FOLLOWING */
begin 
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 1, 1  );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 1, 2  );

  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 2, 1  );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 2, 2  );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 2, 3  );

  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 3, 2  );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 3, 3 );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 3, 4  );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 4, 4 );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 4, 5 );  
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 5, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 5, 5 );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 5, 6 );  
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 6, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING', 6, 6 );
    

  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 1, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 1, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 1, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 1, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 1, 5 );

  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 2, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 2, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 2, 3 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 2, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 2, 5 );

  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 3, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 3, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 3, 3 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 3, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 3, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 4, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 4, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 4, 4 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 4, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 5, 1 );
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 5, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 5, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 5, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 5, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY RANGE 1 PRECEDING AND 1 FOLLOWING', 6, 6 );    
   

  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 1, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 1, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 1, 3 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 1, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 1, 5 );

  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 2, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 2, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 2, 3 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 2, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 2, 5 );

  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 3, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 3, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 3, 3 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 3, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 3, 5 );
    
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 4, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 4, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 4, 4 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 4, 5 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 4, 6 );
    
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 5, 1 );
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 5, 2 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 5, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 5, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 5, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 5, 6 );
    
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 6, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 6, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY GROUPS 1 PRECEDING AND 1 FOLLOWING', 6, 6 ); 
end;
/



/* ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE */
begin 
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 1, 2  );

  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 2, 1  );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 2, 3  );

  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 3, 2  );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 3, 4  );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 4, 5 );  
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 5, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 5, 6 );  
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE CURRENT ROW', 6, 5 );  
    
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE GROUP', 4, 3 );  
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE GROUP', 5, 6 );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE GROUP', 6, 4 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE GROUP', 6, 5 );     
   

  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 1, 1 );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 2, 2 );  
  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 3, 3 );
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 3, 4 );  
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 4, 3 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 4, 4 );
    
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 5, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 5, 6 );
     
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 6, 5 );  
  insert into window_mappings 
    values ( 'ORDER BY ROWS 1 PRECEDING AND 1 FOLLOWING EXCLUDE TIES', 6, 6 ); 
end;
/


/* PARTITION BY ORDER BY CURRENT ROW */
begin 
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 1, 1  );

  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 2, 2  );

  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 3, 2 );
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 3, 3 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 4, 1 );
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 4, 4 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 5, 2 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 5, 3 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 5, 5 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY ROWS CURRENT ROW', 6, 6 );
    

  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 1, 1 );

  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 2, 2 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 2, 3 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 3, 2 );
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 3, 3 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 4, 1 );
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 4, 4 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 5, 2 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 5, 3 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 5, 5 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY RANGE CURRENT ROW', 6, 6 );    
    

  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 1, 1 );

  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 2, 2 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 2, 3 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 3, 2 );
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 3, 3 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 4, 1 );
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 4, 4 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 5, 2 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 5, 3 );  
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 5, 5 );
    
  insert into window_mappings 
    values ( 'PARTITION BY ORDER BY GROUPS CURRENT ROW', 6, 6 ); 
end;
/


/* LAG/LEAD */
begin 
  insert into window_mappings 
    values ( 'LEAD', 1, 2  );

  insert into window_mappings 
    values ( 'LAG', 2, 1  );
  insert into window_mappings 
    values ( 'LEAD', 2, 3  );

  insert into window_mappings 
    values ( 'LAG', 3, 2  );  
  insert into window_mappings 
    values ( 'LEAD', 3, 4  );
    
  insert into window_mappings 
    values ( 'LAG', 4, 3 );  
  insert into window_mappings 
    values ( 'LEAD', 4, 5 );  
    
  insert into window_mappings 
    values ( 'LAG', 5, 4 );  
  insert into window_mappings 
    values ( 'LEAD', 5, 6 );  
    
  insert into window_mappings 
    values ( 'LAG', 6, 5 );  
    
end;
/

/* LAG/LEAD BY 2 */
begin 
  insert into window_mappings 
    values ( 'LEAD BY 2', 1, 3  );

  insert into window_mappings 
    values ( 'LEAD BY 2', 2, 4  );

  insert into window_mappings 
    values ( 'LAG BY 2', 3, 1  );  
  insert into window_mappings 
    values ( 'LEAD BY 2', 3, 5  );
    
  insert into window_mappings 
    values ( 'LAG BY 2', 4, 2 );  
  insert into window_mappings 
    values ( 'LEAD BY 2', 4, 6 );  
    
  insert into window_mappings 
    values ( 'LAG BY 2', 5, 3 );   
    
  insert into window_mappings 
    values ( 'LAG BY 2', 6, 4 );  
    
end;
/



/* LAG/LEAD PARTITION BY */
begin 
  insert into window_mappings 
    values ( 'LEAD PARTITION BY', 1, 4  );

  insert into window_mappings 
    values ( 'LEAD PARTITION BY', 2, 3  );
    
  insert into window_mappings 
    values ( 'LEAD PARTITION BY', 3, 5  );
  insert into window_mappings 
    values ( 'LAG PARTITION BY', 3, 2  );

    
  insert into window_mappings 
    values ( 'LAG PARTITION BY', 4, 1 );   
    
  insert into window_mappings 
    values ( 'LAG PARTITION BY', 5, 3 );   
    
end;
/
commit;
--cl scr
