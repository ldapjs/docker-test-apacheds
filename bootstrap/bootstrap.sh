#!/bin/bash

set -e

BOOTSTRAP_DIR=/opt/bootstrap
CONFIG_DIR=${BOOTSTRAP_DIR}/config
DATA_DIR=${BOOTSTRAP_DIR}/data/

echo "Bootstrapping server ..."
apacheds start default
ldap-ready
wait

data=$(find ${CONFIG_DIR} -maxdepth 1 -name \*_\*.ldif -type f | sort)
for ldif in ${data}; do
  echo "Processing file ${ldif}..."
  ldapadd -x -H ldap://localhost:10389/ \
    -D ${LDAP_BINDDN} \
    -w ${LDAP_SECRET} \
    -f ${ldif}
done

apacheds restart default
ldap-ready
wait

echo "Load data..."
data=$(find ${DATA_DIR} -maxdepth 1 -name \*_\*.ldif -type f | sort)
for ldif in ${data}; do
  echo "Processing file ${ldif}..."
  ldapadd -x -H ldap://localhost:10389/ \
    -D ${LDAP_BINDDN} \
    -w ${LDAP_SECRET} \
    -f ${ldif}
done

apacheds stop default
cd /var/lib/apacheds-${APACHEDS_VERSION}/
tar cf /build_out/data.tar .
