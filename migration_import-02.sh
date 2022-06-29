#!/bin/bash
#
# ============================================================
# Red Hat Consulting EMEA, 2021
#
# Created-------: 20211119
# ============================================================
# Description--: Export and Import
#                https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.5/html-single/server_administration_guide/index#export_import
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

# Step 5: Create the template
source ${V_ADMIN_DIR}/sso_install.properties
#
CONFIGMAP_IMPORT_NAME=${APPLICATION_NAME}-import-data
CONFIG_VOLUME_NAME=${APPLICATION_NAME}-import-data-volume
INITIALDELAY_SECONDS=160

# Step 6: Rollout: pause - configuration - resume
oc rollout pause dc ${APPLICATION_NAME} -n ${PROJECT_TARGET}
oc patch dc ${APPLICATION_NAME} -p '{"spec":{"template": {"spec": {"containers":[{"name": "'"${APPLICATION_NAME}"'","livenessProbe": {"initialDelaySeconds":'${INITIALDELAY_SECONDS}'}}]}}}}' -n ${PROJECT_TARGET}
oc patch dc ${APPLICATION_NAME} --type=json --patch '[{"op": "remove", "path": "/spec/template/spec/initContainers"}]'

oc set env dc/${APPLICATION_NAME} JAVA_CUSTOM_ENV_EXT_PROPS="${JAVA_CUSTOM_ENV_EXT_PROPS}" -n ${PROJECT_TARGET}
oc set volume dc/${APPLICATION_NAME} --remove --name=${CONFIG_VOLUME_NAME} -n ${PROJECT_TARGET}
oc set volume dc/${APPLICATION_NAME} --remove --name=export -n ${PROJECT_TARGET}
oc delete secret ${CONFIGMAP_IMPORT_NAME} -n ${PROJECT_TARGET}
oc rollout resume dc ${APPLICATION_NAME} -n ${PROJECT_TARGET}
#

exit 0
# EOF
