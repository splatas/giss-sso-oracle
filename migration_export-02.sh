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
SRC_POD_MIGRATION=/home/jboss/export_all.json
FOLDER_MIGRATION=${V_ADMIN_DIR}/migration
#
RESTORE_EXPORT_ARGUMENTS="-Dkeycloak.profile=preview"
APPNAME_EXPORT=sso
INITIALDELAY_SECONDS=160
CONFIGMAP_NAME=${APPNAME_EXPORT}-cfgmap
#CONFIGMAP_NAME=${APPNAME_EXPORT}-admin

# Step 6: Check if ConfigMap exists
oc get cm ${CONFIGMAP_NAME} -n ${PROJECT_TARGET} &>/dev/null
if [ $? -eq 0 ]
then
	CONFIGMAP=1
else
	CONFIGMAP=0
fi

mkdir -p ${FOLDER_MIGRATION}
#
POD_NAME=$(oc get pods -o  go-template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep -v "postgresql")
#
#
if [ -z ${POD_NAME} ]; then
  echo "There is no POD running."
  exit 1
else
  echo "We will get the '${SRC_POD_MIGRATION}' information file from the '$POD_NAME' pod to '${FOLDER_MIGRATION}'"
  echo "We will use: 'oc rsync ${POD_NAME}:${SRC_POD_MIGRATION} ${FOLDER_MIGRATION}'"
  oc rsync ${POD_NAME}:${SRC_POD_MIGRATION} ${FOLDER_MIGRATION}
  RESULT=$?
  if [ ${RESULT} -ne 0 ]; then
    echo "Ups! An error has occured."
  else
    oc rollout pause dc ${APPNAME_EXPORT} -n ${PROJECT_TARGET}
    oc patch dc ${APPNAME_EXPORT} -p '{"spec":{"template": {"spec": {"containers":[{"name": "'"${APPNAME_EXPORT}"'","livenessProbe": {"initialDelaySeconds":'${INITIALDELAY_SECONDS}'}}]}}}}' -n ${PROJECT_TARGET}
    if [ ${CONFIGMAP} -eq 1 ]
    then
    	oc patch configmap ${CONFIGMAP_NAME} -p '{"data":{"JAVA_OPTS_APPEND":"'"${RESTORE_EXPORT_ARGUMENTS}"'"}}' -n ${PROJECT_TARGET}
    else
	oc set env dc/${APPNAME_EXPORT} JAVA_OPTS_APPEND="${RESTORE_EXPORT_ARGUMENTS}" -n ${PROJECT_TARGET}
    fi
    oc rollout resume dc ${APPNAME_EXPORT} -n ${PROJECT_TARGET}
    oc scale --replicas=0 dc/${APPNAME_EXPORT} -n ${PROJECT_TARGET}
  fi
fi

exit 0
# EOF
