#!/bin/bash
#
# Maintainer: David Ryder, David.Ryder@AppDynamics.com
#
# AppDynamics Controller Commands
#
# Commands:
#   authenticate
#   accountInfo
#   getApps
#   getAppNodes
#   appNodeMonitoring
#
# Requires:
#    jq  - https://stedolan.github.io/jq/ - sudo apt-get install jq
#
cmd=${1:-"unknown"}
APPD_APPLICATION_NAME=${2:-""}
appDescription=${3:-"Created `date +'%m%d%y-%H%M'`"}
showHelp="NO"
ERROR=0

# Temp files
CURL_SESSION_FILE=/tmp/appd-curl-session.dat

#VERBOSE="--verbose"
#VERBOSE="-v"

_validateEnvironmentVars() {
  VAR_LIST=("$@") # rebuild using all args
  #echo $VAR_LIST
  for i in "${VAR_LIST[@]}"; do
     [ -z ${!i} ] && { echo "Environment variable not set: $i"; ERROR="1"; }
  done
  [ "$ERROR" == "1" ] && { echo "Exiting"; exit 1; }
}

_controllerAutheticate() {
  # Authentication to Controller using basic authentication
  _validateEnvironmentVars "APPD_CONTROLLER_ADMIN" "APPDYNAMICS_AGENT_ACCOUNT_NAME" "APPD_UNIVERSAL_PWD" "APPDYNAMICS_CONTROLLER_HOST_NAME" "APPDYNAMICS_CONTROLLER_PORT"

  APPD_FULL_USER=$APPD_CONTROLLER_ADMIN@$APPDYNAMICS_AGENT_ACCOUNT_NAME:$APPD_UNIVERSAL_PWD
  B64AUTH=`echo $APPD_FULL_USER | base64`
  rm -f $CURL_SESSION_FILE
  curl $VERBOSE -s -c $CURL_SESSION_FILE \
       --user "$APPD_FULL_USER" \
       -X GET http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT/controller/auth?action=login

  # Get X-CSRF-TOKEN
  SED_TRIM_SPACES='sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//''
  XCSRFTOKEN=`grep X-CSRF-TOKEN $CURL_SESSION_FILE | sed 's/^.*X-CSRF-TOKEN\s*//' | $SED_TRIM_SPACES`
  #echo "XRCF [$XCSRFTOKEN]"
  if [ "$XCSRFTOKEN" == "" ]; then
    echo "Failed to authenticate to controller: $APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT"
    exit 1
  else
    echo "Authentication sucessful: $APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT"
  fi
}

_http() {
  METHOD=$1
  PROTOCOL=$2
  SERVICE=$3
  POST_DATA=$4
  HTTP_RESULT=`curl $VERBOSE -s -b $CURL_SESSION_FILE \
       --header "Origin: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT" \
       --header "Accept-Encoding: text" \
       --header "Accept-Language: en-US,en;q=0.9" \
       --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
       --header "Content-Type: application/vnd.appd.cntrl+json;v=1" \
       --header "Accept: application/json, text/plain, */*" \
       --header "Referer: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT/controller/" \
       --data-binary "${POST_DATA}" \
       --header "Connection: keep-alive" \
       -X $METHOD $PROTOCOL://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT$SERVICE`
}

_http2() {
  METHOD=$1
  PROTOCOL=$2
  SERVICE=$3
  POST_DATA=$4
  HTTP_RESULT=`curl $VERBOSE -s -b $CURL_SESSION_FILE \
       --header "Origin: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT" \
       --header "Accept-Encoding: text" \
       --header "Accept-Language: en-US,en;q=0.9" \
       --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
       --header "Content-Type: application/json;charset=utf-8" \
       --header "Accept: application/json, text/plain, */*" \
       --header "Referer: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT/controller/" \
       --data-binary "${POST_DATA}" \
       --header "Connection: keep-alive" \
       --compressed \
       -X $METHOD $PROTOCOL://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT$SERVICE`
}

_getValue() { echo $1 | base64 --decode | jq -r $2; }

_controllerGetApplicationId() {
  _APP_NAME=${1:-"UNKNOWN"}
  _http "GET" "http" "/controller/rest/applications?output=JSON" ""
  APP_ID=`echo "${HTTP_RESULT}" | jq --arg APP_NAME "$_APP_NAME" \
          -r  '.[] | select(.name == $APP_NAME) \
                | .id '`
  #echo "Found App: $APP_NAME ID: $APP_ID"
  echo $APP_ID
}

