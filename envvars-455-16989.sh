#!/bin/bash
#
# Environment vars for Platform Admin and Controller
#
export APPD_CONTROLLER_HOST=sys4
export APPD_BASE_DIR=/home/ddr/appdynamics
export APPD_CONTROLLER_NAME=controller2
export APPD_PLATFORM_ADMIN_CMD=$APPD_BASE_DIR/platform/platform-admin/bin/platform-admin.sh
export APPD_CONTROLLER_INSTALL_DIR=$APPD_BASE_DIR/$APPD_CONTROLLER_NAME
export APPD_VERSION=4.5.5
export APPD_RELEASE_NUMBER=16989
export APPD_CONTROLLER_PORT=8090
export APPD_SSH_PRI_KEY_FILE=ddr-04012018
export APPD_SSH_CREDENTIAL_NAME=ddr-04012018
export APPD_SSH_USER_NAME=ddr
export APPD_CONTROLLER_MODE=single
export APPD_CONTROLLER_PROFILE=demo
export APPD_CONTROLLER_ADMIN=admin
export APPD_UNIVERSAL_PWD=welcome1
export APPD_LICENSE_FILE=license.lic
export APPD_EVENTSSERVICE_PROFILE=dev
