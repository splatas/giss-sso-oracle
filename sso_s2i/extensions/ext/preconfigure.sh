#!/bin/bash
JBOSS_HOME=/opt/eap
source $JBOSS_HOME/bin/launch/logging.sh

CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

log_info "JBOSS_HOME----------------: '$JBOSS_HOME'"
log_info "CONFIG_FILE---------------: '$CONFIG_FILE'"
log_info "SSO_REALM-----------------: '${SSO_REALM}'"
log_info "JAVA_CUSTOM_ENV_EXT_PROPS-: '${JAVA_CUSTOM_ENV_EXT_PROPS}'"
log_info "JAVA_OPTS_APPEND----------: '${JAVA_OPTS_APPEND}'"
log_info "CUSTOM_SSO_CACHES_MODE----: '${CUSTOM_SSO_CACHES_MODE}'"
log_info "TEST_MODE_H2--------------: '${TEST_MODE_H2}'"


function main() {
  log_info "preconfigure()--->Init"
  inject_ds
  config_spi_connectionsJpa
  config_sso_caches
  log_info "preconfigure()--->End"
}

function inject_ds() {

  if [ "${TEST_MODE_H2}" = "true" ]; then
    KEYCLOAKDS_NAME=KeycloakDSTest
  else
    KEYCLOAKDS_NAME=KeycloakDS
  fi
  log_info "inject_ds()--->Using KeyCloakDS Name: '${KEYCLOAKDS_NAME}'"

  ds_info="<datasource jta=\"true\" jndi-name=\"java:jboss/datasources/${KEYCLOAKDS_NAME}\" pool-name=\"${KEYCLOAKDS_NAME}\" enabled=\"true\" use-java-context=\"true\" spy=\"false\" use-ccm=\"true\" tracking=\"false\" enlistment-trace=\"false\" statistics-enabled=\"true\">\\
                    <connection-url>\${env.KEYCLOAKDS_CONNECTION_URL}</connection-url>\\
                    <driver>oracle</driver>\\
                    <transaction-isolation>TRANSACTION_READ_COMMITTED</transaction-isolation>\\
                    <pool>\\
                        <min-pool-size>\${env.KEYCLOAKDS_MIN_POOL_SIZE}</min-pool-size>\\
                        <initial-pool-size>\${env.KEYCLOAKDS_INIT_POOL_SIZE}</initial-pool-size>\\
                        <max-pool-size>\${env.KEYCLOAKDS_MAX_POOL_SIZE}</max-pool-size>\\
                        <prefill>false</prefill>\\
                        <use-strict-min>true</use-strict-min>\\
                        <flush-strategy>IdleConnections</flush-strategy>\\
                        <allow-multiple-users>false</allow-multiple-users>\\
                    </pool>\\
                    <security>\\
                        <user-name>\${env.DB_USERNAME}</user-name>\\
                        <password>\${env.DB_PASSWORD}</password>\\
                    </security>\\
                    <validation>\\
                        <valid-connection-checker class-name=\"org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker\"/>\\
                        <validate-on-match>false</validate-on-match>\\
                        <background-validation>true</background-validation>\\
                        <background-validation-millis>300000</background-validation-millis>\\
                        <use-fast-fail>false</use-fast-fail>\\
                        <stale-connection-checker class-name=\"org.jboss.jca.adapters.jdbc.extensions.oracle.OracleStaleConnectionChecker\"/>\\
                        <exception-sorter class-name=\"org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter\"/>\\
                    </validation>\\
                    <timeout>\\
                        <set-tx-query-timeout>true</set-tx-query-timeout>\\
                        <blocking-timeout-millis>180000</blocking-timeout-millis>\\
                        <idle-timeout-minutes>10</idle-timeout-minutes>\\
                        <query-timeout>180</query-timeout>\\
                        <allocation-retry>3</allocation-retry>\\
                        <allocation-retry-wait-millis>3000</allocation-retry-wait-millis>\\
                    </timeout>\\
                    <statement>\\
                        <track-statements>false</track-statements>\\
                        <prepared-statement-cache-size>200</prepared-statement-cache-size>\\
                        <share-prepared-statements>false</share-prepared-statements>\\
                    </statement>\\
                </datasource>"
	
  if [ "${TEST_MODE_H2}" = "true" ]; then
    # For Test: create h2 datasource
    sed -i "s|<!-- ##DATASOURCES## -->|${ds_info}\n<!-- ##DATASOURCES## -->|" $CONFIG_FILE
  else
    # Don't create h2 datasource, only our datasource:
    sed -i "s|<!-- ##DATASOURCES## -->|${ds_info}\n|" $CONFIG_FILE
  fi

  log_info "inject_ds()--->End"
}


