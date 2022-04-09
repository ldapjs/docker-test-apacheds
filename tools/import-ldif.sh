#!/bin/bash

ldapadd -x -H ldap://localhost:10389/ \
    -D ${LDAP_BINDDN} \
    -w ${LDAP_SECRET} \
    -f ${1}
