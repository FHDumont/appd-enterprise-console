#!/bin/bash

CURRENT_FOLDER=`realpath ./`
CONF_FOLDER="../conf"
IS_BOOT=

for ARGUMENT in "$@"
do
    if [ "$ARGUMENT" = "--boot" ]; then
      IS_BOOT=--boot
    fi
done

if [[ $IS_BOOT = "--boot" ]]; then
  CONF_FOLDER=$CURRENT_FOLDER/appd-enterprise-console/conf
  CURRENT_FOLDER=$CURRENT_FOLDER/appd-enterprise-console/scripts
fi

source "$CONF_FOLDER/settings.env"

mkdir -p $ARTIFACTS_FOLDER
sudo mkdir -p $APPDYNAMICS_FOLDER
sudo chown $USER_NAME: $APPDYNAMICS_FOLDER

cp $PROJECT_FOLDER/conf/*.varfile $ARTIFACTS_FOLDER
cp $PROJECT_FOLDER/conf/settings.env $ARTIFACTS_FOLDER

cp $CURRENT_FOLDER/getAgent.sh $ARTIFACTS_FOLDER/getAgent.sh
chmod +x $ARTIFACTS_FOLDER/getAgent.sh

echo "" >> $ARTIFACTS_FOLDER/settings.env

sed -i "s|<controller-dns>|$HOST_NAME|g" $ARTIFACTS_FOLDER/ec_response.varfile
sed -i "s|<appdynamics>|$APPDYNAMICS_FOLDER|g" $ARTIFACTS_FOLDER/ec_response.varfile
EC_FOLDER=`cat $ARTIFACTS_FOLDER/ec_response.varfile | grep -i sys.installationDir | cut -d '=' -f2`
echo EC_FOLDER=$EC_FOLDER >> $ARTIFACTS_FOLDER/settings.env

sed -i "s|<primary-host>|$HOST_NAME|g" $ARTIFACTS_FOLDER/platform_response.varfile
sed -i "s|<appdynamics>|$APPDYNAMICS_FOLDER|g" $ARTIFACTS_FOLDER/platform_response.varfile
PLATFORM_FOLDER=$APPDYNAMICS_FOLDER/platform
echo PLATFORM_FOLDER=$PLATFORM_FOLDER >> $ARTIFACTS_FOLDER/settings.env

sed -i "s|<appdynamics>|$APPDYNAMICS_FOLDER|g" $ARTIFACTS_FOLDER/eum_response.varfile
sed -i "s|<appdynamics-controller>|$PLATFORM_FOLDER|g" $ARTIFACTS_FOLDER/eum_response.varfile
EUM_FOLDER=`cat $ARTIFACTS_FOLDER/eum_response.varfile | grep -i sys.installationDir | cut -d '=' -f2`
echo EUM_FOLDER=$EUM_FOLDER >> $ARTIFACTS_FOLDER/settings.env

if [[ -f "$PLATFORM_FOLDER/events-service/processor/conf/events-service-api-store.properties" ]]; then
    sed -i "s|<appdynamics.es.eum.key>|`cat $PLATFORM_FOLDER/events-service/processor/conf/events-service-api-store.properties | grep -i ad.accountmanager.key.eum | cut -d '=' -f2`|g" $ARTIFACTS_FOLDER/eum_response.varfile
fi
