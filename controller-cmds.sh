#!/bin/bash
#
# Maintainer: David Ryder, David.Ryder@AppDynamics.com
#
# Create an AppDynamics APM Application in the Controller
#
# Commands:
#   authenticate
#   createApp <app name> [<app description>]
#
# Requires:
#    controller-envars.sh
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
  # Authentication to Controller
  _validateEnvironmentVars "APPD_USER_NAME" "APPD_ACCOUNT" "APPD_PWD" "APPD_CONTROLLER_HOST" "APPD_CONTROLLER_PORT"

  APPD_FULL_USER=$APPD_USER_NAME@$APPD_ACCOUNT:$APPD_PWD
  B64AUTH=`echo $APPD_FULL_USER | base64`
  rm -f $CURL_SESSION_FILE
  curl $VERBOSE -s -c $CURL_SESSION_FILE \
       --user "$APPD_FULL_USER" \
       -X GET http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/auth?action=login

  # Get X-CSRF-TOKEN
  SED_TRIM_SPACES='sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//''
  XCSRFTOKEN=`grep X-CSRF-TOKEN $CURL_SESSION_FILE | sed 's/^.*X-CSRF-TOKEN\s*//' | $SED_TRIM_SPACES`
}

_http() {
  METHOD=$1
  PROTOCOL=$2
  SERVICE=$3
  POST_DATA=$4
  HTTP_RESULT=`curl $VERBOSE -s -b $CURL_SESSION_FILE \
       --header "Origin: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT" \
       --header "Accept-Encoding: text" \
       --header "Accept-Language: en-US,en;q=0.9" \
       --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
       --header "Content-Type: application/vnd.appd.cntrl+json;v=1" \
       --header "Accept: application/json, text/plain, */*" \
       --header "Referer: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/" \
       --data-binary "${POST_DATA}" \
       --header "Connection: keep-alive" \
       -X $METHOD $PROTOCOL://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT$SERVICE`
}

_http2() {
  METHOD=$1
  PROTOCOL=$2
  SERVICE=$3
  POST_DATA=$4
  HTTP_RESULT=`curl $VERBOSE -s -b $CURL_SESSION_FILE \
       --header "Origin: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT" \
       --header "Accept-Encoding: text" \
       --header "Accept-Language: en-US,en;q=0.9" \
       --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
       --header "Content-Type: application/json;charset=utf-8" \
       --header "Accept: application/json, text/plain, */*" \
       --header "Referer: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/" \
       --data-binary "${POST_DATA}" \
       --header "Connection: keep-alive" \
       --compressed \
       -X $METHOD $PROTOCOL://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT$SERVICE`
}

_getValue() { echo $1 | base64 --decode | jq -r $2; }


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
   APPDYNAMICS_CONTROLLER_HOST_NAME=$APPD_CONTROLLER_HOST
   APPDYNAMICS_CONTROLLER_PORT=$APPD_CONTROLLER_PORT
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
  #     --header "Origin: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT" \
  #     --header "Accept-Encoding: text" \
  #     --header "Accept-Language: en-US,en;q=0.9" \
  #     --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
  #     --header "Content-Type: application/json;charset=utf-8" \
  #     --header "Accept: application/json, text/plain, */*" \
  #     --header "Referer: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/" \
  #     --header "Connection: keep-alive" \
  #     --data-binary "${PARAMS}" \
  #     --compressed \
  #     -X POST http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT$SERVICE
  _http2 "POST" "http" "/controller/restui/allApplications/createApplication?applicationType=APM" "$PARAMS"



#####################################
# Create an AppDynamce APM applicaiton in the controller
#
elif [ $cmd == "gn" ]; then
  _controllerAutheticate

  SERVICE='/controller/rest/applications/1/nodes'
  curl $VERBOSE -s -b $CURL_SESSION_FILE \
       --header "Origin: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT" \
       --header "Accept-Encoding: text" \
       --header "Accept-Language: en-US,en;q=0.9" \
       --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
       --header "Content-Type: application/json;charset=utf-8" \
       --header "Accept: application/json, text/plain, */*" \
       --header "Referer: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/" \
       --header "Connection: keep-alive" \
       -X GET http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT$SERVICE


 #####################################
 # Create an AppDynamce APM applicaiton in the controller
 #
elif [ $cmd == "getApplications" ]; then
  _controllerAutheticate
  _http "GET" "http" "/controller/rest/applications?output=JSON" ""
  #echo $HTTP_RESULT | jq -r '[.[] | {name: .name, id: .id} ]'

  for row in $(echo "${HTTP_RESULT}" | jq -r '.[] | @base64'); do
     name=$(_getValue ${row} '.name')
     id=$(_getValue ${row} '.id')
     echo $name $id
  done

#####################################
# getNodes
#
elif [ $cmd == "getNodes" ]; then
  _controllerAutheticate
  _http "GET" "http" "/controller/rest/applications/7/nodes?output=JSON" ""
  echo $HTTP_RESULT | jq


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
  echo " export APPD_USER_NAME=<...>"
  echo " export APPD_ACCOUNT=<...>"
  echo " export APPD_PWD=<...>"
  echo " export APPD_CONTROLLER_HOST=<...>"
  echo " export APPD_CONTROLLER_PORT=8090"
fi

exit 0
