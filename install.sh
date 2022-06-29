#!/bin/bash
#
# ============================================================
# Red Hat Consulting EMEA, 2021
#
# Created-------: 20211119
# ============================================================
# Description--: Download ImageStream RH-SSO 7.5
#               https://catalog.redhat.com/software/containers/rh-sso-7/sso75-openshift-rhel8/611418806e1e42ca4d6decf1?container-tabs=overview
# ============================================================
#
# ============================================================
# Pre Steps---:
# chmod 774 *.sh
# ============================================================
#
#
#
# EOH
# Step 0: Get project
if [ $# -eq 0 ];
then
	echo "Error: You must specify a project to deploy RH SSO"
	exit 1
fi
PROJECT_TARGET=$1
oc get project $PROJECT_TARGET 2>/dev/null
if [ $? -ne 0 ];
then
	echo "Error: The project you has specified does not exists"
	exit 2
fi

# Step 1: Set current DIR and default variables:
V_ADMIN_DIR=$(dirname $0)


# Step 2: Create the template
PROPERTIES_PATH=${V_ADMIN_DIR}/sso_install.properties
TEMPLATE_PATH=${V_ADMIN_DIR}/nb-sso7-x509-oracle-persistent.yaml

oc replace -f ${TEMPLATE_PATH} -n ${PROJECT_TARGET} --force

# Step 6: Get templates
oc get templates -n ${PROJECT_TARGET} | grep sso7

# Step 7: Create Application using a properties file
oc new-app --template=nb-sso7-x509-oracle-persistent --param-file=${PROPERTIES_PATH} -n ${PROJECT_TARGET}

exit 0
# EOF
