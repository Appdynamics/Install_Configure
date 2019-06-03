#!/bin/bash
#
#

$APPD_PLATFORM_ADMIN_CMD login --user-name  $APPD_CONTROLLER_ADMIN --password $APPD_UNIVERSAL_PWD
$APPD_PLATFORM_ADMIN_CMD list-platforms

# List Jobs available
$APPD_PLATFORM_ADMIN_CMD list-jobs --platform-name $APPD_PLATFORM_NAME --service events-service
$APPD_PLATFORM_ADMIN_CMD list-jobs --platform-name $APPD_PLATFORM_NAME --service controller

# Stop
$APPD_PLATFORM_ADMIN_CMD submit-job --service events-service --job stop --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD submit-job --service controller --job stop --platform-name $APPD_PLATFORM_NAME

# Uninstall
$APPD_PLATFORM_ADMIN_CMD submit-job --service events-service --job uninstall --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD submit-job --service controller --job remove --platform-name $APPD_PLATFORM_NAME

# Remove hosts
$APPD_PLATFORM_ADMIN_CMD remove-hosts --hosts $APPD_CONTROLLER_HOST1 --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD remove-hosts --hosts $APPD_CONTROLLER_HOST2 --platform-name $APPD_PLATFORM_NAME

$APPD_PLATFORM_ADMIN_CMD remove-hosts --hosts $APPD_EVENTS_SERVICE_HOST1 --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD remove-hosts --hosts $APPD_EVENTS_SERVICE_HOST2 --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD remove-hosts --hosts $APPD_EVENTS_SERVICE_HOST3 --platform-name $APPD_PLATFORM_NAME

$APPD_PLATFORM_ADMIN_CMD remove-dead-hosts --hosts $APPD_CONTROLLER_HOST1 --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD remove-dead-hosts --hosts $APPD_CONTROLLER_HOST2 --platform-name $APPD_PLATFORM_NAME

$APPD_PLATFORM_ADMIN_CMD remove-dead-hosts --hosts $APPD_EVENTS_SERVICE_HOST1 --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD remove-dead-hosts --hosts $APPD_EVENTS_SERVICE_HOST2 --platform-name $APPD_PLATFORM_NAME
$APPD_PLATFORM_ADMIN_CMD remove-dead-hosts --hosts $APPD_EVENTS_SERVICE_HOST3 --platform-name $APPD_PLATFORM_NAME

$APPD_PLATFORM_ADMIN_CMD list-credentials --platform-name $APPD_PLATFORM_NAME

$APPD_PLATFORM_ADMIN_CMD remove-credential --credential-name $APPD_SSH_CREDENTIAL_NAME --platform-name $APPD_PLATFORM_NAME

$APPD_PLATFORM_ADMIN_CMD delete-platform --name $APPD_PLATFORM_NAME
