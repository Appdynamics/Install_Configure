#!/bin/bash
#
# Environment variables for econsole-cmds.sh for installation of
# Controller and Events Service
# Ver 4.5.7.18512
#
export APPD_CONTROLLER_HOST1=controller1
export APPD_CONTROLLER_HOST2=controller2
export APPD_EVENTS_SERVICE_HOST1=events1
export APPD_EVENTS_SERVICE_HOST2=events2
export APPD_EVENTS_SERVICE_HOST3=events3
export APPD_BASE_DIR=/home/appduser/appdynamics
export APPD_VERSION=4.5.7
export APPD_RELEASE_NUMBER=18512
export APPD_CONTROLLER_NAME1=controller1
export APPD_CONTROLLER_NAME2=controller2
export APPD_PLATFORM_NAME=test1
export APPD_PLATFORM_ADMIN_CMD=$APPD_BASE_DIR/platform/platform-admin/bin/platform-admin.sh
export APPD_CONTROLLER_INSTALL_DIR=$APPD_BASE_DIR/$APPD_CONTROLLER_NAME
export APPD_CONTROLLER_PORT=8090
export APPD_SSH_PRI_KEY_FILE=~/.ssh/02052019
export APPD_SSH_CREDENTIAL_NAME=02052019
export APPD_SSH_USER_NAME=appduser
export APPD_CONTROLLER_MODE=single
export APPD_CONTROLLER_PROFILE=small
export APPD_CONTROLLER_ADMIN=admin
export APPD_UNIVERSAL_PWD=welcome1
export APPD_LICENSE_FILE=license.lic
export APPD_EVENTSSERVICE_PROFILE=prod