_controllerGetAppNodes() {
  APP_NAME=${1:-"Error Application Name Missing"}
  TIER_NAME=${2:-"Error Tier Name Missing"}
  NODE_NAME=${3:-"Error Node Name Missing"}
  RESULT=""
  APP_ID=$(_controllerGetApplicationId ${APP_NAME})
  if [ "$APP_ID" != "" ]; then
    _http "GET" "http" "/controller/rest/applications/$APP_ID/nodes?output=JSON" ""
    RESULT=`echo "${HTTP_RESULT}" | jq --arg NODE_NAME "$NODE_NAME" --arg TIER_NAME "$TIER_NAME"  \
            -r  '[.[] | select((.tierName | test($TIER_NAME)) and (.name | test($NODE_NAME)))]' `
  else
    echo "Error node not found: [$APP_NAME] [$TIER_NAME] [$NODE_NAME] [$APP_ID]"
    exit 1
  fi
  echo $RESULT
}

_controllerDisableNodeMonitoring() {
  _NODE_ID=${1:-"NONE_NONE"}
  _http "POST" "http" "/controller/restui/agent/setting/disableAppServerAgentForNode/$_NODE_ID?disableMonitoring=true" ""
}

_controllerEnableNodeMonitoring() {
  _NODE_ID=${1:-"NONE_NONE"}
  _http "POST" "http" "/controller/restui/agent/setting/enableAppServerAgentForNode/$_NODE_ID" ""
}

#####################################
# Test authentication to Controller
#
if [ $cmd == "authenticate" ]; then
  _controllerAutheticate
  cat $CURL_SESSION_FILE

  #####################################
  # Create an AppDynamce APM applicaiton in the controller
  #
 elif [ $cmd == "accountInfo" ]; then
   _controllerAutheticate
   _http "GET" "http" "/controller/restui/user/account" ""

   # Setup envvars
   APPDYNAMICS_CONTROLLER_HOST_NAME=$APPDYNAMICS_CONTROLLER_HOST_NAME
   APPDYNAMICS_CONTROLLER_PORT=$APPDYNAMICS_CONTROLLER_PORT
   APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY=`echo $HTTP_RESULT | jq -r .account.accessKey`
   APPDYNAMICS_AGENT_ACCOUNT_NAME=`echo $HTTP_RESULT | jq -r .account.name`
   APPDYNAMICS_GLOBAL_ACCOUNT_NAME=`echo $HTTP_RESULT | jq -r .account.globalAccountName`

   # Export envvars for agent configuration

   echo "# Agent configuration"
   echo "export APPDYNAMICS_CONTROLLER_HOST_NAME=$APPDYNAMICS_CONTROLLER_HOST_NAME"
   echo "export APPDYNAMICS_CONTROLLER_PORT=$APPDYNAMICS_CONTROLLER_PORT"
   echo "export APPDYNAMICS_CONTROLLER_SSL_ENABLED=false"
   echo "export APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY=$APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY"
   echo "export APPDYNAMICS_AGENT_ACCOUNT_NAME=$APPDYNAMICS_AGENT_ACCOUNT_NAME"
   echo "export APPDYNAMICS_GLOBAL_ACCOUNT_NAME=$APPDYNAMICS_GLOBAL_ACCOUNT_NAME"
   echo "export APPDYNAMICS_ANALYTICS_AGENT_URL=http://localhost:9090/v2/sinks/bt"
   echo "export APPDYNAMICS_EVENTS_SERVICE_ENDPOINT=http://<----URL---->:8090"
   echo "export APPDYNAMICS_SIM_ENABLED=true"

   echo "# App, Tier, Node  Names"
   echo "export APPDYNAMICS_AGENT_APPLICATION_NAME=APP_TEST_1"
   echo "export APPDYNAMICS_AGENT_TIER_NAME=APP_TIER_T1"
   echo "export APPDYNAMICS_AGENT_NODE_NAME=APP_NODE_N1"

   # $HTTP_RESULT | jq


