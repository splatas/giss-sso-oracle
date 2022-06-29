#!/bin/bash

injected_dir=$1

echo "[S2I install.sh] injected_dir: ${injected_dir}"
echo "[S2I install.sh] ENV_FILES---: ${ENV_FILES}"
source /usr/local/s2i/install-common.sh
source ${JBOSS_HOME}/bin/launch/launch-common.sh
#######################
cp ${injected_dir}/configuration/* ${JBOSS_HOME}/standalone/configuration/

# Copy datasources
mkdir -p ${JBOSS_HOME}/extensions/
if [ -d "${JBOSS_HOME}/extensions" ]
then
    cp ${injected_dir}/ext/* ${JBOSS_HOME}/extensions/
fi
####################
install_deployments ${injected_dir}/deployments/

install_modules ${injected_dir}/modules

configure_drivers ${injected_dir}/configuration/oracle_driver.properties
#######################


DEFAULT_LAUNCH=${JBOSS_HOME}/bin/openshift-launch.sh
sed -i 's/${JAVA_PROXY_OPTIONS}/${JAVA_PROXY_OPTIONS} ${JAVA_CUSTOM_ENV_EXT_PROPS}/g' $DEFAULT_LAUNCH

###
sed -i "s|<resolve-parameter-values>false</resolve-parameter-values>|<resolve-parameter-values>true</resolve-parameter-values>|" ${JBOSS_HOME}/bin/jboss-cli.xml

SSO_CLI_EXT=${JBOSS_HOME}/bin/launch/configure_sso_cli_extensions.sh
sed -i 's/function postConfigure() {/function postConfigure() {\n ##SED_ENV_VARS##/' ${SSO_CLI_EXT}

#upd_vars="sed -i \"s|#HTTPS_PASSWORD#|\${HTTPS_PASSWORD}|\" \${JBOSS_HOME}\/extensions\/sso-extension.properties\\
#  sed -i \"s|#SSO_TRUSTSTORE_PASSWORD#|\${SSO_TRUSTSTORE_PASSWORD}|\" \${JBOSS_HOME}\/extensions\/sso-extension.properties\\"
#sed -i "s|##SED_ENV_VARS##|${upd_vars}\n  ##SED_ENV_VARS##|" ${SSO_CLI_EXT}
#sed -i 's|$JBOSS_HOME/bin/jboss-cli.sh|$JBOSS_HOME/bin/jboss-cli.sh --properties=${JBOSS_HOME}/extensions/sso-extension.properties|' ${SSO_CLI_EXT}
#
# Propagate the trustore/keystore related variables to the jboss-cli script
sed -i 's|$JBOSS_HOME/bin/jboss-cli.sh|$JBOSS_HOME/bin/jboss-cli.sh -DHTTPS_KEYSTORE_DIR=${HTTPS_KEYSTORE_DIR} -DHTTPS_KEYSTORE=${HTTPS_KEYSTORE} -DHTTPS_PASSWORD=${HTTPS_PASSWORD} -DSSO_TRUSTSTORE=${SSO_TRUSTSTORE} -DSSO_TRUSTSTORE_DIR=${SSO_TRUSTSTORE_DIR} -DSSO_TRUSTSTORE_PASSWORD=${SSO_TRUSTSTORE_PASSWORD} |' ${SSO_CLI_EXT}

echo "[S2I install.sh] Prepared openshift-launch.sh"
#######################
#######################

echo "[S2I install.sh] End"
#
# EOF
