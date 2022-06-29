#!/bin/bash
set -x
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

if ! command -v &> /dev/null;
then 
	Echo "Error: You need to have \'tar\' command"
	exit 3
fi


# Step 1: Set current DIR and default variables:
V_ADMIN_DIR=$(dirname $0)

# Step 5: Source variables by environment
source ${V_ADMIN_DIR}/sso_install.properties
#
FILE_MIGRATION_NAME=export_all.json
FILE_MIGRATION_PATH=${V_ADMIN_DIR}/migration/${FILE_MIGRATION_NAME}
TAR_FILE=export_all.xz
TAR_FILE_PATH=${V_ADMIN_DIR}/migration/${TAR_FILE}
EXPORT_ARGUMENTS="-Dkeycloak.migration.action=import -Dkeycloak.migration.file=/export/${FILE_MIGRATION_NAME} -Dkeycloak.migration.provider=singleFile -Dkeycloak.migration.strategy=OVERWRITE_EXISTING -Dkeycloak.password.blacklists.path=/home/jboss/password-blacklists/"
CONFIGMAP_IMPORT_NAME=${APPLICATION_NAME}-import-data
CONFIG_VOLUME_NAME=${APPLICATION_NAME}-import-data-volume
INITIALDELAY_SECONDS=360

# Step 5.5: Create tar file
pushd ${V_ADMIN_DIR}/migration/
tar cvaf ${TAR_FILE} ${FILE_MIGRATION_NAME}
popd

#
# Step 6: Rollout: pause - configuration - resume
oc rollout pause dc ${APPLICATION_NAME} -n ${PROJECT_TARGET}
oc patch dc ${APPLICATION_NAME} -p '{"spec":{"template": {"spec": {"containers":[{"name": "'"${APPLICATION_NAME}"'","livenessProbe": {"initialDelaySeconds":'${INITIALDELAY_SECONDS}'}}]}}}}' -n ${PROJECT_TARGET}
oc set env dc/${APPLICATION_NAME} JAVA_CUSTOM_ENV_EXT_PROPS="${EXPORT_ARGUMENTS}" -n ${PROJECT_TARGET}
oc set env dc/${APPLICATION_NAME} SSO_REALM="" -n ${PROJECT_TARGET}

# Create PVC
oc set volume dc/${APPLICATION_NAME} --add --name=export --type=pvc --claim-name=${APPLICATION_NAME}-export --claim-size=1Gi --mount-path=/export


# create import secret
oc create secret generic ${CONFIGMAP_IMPORT_NAME} --from-file=${TAR_FILE_PATH} -n ${PROJECT_TARGET}
# set volume with the import data file
oc set volume dc/${APPLICATION_NAME} --add --name=${CONFIG_VOLUME_NAME} --type=secret --secret-name=${CONFIGMAP_IMPORT_NAME} --mount-path=/export/${TAR_FILE} --sub-path="${TAR_FILE}" -n ${PROJECT_TARGET} --overwrite

# Add init container
oc patch dc ${APPLICATION_NAME} -p '{"spec":{"template":{"spec":{"initContainers":[{"command":["sh", "-c", "cd /export; tar xavf '${TAR_FILE}'"],"name":"tarinit","image":"registry.access.redhat.com/rhel7/rhel-tools","volumeMounts":[{"name": "export", "mountPath": "/export"},{"name":"'${CONFIG_VOLUME_NAME}'","mountPath":"/export/'${TAR_FILE}'","subPath":"'${TAR_FILE}'"}]}]}}}}'

oc rollout resume dc ${APPLICATION_NAME} -n ${PROJECT_TARGET}

exit 0
# EOF