#####################################
# Create an AppDynamce APM applicaiton in the controller
#
elif [ $cmd == "createApp" ]; then
  _controllerAutheticate

    # Parameters to post
  PARAMS="{\"name\":\"${APPD_APPLICATION_NAME}\", \
           \"description\":\"${appDescription}\"}"
  echo "Post Data: "$PARAMS

  #_http "POST" "http" "/controller/restui/allApplications/createApplication?applicationType=APM" "$PARAMS"
  # Post
  SERVICE='/controller/restui/allApplications/createApplication?applicationType=APM'
  SERVICE='/controller/restui/allApplications/createApplication?applicationType=APM'
  #curl $VERBOSE -s -b $CURL_SESSION_FILE \
  #     --header "Origin: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT" \
  #     --header "Accept-Encoding: text" \
  #     --header "Accept-Language: en-US,en;q=0.9" \
  #     --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
  #     --header "Content-Type: application/json;charset=utf-8" \
  #     --header "Accept: application/json, text/plain, */*" \
  #     --header "Referer: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT/controller/" \
  #     --header "Connection: keep-alive" \
  #     --data-binary "${PARAMS}" \
  #     --compressed \
  #     -X POST http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT$SERVICE
  _http2 "POST" "http" "/controller/restui/allApplications/createApplication?applicationType=APM" "$PARAMS"



#####################################
# Create an AppDynamce APM applicaiton in the controller
#
elif [ $cmd == "gn" ]; then
  _controllerAutheticate

  SERVICE='/controller/rest/applications/1/nodes'
  curl $VERBOSE -s -b $CURL_SESSION_FILE \
       --header "Origin: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT" \
       --header "Accept-Encoding: text" \
       --header "Accept-Language: en-US,en;q=0.9" \
       --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
       --header "Content-Type: application/json;charset=utf-8" \
       --header "Accept: application/json, text/plain, */*" \
       --header "Referer: http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT/controller/" \
       --header "Connection: keep-alive" \
       -X GET http://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT$SERVICE

#####################################
#
#
elif [ $cmd == "getApps" ]; then
  _controllerAutheticate
  _http "GET" "http" "/controller/rest/applications?output=JSON" ""

  for row in $(echo "${HTTP_RESULT}" | jq -r '.[] | @base64'); do
     name=$(_getValue ${row} '.name')
     id=$(_getValue ${row} '.id')
     echo $name $id
  done

#####################################
#
#
elif [ $cmd == "getAppId" ]; then
  APP_NAME=${2:-"Error Application Name Missing"}
  _controllerAutheticate
  APP_ID=$(_controllerGetApplicationId ${APP_NAME})

  if [ "$APP_ID" != "" ]; then
    echo "Application: $APP_NAME ID: $APP_ID"
  else
    echo "Application not found: $APP_NAME"
  fi

#####################################
# Get all nodes in an application
#
elif [ $cmd == "getAppNodes" ]; then
  APP_NAME=${2:-"Error Application Name Missing"}
  _controllerAutheticate
  HTTP_RESULT=$(_controllerGetAppNodes $APP_NAME "." ".")

  APP_ID=$(_controllerGetApplicationId ${APP_NAME})
  if [ "$APP_ID" != "" ]; then
    echo "Application: $APP_NAME ID: $APP_ID"
    #echo $HTTP_RESULT | jq
    for row in $(echo "${HTTP_RESULT}" | jq -r '.[] | @base64'); do
       name=$(_getValue ${row} '.name')
       id=$(_getValue ${row} '.id')
       agentType=$(_getValue ${row} '.agentType')
       machineAgentPresent=$(_getValue ${row} '.machineAgentPresent')
       tierName=$(_getValue ${row} '.tierName')
       echo $name $id $agentType $tierName $machineAgentPresent
    done
  else
    echo "Application not found: $APP_NAME"
  fi

#####################################
# appNodeMonitoring <APP_NAME> <NODE_NAME> ENABLE | DISABLE
# Enable disable application agents
#
elif [ $cmd == "appNodeMonitoring" ]; then
  APP_NAME=${2:-"Error Application Name Missing"}
  TIER_NAME=${3:-"Error Tier Name Missing"}
  NODE_NAME=${4:-"Error Node Name Missing"}
  MONITORING_STATE=${5:-"Error Node Monitoring State"}
  _controllerAutheticate
  HTTP_RESULT=$(_controllerGetAppNodes $APP_NAME $TIER_NAME $NODE_NAME)

  if [ "$MONITORING_STATE" == "ENABLE" ] || [ "$MONITORING_STATE" == "DISABLE" ]; then
  for row in $(echo "${HTTP_RESULT}" | jq -r '.[] | @base64'); do
     name=$(_getValue ${row} '.name')
     node_id=$(_getValue ${row} '.id')
     agentType=$(_getValue ${row} '.agentType')
     machineAgentPresent=$(_getValue ${row} '.machineAgentPresent')
     tierName=$(_getValue ${row} '.tierName')
     echo "Changing monitoring state: $MONITORING_STATE $name $node_id $agentType $tierName $machineAgentPresent"
     case "$MONITORING_STATE" in
        ENABLE)
            _controllerEnableNodeMonitoring $node_id
            ;;
        DISABLE)
            _controllerDisableNodeMonitoring $node_id
            ;;
        *)
            echo "Error: Monitoring state [$MONITORING_STATE] invalid"
            exit 1
      esac
      sleep 1
  done
