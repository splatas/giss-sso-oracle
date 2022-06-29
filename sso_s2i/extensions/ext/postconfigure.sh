#!/bin/bash
source $JBOSS_HOME/bin/launch/logging.sh

CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

log_info "JBOSS_HOME----------------: '$JBOSS_HOME'"
log_info "CONFIG_FILE---------------: '$CONFIG_FILE'"
log_info "JAVA_CUSTOM_ENV_EXT_PROPS-: '${JAVA_CUSTOM_ENV_EXT_PROPS}'"
log_info "SSO_REALM-----------------: '${SSO_REALM}'"

function main() {
  log_info "postconfigure()--->Init"
  log_info "postconfigure()--->End"
}


main

# EOF
