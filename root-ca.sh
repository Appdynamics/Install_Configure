#!/bin/bash
#
#
APPD_CONTROLLER_PROTOCOL="https"
APPD_CONTROLLER_HOST="TEST.saas.appdynamics.com"
APPD_CONTROLLER_PORT="443"
CERT_PEM_FILE="cert.pem"
KEYSTORE_FILE="cacerts.jks"
KEYSTORE_PASSWORD="CHANGEME"

CONTROLLER_STATUS_URL="$APPD_CONTROLLER_PROTOCOL://$APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT/controller/rest/serverstatus"
curl -v $CONTROLLER_STATUS_URL
if [ $? -ne 0 ]; then
    echo "Failed to connect to: $CONTROLLER_STATUS_URL"
    exit 0
else
    echo "Connection succeeded: $CONTROLLER_STATUS_URL"
fi


echo | \
  openssl s_client -showcerts -connect $APPD_CONTROLLER_HOST:$APPD_CONTROLLER_PORT 2>&1 | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERT_PEM_FILE

echo "Created $CERT_PEM_FILE"

keytool -import -alias rootCA -file $CERT_PEM_FILE -keystore $KEYSTORE_FILE -storepass $KEYSTORE_PASSWORD
echo "Created $KEYSTORE_FILE with password $KEYSTORE_PASSWORD"
