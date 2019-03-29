#!/bin/bash
#
# Copyright (c) AppDynamics Inc
# All rights reserved
#
# Maintainer: David Ryder, david.ryder@appdynamics.com
#
# Auto configure the AppDynamics agents: Machine Agent, Analytics Agent,
# Database and Applicaiton Agent
#
# Document References
# https://docs.appdynamics.com/display/PRO45/Installing+Agent-Side+Components


# Configure the following environment varibales to meet the requirements of the AppDynamics Deployment
#
# Controller host name
# APPDYNAMICS_CONTROLLER_HOST_NAME

# Controller port: 8090, 443
# APPDYNAMICS_CONTROLLER_PORT

# SSL enabled: true | false
# APPDYNAMICS_CONTROLLER_SSL_ENABLED

# The location of the Analytics Event Service API.
# APPDYNAMICS_EVENTS_SERVICE_ENDPOINT

# The customer name field from the appdynamics license page.
# APPDYNAMICS_AGENT_ACCOUNT_NAME

# The global name account in the Controller to which this Analytics data is associated.
# APPDYNAMICS_GLOBAL_ACCOUNT_NAME

# Replace this value with the access key of the account name configured above.
# APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY

_validateEnvironmentVars() {
  VAR_LIST=("$@") # rebuild using all args
  echo $VAR_LIST
  for i in "${VAR_LIST[@]}"; do
     [ -z ${!i} ] && { echo "Environment variable not set: $i"; ERROR="1"; }
  done
  [ "$ERROR" == "1" ] && { echo "Exiting"; exit 1; }
}

_modify_XML_file() {
  PROPERTY=$1
  VALUE=$2
  MFILE=$3
  echo "Updating " $PROPERTY  "to ["$VALUE"] in "$MFILE
  # eg # <controller-host></controller-host>
  sed -i".backup" "s/<$PROPERTY>.*<\/$PROPERTY>/<$PROPERTY>$VALUE<\/$PROPERTY>/g" "$MFILE"
}

_modify_Properties_file() {
  echo "Updating properties $1 to $2 in $3"
  V1=$(printf '%s\n' "$1"      | sed 's/[[\.*^$/]/\\&/g'   )
  NEW_VAL=$(printf '%s\n' "$2" | sed 's/[[\.*^$/]/\\&/g'   )
  MFILE=$3
  sed -i".backup"  "s/.*$V1.*/$V1=$NEW_VAL/" "$MFILE"
}

SAFE_FOR_SED="sed 's/[[\.*^$/]/\\&/g'"

_copyFileTimeStamp() {
  FILE_NAME=$1
  echo "TS $FILE_NAME"
  if [ -e $FILE_NAME ]; then
    TS=`date +%Y%m%d-%H%M%S`
    cp $FILE_NAME $FILE_NAME.backup.$TS
  else
    echo 'Copy Time Stamp: File does not exist: [$FILE_NAME]'
  fi
}

_analyticsPropertiesFile_Modify() {
  APPD_ANALYTICS_PROPERTIES_FILE=$1
  # Backup existing properties file
  _copyFileTimeStamp $APPD_ANALYTICS_PROPERTIES_FILE

  # Modify Analytics Configuration
  _modify_Properties_file ad.controller.url      $CONTROLLER_URL                           $APPD_ANALYTICS_PROPERTIES_FILE
  _modify_Properties_file http.event.endpoint    $APPDYNAMICS_EVENTS_SERVICE_ENDPOINT      $APPD_ANALYTICS_PROPERTIES_FILE
  _modify_Properties_file http.event.name        $APPDYNAMICS_AGENT_ACCOUNT_NAME           $APPD_ANALYTICS_PROPERTIES_FILE
  _modify_Properties_file http.event.accountName $APPDYNAMICS_GLOBAL_ACCOUNT_NAME          $APPD_ANALYTICS_PROPERTIES_FILE
  _modify_Properties_file http.event.accessKey   $APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY     $APPD_ANALYTICS_PROPERTIES_FILE
}

_analyticsPropertiesFile_Validate() {
  APPD_ANALYTICS_PROPERTIES_FILE=$1
  grep ad.controller.url      $APPD_ANALYTICS_PROPERTIES_FILE
  grep http.event.endpoint    $APPD_ANALYTICS_PROPERTIES_FILE
  grep http.event.name        $APPD_ANALYTICS_PROPERTIES_FILE
  grep http.event.accountName $APPD_ANALYTICS_PROPERTIES_FILE
  grep http.event.accessKey   $APPD_ANALYTICS_PROPERTIES_FILE
}

_machineAgent_Configure() {
  CONTROLLER_INFO_XML_FILE=$1

  if [ -e $CONTROLLER_INFO_XML_FILE ]; then
    _validateEnvironmentVars "APPDYNAMICS_AGENT_ACCOUNT_NAME"  "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY" "APPDYNAMICS_SIM_ENABLED" \
                             "APPDYNAMICS_CONTROLLER_PORT" "APPDYNAMICS_CONTROLLER_SSL_ENABLED" "APPDYNAMICS_CONTROLLER_HOST_NAME"
     # Backup existing properties file
     _copyFileTimeStamp $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-host           $APPDYNAMICS_CONTROLLER_HOST_NAME      $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-port           $APPDYNAMICS_CONTROLLER_PORT           $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-ssl-enabled    $APPDYNAMICS_CONTROLLER_SSL_ENABLED    $CONTROLLER_INFO_XML_FILE
    _modify_XML_file account-name              $APPDYNAMICS_AGENT_ACCOUNT_NAME        $CONTROLLER_INFO_XML_FILE
    _modify_XML_file account-access-key        $APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY  $CONTROLLER_INFO_XML_FILE
    _modify_XML_file sim-enabled               $APPDYNAMICS_SIM_ENABLED               $CONTROLLER_INFO_XML_FILE
  else
    echo "Machine Agent, Controller Info XML file does not exist: [$APPD_ANALYTICS_PROPERTIES_FILE]"
  fi
}

