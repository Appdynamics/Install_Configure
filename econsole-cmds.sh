#!/bin/bash
#
# Maintainer: David Ryder, David.Ryder@AppDynamics.com
#
# Install pltform, controller, events service
#
# Commands:
#   installPlatform
#   installController
#   installEventsService
#   showParams
#
# Requires:
#    econsole-envvars.sh
#

# Required environment variables
declare -a \
envVarList=("APPD_CONTROLLER_HOST" "APPD_PLATFORM_ADMIN_CMD" "APPD_CONTROLLER_PORT" \
            "APPD_CONTROLLER_INSTALL_DIR" "APPD_SSH_PRI_KEY_FILE" \
            "APPD_SSH_CREDENTIAL_NAME" "APPD_SSH_USER_NAME" "APPD_CONTROLLER_NAME" \
            "APPD_CONTROLLER_MODE" "APPD_CONTROLLER_PROFILE" "APPD_CONTROLLER_ADMIN" \
            "APPD_UNIVERSAL_PWD" "APPD_LICENSE_FILE" "APPD_EVENTSSERVICE_PROFILE")
ERROR=0
for evar in "${envVarList[@]}"; do
   [ -z ${!evar} ] && { echo "Environment variable not set: $evar"; ERROR=1; }
done
[ $ERROR = 1 ] && { echo "Exiting"; exit 0; }

cmd=${1:-"unknown"}

#
# APPD_CURRENT_PLATFORM = APPD_CONTROLLER_NAME
#

#####################################
# Create a Platform
#
if [ $cmd == "installPlatform" ]; then
   $APPD_PLATFORM_ADMIN_CMD login --user-name  $APPD_CONTROLLER_ADMIN --password $APPD_UNIVERSAL_PWD

    # Create Platform
    $APPD_PLATFORM_ADMIN_CMD create-platform --name $APPD_CONTROLLER_NAME --installation-dir $APPD_CONTROLLER_INSTALL_DIR

    # Add credentials
    $APPD_PLATFORM_ADMIN_CMD add-credential \
      --credential-name $APPD_SSH_CREDENTIAL_NAME \
      --user-name $APPD_SSH_USER_NAME \
      --ssh-key-file $APPD_SSH_PRI_KEY_FILE \
      --platform-name $APPD_CONTROLLER_NAME

    # Add a host
    $APPD_PLATFORM_ADMIN_CMD add-hosts --hosts $APPD_CONTROLLER_HOST \
      --credential $APPD_SSH_CREDENTIAL_NAME \
      --platform-name $APPD_CONTROLLER_NAME

#####################################
# Install a Controller
#
elif [ $cmd == "installController" ]; then
    $APPD_PLATFORM_ADMIN_CMD login --user-name  $APPD_CONTROLLER_ADMIN --password $APPD_UNIVERSAL_PWD

    # Install controller
    $APPD_PLATFORM_ADMIN_CMD submit-job --service controller --job install --platform-name $APPD_CONTROLLER_NAME --args \
      controllerProfile=$APPD_CONTROLLER_PROFILE \
      controllerTenancyMode=$APPD_CONTROLLER_MODE \
      controllerPrimaryHost=$APPD_CONTROLLER_HOST \
      controllerAdminUsername=$APPD_CONTROLLER_ADMIN \
      controllerAdminPassword=$APPD_UNIVERSAL_PWD \
      controllerRootUserPassword=$APPD_UNIVERSAL_PWD \
      mysqlRootPassword=$APPD_UNIVERSAL_PWD

    # License
    #scp -i $APPD_SSH_PRI_KEY_FILE $APPD_LICENSE_FILE $APPD_SSH_USER_NAME@$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_INSTALL_DIR/controller/.

#####################################
# Install the Events Service
#
elif [ $cmd == "installEventsService" ]; then
  # Install Events Service
  $APPD_PLATFORM_ADMIN_CMD install-events-service \
    --profile $APPD_EVENTSSERVICE_PROFILE \
    --hosts $APPD_CONTROLLER_HOST \
    --data-dir $APPD_CONTROLLER_INSTALL_DIR \
    --platform-name $APPD_CONTROLLER_NAME

    #####################################
    # Install a Controller
    #
  elif [ $cmd == "deletePlatform" ]; then
        # Install controller
        $APPD_PLATFORM_ADMIN_CMD login --user-name  $APPD_CONTROLLER_ADMIN --password $APPD_UNIVERSAL_PWD
        $APPD_PLATFORM_ADMIN_CMD list-platforms
        $APPD_PLATFORM_ADMIN_CMD remove-hosts --hosts $APPD_CONTROLLER_HOST --platform-name $APPD_CONTROLLER_NAME
        $APPD_PLATFORM_ADMIN_CMD remove-dead-hosts --hosts $APPD_CONTROLLER_HOST --platform-name $APPD_CONTROLLER_NAME
        $APPD_PLATFORM_ADMIN_CMD list-credentials --platform-name $APPD_CONTROLLER_NAME
        $APPD_PLATFORM_ADMIN_CMD remove-credential --credential-name $APPD_SSH_CREDENTIAL_NAME --platform-name $APPD_CONTROLLER_NAME
        $APPD_PLATFORM_ADMIN_CMD delete-platform --name $APPD_CONTROLLER_NAME

#####################################
# Get the controller status
#
elif [ $cmd == "controllerStatus" ]; then
    # Controller status
    curl $APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/rest/serverstatus

elif [ $cmd == "showParams" ]; then
  $APPD_PLATFORM_ADMIN_CMD list-job-parameters --job install --service controller
  $APPD_PLATFORM_ADMIN_CMD list-job-parameters --job install --service events-service

else
  echo "Command unknown: "$cmd
fi

# Complete
# $APPD_PLATFORM_ADMIN_CMD delete-platform --name c2
