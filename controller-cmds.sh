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
applicationName=${2:-""}
appDescription=${3:-"Created `date +'%m%d%y-%H%M'`"}
showHelp="NO"
ERROR=0

# Parameters
[ -z "$applicationName" ]  && { echo "<applicationName> parameter not set"; ERROR=1; }
[ "$ERROR" == 0 ] && { showHelp="YES";  }

# Required environment variables. Authentication and Access
declare -a envVarList=("APPD_USER_NAME" "APPD_ACCOUNT" "APPD_PWD" "APPD_CONTROLLER_HOST" "APPD_CONTROLLER_PORT")
for i in "${envVarList[@]}"; do
   [ -z ${!i} ] && { echo "Environment variable not set: $i"; ERROR=1; }
done
[ $ERROR = 1 ] && { showHelp="YES"; }

APPD_FULL_USER=$APPD_USER_NAME@$APPD_ACCOUNT:$APPD_PWD
B64AUTH=`echo $APPD_FULL_USER | base64`

# Temp files
CURL_SESSION_FILE=/tmp/curl-session.dat

#VERBOSE="--verbose"
VERBOSE=""

#####################################
# Test authentication to Controller
#
if [ $cmd == "authenticate" ]; then
  # Authentication to Controller
  VERBOSE="--verbose"
  rm -f $CURL_SESSION_FILE
  curl $VERBOSE -s -c $CURL_SESSION_FILE \
       --user "$APPD_FULL_USER" \
       -X GET http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/auth?action=login
  cat $CURL_SESSION_FILE
  rm -f $CURL_SESSION_FILE

#####################################
# Create an AppDynamce APM applicaiton in the controller
#
elif [ $cmd == "createApp" ]; then
  # Authentication to Controller
  rm -f $CURL_SESSION_FILE
  curl $VERBOSE -s -c $CURL_SESSION_FILE \
       --user "$APPD_FULL_USER" \
       -X GET http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/auth?action=login

  # Get X-CSRF-TOKEN
  SED_TRIM_SPACES='sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//''
  XCSRFTOKEN=`grep X-CSRF-TOKEN $CURL_SESSION_FILE | sed 's/^.*X-CSRF-TOKEN\s*//' | $SED_TRIM_SPACES`

  # Parameters to post
  PARAMS="{\"name\":\"${applicationName}\", \
           \"description\":\"${appDescription}\"}"
  #echo "Post Data: "$PARAMS

  # Post
  SERVICE='/controller/restui/allApplications/createApplication?applicationType=APM'
  curl $VERBOSE -s -b $CURL_SESSION_FILE \
       --header "Origin: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT" \
       --header "Accept-Encoding: text" \
       --header "Accept-Language: en-US,en;q=0.9" \
       --header "X-CSRF-TOKEN: ${XCSRFTOKEN}" \
       --header "Content-Type: application/json;charset=utf-8" \
       --header "Accept: application/json, text/plain, */*" \
       --header "Referer: http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/" \
       --header "Connection: keep-alive" \
       --data-binary "${PARAMS}" \
       --compressed \
       -X POST http://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT$SERVICE
    rm -f $CURL_SESSION_FILE

else
  echo "Command error: "$cmd
  showHelp="YES"

#####################################
# Show help
if [ $showHelp == "YES" ]; then
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
