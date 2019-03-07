#!/bin/bash
#
# Fixes for 4.4.2


[ -z "$APPD_VERSION" ]  && { echo "APPD_VERSION parameter not set"; exit 0; }
[ -z "$APPD_RELEASE_NUMBER" ]  && { echo "APPD_RELEASE_NUMBER parameter not set"; exit 0; }

# Packages
sudo apt-get -y install libaio1 numactl net-tools tzdata chrony
#
#
# Response file
RESPONSE_FILE=`pwd`"\response-file-$APPD_VERSION-$APPD_RELEASE_NUMBER.txt"

echo "serverHostName=$APPD_CONTROLLER_HOST"                                    > $RESPONSE_FILE
echo "sys.languageId=en"                                                      >> $RESPONSE_FILE
echo "disableEULA=true"                                                       >> $RESPONSE_FILE
echo "sys.installationDir=$APPD_BASE_DIR/platform"                            >> $RESPONSE_FILE
echo "platformAdmin.dataDir=$APPD_BASE_DIR/platform/mysql/data"                >> $RESPONSE_FILE
echo "platformAdmin.port=9191"                                                >> $RESPONSE_FILE
echo "platformAdmin.databasePort=3377"                                        >> $RESPONSE_FILE
echo "platformAdmin.databasePassword=$APPD_UNIVERSAL_PWD"                     >> $RESPONSE_FILE
echo "platformAdmin.databaseRootPassword=$APPD_UNIVERSAL_PWD"                 >> $RESPONSE_FILE
echo "platformAdmin.adminPassword=$APPD_UNIVERSAL_PWD"                        >> $RESPONSE_FILE
echo 'platformAdmin.useHttps$Boolean=false'                                 >> $RESPONSE_FILE

# Install directory
mkdir -p $APPD_BASE_DIR

# Install
../platform-setup/platform-setup-x64-linux-$APPD_VERSION.$APPD_RELEASE_NUMBER.sh -q -varfile $RESPONSE_FILE
