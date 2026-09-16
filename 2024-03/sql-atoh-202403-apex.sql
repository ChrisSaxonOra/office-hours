export ORDS_HOME=/u01/app/ords
export ORDS_CONFIG=/u01/app/config/ords
export ORDS_LOGS=${ORDS_CONFIG}/logs
export DB_PORT=1521
export DB_SERVICE=dbaas19c_pdb1.paas.oracle.com
export SYSDBA_USER=SYS
export SYSDBA_PASSWORD=testTEST1234##
export ORDS_PASSWORD=testTEST1234##

alter user ords_public_user identified by testTEST1234## account unlock;
alter user apex_listener identified by testTEST1234## account unlock;
alter user apex_public_user identified by testTEST1234## account unlock;
alter user apex_rest_public_user identified by testTEST1234## account unlock;

export ORDS_HOME=/u01/app/ords
export ORDS_CONFIG=/u01/app/config/ords
export ORDS_LOGS=${ORDS_CONFIG}/logs
export PATH=${ORDS_HOME}/bin:$PATH
ords --config ${ORDS_CONFIG} serve


${ORDS_HOME}/bin/ords --config ${ORDS_CONFIG} install \
     --log-folder ${ORDS_LOGS} \
     --admin-user ${SYSDBA_USER} \
     --db-hostname ${HOSTNAME} \
     --db-port ${DB_PORT} \
     --db-servicename ${DB_SERVICE} \
     --feature-db-api true \
     --feature-rest-enabled-sql true \
     --feature-sdw true \
     --gateway-mode proxied \
     --gateway-user APEX_PUBLIC_USER \
     --proxy-user \
     --password-stdin <<EOF
${SYSDBA_PASSWORD}
${ORDS_PASSWORD}
EOF