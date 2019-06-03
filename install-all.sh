#!/bin/bash
#
#

./econsole-cmds.sh login

./econsole-cmds.sh createPlatform

./econsole-cmds.sh addCredentials

./econsole-cmds.sh addRemoteHost $APPD_CONTROLLER_HOST1
#./econsole-cmds.sh addRemoteHost $APPD_CONTROLLER_HOST2

./econsole-cmds.sh addRemoteHost $APPD_EVENTS_SERVICE_HOST1
#./econsole-cmds.sh addRemoteHost $APPD_EVENTS_SERVICE_HOST2
#./econsole-cmds.sh addRemoteHost $APPD_EVENTS_SERVICE_HOST3

./econsole-cmds.sh installPrimaryController

./econsole-cmds.sh installSingleEventsService
