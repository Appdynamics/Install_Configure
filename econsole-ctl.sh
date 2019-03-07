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
APPD_VERSION=${2:-"4.5.2"} # 4.4.2 | 4.5.0

# Vars
BASE_DIR=$APPD_BASE_DIR/$APPD_VERSION
APPD_PLATFORM_ADMIN_CMD=$BASE_DIR/platform/platform-admin/bin/platform-admin.sh

[ ! -e "$BASE_DIR" ] && { echo "Incorrect Version "$APPD_VERSION; exit 0; }

if [ $COMMAND == "start" ]; then
    $APPD_PLATFORM_ADMIN_CMD start-platform-admin

elif [ $COMMAND == "log" ]; then
    tail -f $BASE_DIR/platform/platform-admin/logs/platform-admin-server.log

elif [ $COMMAND == "stop" ]; then
    $APPD_PLATFORM_ADMIN_CMD stop-platform-admin

elif [ $COMMAND == "status" ]; then
  curl $APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/rest/serverstatus

elif [ $COMMAND == "showParams" ]; then
  $APPD_PLATFORM_ADMIN_CMD list-job-parameters --job install --service controller
  $APPD_PLATFORM_ADMIN_CMD list-job-parameters --job install --service events-service

elif [ $COMMAND == "firewall" ]; then
  # Econsole
  sudo firewall-cmd --zone=public --add-port=9191/tcp --permanent

  # Controller
  sudo firewall-cmd --zone=public --add-port=8090/tcp --permanent

  # Events Service
  sudo firewall-cmd --zone=public --add-port=9080/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=9081/tcp --permanent

  sudo firewall-cmd --reload
  sudo firewall-cmd --list-all

else
  echo "Command unknown: "$COMMAND
fi
