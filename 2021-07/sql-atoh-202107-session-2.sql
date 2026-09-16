select * from orders
where  order_id = 1403;

/* Back to session 1 */






insert into orders values ( 0, '{}' );

/* Back to session 1 */





select * from dba_dml_locks
where  owner = user;

rollback;
/* Back to session 1 */





insert into orders values ( 0, '{}' );
/* Back to session 1 */




rollback;
/* Back to session 1 */







/* GTT data are private */
select * from orders_gtt;