else
  echo "Error: Monitoring state [$MONITORING_STATE] invalid"
fi

#####################################
# disableNode
#
elif [ $cmd == "disableNode" ]; then
  NODE_ID=${2:-"NONE_NONE"}
  _controllerAutheticate
  _controllerDisableNodeMonitoring $NODE_ID

#####################################
# enableNode
#
elif [ $cmd == "enableNode" ]; then
  NODE_ID=${2:-"NONE_NONE"}
  _controllerAutheticate
  _controllerEnableNodeMonitoring $NODE_ID


#####################################
# addUser
#
elif [ $cmd == "addUser" ]; then
  # Invalid user name and password characters: \ / " [ ] : | < > + = ; , ? * , ' tab space @
  USER_EMAIL=$2
  USER_NAME=`echo $USER_EMAIL | awk -F"@" '{print $1}'`
  USER_PWD=`openssl rand -base64 16 | tr -dc A-Z-a-z-0-9`
  echo $USER_EMAIL $USER_NAME $USER_PWD

  _controllerAutheticate

  # Parameters to post
  PARAMS="{\"name\":\"${USER_NAME}\", \
           \"security_provider_type\":\"INTERNAL\", \
           \"displayName\":\"${USER_NAME}\", \
           \"email\":\"${USER_EMAIL}\", \
           \"password\":\"${USER_PWD}\"}"
  _http "POST" "http" "/controller/api/rbac/v1/users" "$PARAMS"

  USER_ID=`echo $HTTP_RESULT | jq -r .id`
  echo "UID "$USER_ID

  declare -a APPD_ROLES=("14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25")

  for ROLE_ID in "${APPD_ROLES[@]}"; do
    echo "Adding role $ROLE_ID to user $USER_ID"
    _http "PUT" "http" "/controller/api/rbac/v1/roles/$ROLE_ID/users/$USER_ID" ""
  done


#####################################
# addUser
#
elif [ $cmd == "getUser" ]; then
  USER_NAME=$2

  _controllerAutheticate
  _http "GET" "http" "/controller/api/rbac/v1/users/name/$USER_NAME" ""
  echo $HTTP_RESULT | jq

#####################################
# Under Development
#
elif [ $cmd == "UDappserver" ]; then
  _controllerAutheticate
  _http "POST" "http" "/controller/restui/agents/list/appserver" ""
  echo $HTTP_RESULT

  #{"requestFilter":{"queryParams":{"applicationAssociationType":"ASSOCIATED_WITH_APPLICATION"},"filters":[]},"resultColumns":[],"offset":0,"limit":-1,"searchFilters":[{"columns":["HOST_NAME","NODE_NAME","COMPONENT_NAME","APPLICATION_NAME"],"query":"java_"}],"columnSorts":[{"column":"HOST_NAME","direction":"ASC"}],"timeRangeStart":1563394667785,"timeRangeEnd":1563398267785}

 # http://dryderc1-drydertest1-lbthj36l.srv.ravcloud.com:8090/controller/restui/agents/list/appserver/ids

else
  echo "Command error: "$cmd
  showHelp="YES"
fi

#####################################
# Show help
if [ $showHelp == "xYES" ]; then
  echo "Help:"
  echo
  echo "Commands:"
  echo " createApp <application name> [<application description>] - create an AppDynamics APM Application"
  echo " authenticate - test authentication against the controller"
  echo
  echo "Requries the following Environment Variables:"
  echo " export APPD_CONTROLLER_ADMIN=<...>"
  echo " export APPDYNAMICS_AGENT_ACCOUNT_NAME=<...>"
  echo " export APPD_UNIVERSAL_PWD=<...>"
  echo " export APPDYNAMICS_CONTROLLER_HOST_NAME=<...>"
  echo " export APPDYNAMICS_CONTROLLER_PORT=8090"
fi

exit 0