function config_spi_connectionsJpa(){

  init_TRUE="<property name=\"initializeEmpty\" value=\"true\"/>"
  init_PARAM="<property name=\"initializeEmpty\" value=\"\${env.SPI_KEYCLOAKDS_INITIALIZE_EMPTY:true}\" />"
  sed -i "s|${init_TRUE}|${init_PARAM}|" $CONFIG_FILE

  init_TRUE="<property name=\"migrationStrategy\" value=\"update\"/>"
  init_PARAM="<property name=\"migrationStrategy\" value=\"\${env.SPI_KEYCLOAKDS_MIGRATION_STRATEGY:update}\" />"
  sed -i "s|${init_TRUE}|${init_PARAM}\n|" $CONFIG_FILE

  log_info "config_spi_connectionsJpa()--->End"
}

function config_sso_caches(){
  #CUSTOM_SSO_CACHES_MODE=distributed
  #CUSTOM_SSO_CACHES_MODE=replicated
  if [ -z "${CUSTOM_SSO_CACHES_MODE}" ]; then
    log_info "config_sso_caches()--->The CUSTOM_SSO_CACHES_MODE variable doesn't exist, we will use the default configuration"
    return
  fi

  log_info "config_sso_caches()--->(CUSTOM_SSO_CACHES_MODE) MODE: '${CUSTOM_SSO_CACHES_MODE}'"
  declare -a CACHE_NAMES=("sessions" "authenticationSessions" "offlineSessions" "clientSessions" "offlineClientSessions" "loginFailures" "actionTokens")
  if [ "${CUSTOM_SSO_CACHES_MODE}" = "distributed" ]; then
    log_info "config_sso_caches()--->Applying cache MODE: 'distributed'"
    for cache in ${CACHE_NAMES[@]}; do
      log_info "config_sso_caches()--->Updating the '${cache}' cache"
      defconf="<distributed-cache name=\"${cache}\" owners=\"[0-9]\+\""
      newconf="<distributed-cache name=\"${cache}\" owners=\"\${CUSTOM_SSO_CACHE_OWNERS:2}\""
      log_info "config_sso_caches()--->New owners: '${newconf}'"
      sed -i "s|${defconf}|${newconf}|" ${CONFIG_FILE}
    done
  elif [ "${CUSTOM_SSO_CACHES_MODE}" = "replicated" ]; then
    log_info "config_sso_caches()--->Applying cache MODE: 'replicated'"
    for cache in ${CACHE_NAMES[@]}; do
      log_info "config_sso_caches()--->Updating the '${cache}' cache"
      defconf="<distributed-cache name=\"${cache}\" owners=\"[0-9]\+\""
      newconf="<replicated-cache name=\"${cache}\""
      log_info "config_sso_caches()--->New owners: '${newconf}'"
      sed -i "s|${defconf}|${newconf}|" ${CONFIG_FILE}
    done
    # the whitespaces are important, please don't change it
    sed -in '$!N;s@max-idle="-1" interval="300000"/>\n                </distributed-cache>@max-idle="-1" interval="300000"/>\n                </replicated-cache>@;P;D' ${CONFIG_FILE}
    log_info "config_sso_caches()--->Closing </replicated-cache> (actionTokens cache)"
  fi
  log_info "config_sso_caches()--->End"
}


main

# EOF
