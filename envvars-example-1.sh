#!/bin/bash
#
# Environment vars for Platform Admin, Controller and Event Service Install
#
# Version 4.5.7.18512 of software to install
export APPD_VERSION=4.5.7
export APPD_RELEASE_NUMBER=18512

# Platform Name for deployment of this controller and events service
export APPD_PLATFORM_NAME=TEST1

# Base directory for install, consistent across econsole, controller and events service
export APPD_BASE_DIR=/home/appduser/appdynamics
export APPD_CONTROLLER_INSTALL_DIR=$APPD_BASE_DIR/$APPD_PLATFORM_NAME
export APPD_PLATFORM_ADMIN_CMD=$APPD_BASE_DIR/platform/platform-admin/bin/platform-admin.sh


# Econsole Host Name
APPD_ECONSOLE_HOST=econsole.test1.com

# Hostname of controller for authentication (same host as APPD_CONTROLLER_HOST1)
export APPD_CONTROLLER_HOST=controller1.test1.com

# Hostnames resolvable from econsole
export APPD_CONTROLLER_HOST1=controller1
export APPD_CONTROLLER_HOST2=controller2
export APPD_EVENTS_SERVICE_HOST1=events1
export APPD_EVENTS_SERVICE_HOST2=events2
export APPD_EVENTS_SERVICE_HOST3=events3

# Naming of controllers within econsole
export APPD_CONTROLLER_NAME1=controllerA
export APPD_CONTROLLER_NAME2=controllerB

export APPD_CONTROLLER_PORT=8090

# SSH passwordless access across nodes: RSA
export APPD_SSH_PRI_KEY_FILE=~/.ssh/appduser-02052019
export APPD_SSH_CREDENTIAL_NAME=appduser-02052019
export APPD_SSH_USER_NAME=appduser

# Controller authentication
export APPD_CONTROLLER_ADMIN=admin
export APPD_UNIVERSAL_PWD=changepwd1

# Deployment sizing
export APPD_CONTROLLER_MODE=single
export APPD_CONTROLLER_PROFILE=small
export APPD_EVENTSSERVICE_PROFILE=dev

# License file
export APPD_LICENSE_FILE=license.lic
