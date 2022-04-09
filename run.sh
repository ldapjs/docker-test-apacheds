#!/usr/local/bin/dumb-init /bin/bash
# Copied from https://github.com/ome/apacheds-docker/blob/2d49b2a/scripts/run.sh

# Environment variables:
# APACHEDS_VERSION
# APACHEDS_INSTANCE
# APACHEDS_BOOTSTRAP
# APACHEDS_DATA
# APACHEDS_USER
# APACHEDS_GROUP

PIDFILE="${APACHEDS_INSTANCE_DIR}/run/apacheds-${APACHEDS_INSTANCE}.pid"

cleanup(){
    if [ -e "${PIDFILE}" ];
    then
        echo "Cleaning up ${PIDFILE}"
        rm "${PIDFILE}"
    fi
}

trap cleanup EXIT
cleanup

/opt/apacheds-${APACHEDS_VERSION}/bin/apacheds start ${APACHEDS_INSTANCE}
sleep 2  # Wait on new pid

shutdown(){
    echo "Shutting down..."
    /opt/apacheds-${APACHEDS_VERSION}/bin/apacheds stop ${APACHEDS_INSTANCE}
}

trap shutdown INT TERM
tail -n 0 --pid=$(cat ${PIDFILE}) -f ${APACHEDS_INSTANCE_DIR}/log/apacheds.log
