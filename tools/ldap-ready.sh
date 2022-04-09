#!/bin/bash

TRIES=0
READY=1
while [[ ${READY} -ne 0 && ${TRIES} -lt 9 ]]; do
  ldapsearch -x -H ldap://localhost:10389/ \
    -D ${LDAP_BINDDN} \
    -w ${LDAP_SECRET} \
    -LLL '(uid=admin)' 2>/dev/null 1>/dev/null
  READY=$?
  TRIES=$((TRIES+1))
  sleep 2
done

if [ ${TRIES} -eq 9 ]; then
  echo "LDAP server not ready in allotted limit!"
  exit 1
fi
