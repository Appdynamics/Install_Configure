#!/bin/bash
#
# Maintainer: David Ryder, David.Ryder@AppDynamics.com
#
# AppDynamics EConsole commands
#
# Commands:
#   start | stop <version> -  start or stop the econsole
#

# Required arguments
COMMAND=${1:-"unknown"} # start | stop
APPD_VERSION=${2:-"unknown"} # 4.4.2 | 4.5.0

# Vars
BASE_DIR=/vol1/appdynamics/$APPD_VERSION
APPD_PLATFORM_ADMIN_CMD=$BASE_DIR/platform/platform-admin/bin/platform-admin.sh

[ ! -e "$BASE_DIR" ] && { echo "Incorrect Version "$APPD_VERSION; exit 0; }

if [ $COMMAND == "start" ]; then
    $APPD_PLATFORM_ADMIN_CMD start-platform-admin
    tail -f $BASE_DIR/platform/platform-admin/logs/platform-admin-server.log

elif [ $COMMAND == "stop" ]; then
    $APPD_PLATFORM_ADMIN_CMD stop-platform-admin

elif [ $COMMAND == "status" ]; then
  curl $APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/rest/serverstatus

elif [ $COMMAND == "showParams" ]; then
  $APPD_PLATFORM_ADMIN_CMD list-job-parameters --job install --service controller
  $APPD_PLATFORM_ADMIN_CMD list-job-parameters --job install --service events-service

else
  echo "Command unknown: "$COMMAND
fi
