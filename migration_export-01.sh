#!/bin/bash
#
# ============================================================
# Red Hat Consulting EMEA, 2021
#
# Created-------: 20211119
# ============================================================
# Description--: Export and Import
#                https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.5/html-single/server_administration_guide/index#assembly-exporting-importing_server_administration_guide
#                https://www.keycloak.org/docs/latest/server_installation/#profiles
#                https://www.keycloak.org/docs/latest/server_development/#using-keycloak-administration-console-to-upload-scripts
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


# Step 5: Source variables by environment
source ${V_ADMIN_DIR}/sso_install.properties
#
# Step 6: Prepare Java Arguments
EXPORT_ARGUMENTS="-Dkeycloak.profile=preview -Dkeycloak.migration.action=export -Dkeycloak.migration.usersExportStrategy=REALM_FILE"
EXPORT_ARGUMENTS="${EXPORT_ARGUMENTS} -Dkeycloak.migration.file=export_all.json -Dkeycloak.migration.provider=singleFile"
INITIALDELAY_SECONDS=360
APPNAME_EXPORT=sso
CONFIGMAP_NAME=${APPNAME_EXPORT}-cfgmap
#CONFIGMAP_NAME=${APPNAME_EXPORT}-admin
#

# Step 6.1: Check if ConfigMap exists
oc get cm ${CONFIGMAP_NAME} -n ${PROJECT_TARGET} &>/dev/null
if [ $? -eq ]
then
	CONFIGMAP=1
else
	CONFIGMAP=0
fi

# Step 7: Set environment variables JAVA_CUSTOM_ENV_EXT_PROPS
oc rollout pause dc ${APPNAME_EXPORT} -n ${PROJECT_TARGET}
oc patch dc ${APPNAME_EXPORT} -p '{"spec":{"template": {"spec": {"containers":[{"name": "'"${APPNAME_EXPORT}"'","livenessProbe": {"initialDelaySeconds":'${INITIALDELAY_SECONDS}'}}]}}}}' -n ${PROJECT_TARGET}
if [ ${CONFIGMAP} -eq1 ]
then
	oc patch configmap ${CONFIGMAP_NAME} -p '{"data":{"JAVA_OPTS_APPEND":"'"${EXPORT_ARGUMENTS}"'"}}' -n ${PROJECT_TARGET}
else
	oc set env dc/${APPNAME_EXPORT} JAVA_OPTS_APPEND="${EXPORT_ARGUMENTS}" -n ${PROJECT_TARGET}
fi
oc rollout resume dc ${APPNAME_EXPORT} -n ${PROJECT_TARGET}

#
exit 0

# EOF
