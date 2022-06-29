#!/bin/bash
#
# ============================================================
# Red Hat Consulting EMEA, 2021
#
# Created-------: 20211119
# ============================================================
# Description--: Download ImageStream RH-SSO 7.5
#                registry.redhat.io/rh-sso-7/sso75-openshift-rhel8
#
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
source ${V_ADMIN_DIR}/.credentials
source ${V_ADMIN_DIR}/sso_install.properties

# Create Secrets for minishift
oc create secret generic ${GIT_SECRET}                   --from-literal="username=${GIT_CRED_USERNAME}"       --from-literal="password=${GIT_CRED_PWD}"        --type=kubernetes.io/basic-auth -n ${PROJECT_TARGET}
oc create secret generic ${DB_CREDENTIALS_SECRET}        --from-literal="username=${SSO_DB_CRED_USERNAME}"    --from-literal="password=${SSO_DB_CRED_PWD}"     --type=kubernetes.io/basic-auth -n ${PROJECT_TARGET}
oc create secret generic ${SSO_ADMIN_CREDENTIALS_SECRET} --from-literal="username=${SSO_ADMIN_CRED_USERNAME}" --from-literal="password=${SSO_ADMIN_CRED_PWD}"  --type=kubernetes.io/basic-auth -n ${PROJECT_TARGET}
oc create secret generic ${SSO_SRV_CREDENTIALS_SECRET}   --from-literal="username=${SSO_SRV_CRED_USERNAME}"   --from-literal="password=${SSO_SRV_CRED_PWD}"    --type=kubernetes.io/basic-auth -n ${PROJECT_TARGET}


# Create blacklist configmap
oc create configmap passwordblacklist --from-file=10_million_password_list_top_100000.txt -n ${PROJECT_TARGET}

# EOF