_applicationAgent_Configure() {
  CONTROLLER_INFO_XML_FILE=$1

  if [ -e $CONTROLLER_INFO_XML_FILE ]; then
    _validateEnvironmentVars "APPDYNAMICS_AGENT_ACCOUNT_NAME"  "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY" \
                             "APPDYNAMICS_CONTROLLER_PORT" "APPDYNAMICS_CONTROLLER_SSL_ENABLED" "APPDYNAMICS_CONTROLLER_HOST_NAME"
    # Backup existing properties file
    _copyFileTimeStamp $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-host           $APPDYNAMICS_CONTROLLER_HOST_NAME      $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-port           $APPDYNAMICS_CONTROLLER_PORT           $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-ssl-enabled    $APPDYNAMICS_CONTROLLER_SSL_ENABLED    $CONTROLLER_INFO_XML_FILE
    _modify_XML_file account-name              $APPDYNAMICS_AGENT_ACCOUNT_NAME        $CONTROLLER_INFO_XML_FILE
    _modify_XML_file account-access-key        $APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY  $CONTROLLER_INFO_XML_FILE
  else
    echo "Application Agent, Controller Info XML file does not exist: [$APPD_ANALYTICS_PROPERTIES_FILE]"
  fi
}

_databaseAgent_Configure() {
  CONTROLLER_INFO_XML_FILE=$1
  # Backup existing properties file
  _copyFileTimeStamp $CONTROLLER_INFO_XML_FILE

  if [ -e $CONTROLLER_INFO_XML_FILE ]; then
    _validateEnvironmentVars "APPDYNAMICS_AGENT_ACCOUNT_NAME"  "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY" \
                             "APPDYNAMICS_CONTROLLER_PORT" "APPDYNAMICS_CONTROLLER_SSL_ENABLED" "APPDYNAMICS_CONTROLLER_HOST_NAME"
    # Backup existing properties file
    _copyFileTimeStamp $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-host           $APPDYNAMICS_CONTROLLER_HOST_NAME      $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-port           $APPDYNAMICS_CONTROLLER_PORT           $CONTROLLER_INFO_XML_FILE
    _modify_XML_file controller-ssl-enabled    $APPDYNAMICS_CONTROLLER_SSL_ENABLED    $CONTROLLER_INFO_XML_FILE
    _modify_XML_file account-name              $APPDYNAMICS_AGENT_ACCOUNT_NAME        $CONTROLLER_INFO_XML_FILE
    _modify_XML_file account-access-key        $APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY  $CONTROLLER_INFO_XML_FILE
  else
    echo "Database Agent, Controller Info XML file does not exist: [$APPD_ANALYTICS_PROPERTIES_FILE]"
  fi
}

_analyticsProperties_Configure() {
  APPD_ANALYTICS_PROPERTIES_FILE=$1
  if [ -e $APPD_ANALYTICS_PROPERTIES_FILE ]; then
    _validateEnvironmentVars "APPDYNAMICS_EVENTS_SERVICE_ENDPOINT" "APPDYNAMICS_AGENT_ACCOUNT_NAME" \
                             "APPDYNAMICS_GLOBAL_ACCOUNT_NAME"  "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY" \
                             "APPDYNAMICS_CONTROLLER_PORT" "APPDYNAMICS_CONTROLLER_SSL_ENABLED" "APPDYNAMICS_CONTROLLER_HOST_NAME"
    _analyticsPropertiesFile_Modify $APPD_ANALYTICS_PROPERTIES_FILE
    _analyticsPropertiesFile_Validate $APPD_ANALYTICS_PROPERTIES_FILE
  else
    echo "Machine Agent, Analytics Properties file does not exist: [$APPD_ANALYTICS_PROPERTIES_FILE]"
  fi
}



_test() {
  echo "test [$1] [$2] [$3]"
}

# This is the URL of the Appdynamics Controller. The port is the same port number you use to access the
# Appdynamics browser-based user interface. The Format should be http://<host>:<port>
_validateEnvironmentVars "APPDYNAMICS_CONTROLLER_PORT" "APPDYNAMICS_CONTROLLER_SSL_ENABLED" "APPDYNAMICS_CONTROLLER_HOST_NAME"
HTTP_PROTOCOL="http"
[ "$APPDYNAMICS_CONTROLLER_SSL_ENABLED" = "true" ] && { HTTP_PROTOCOL="https"; }
CONTROLLER_URL=$HTTP_PROTOCOL://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT

CMD=$1; shift
case $CMD in
  test)                   _test                           $@ ;;
  analytics-agent)        _analyticsProperties_Configure  $@ ;;
  application-agent)      _applicationAgent_Configure     $@ ;;
  machine-agent)          _machineAgent_Configure         $@ ;;
  database-agent)         _databaseAgent_Configure         $@ ;;
  *)                      echo "Commands unknown: [$CMD]"
esac
