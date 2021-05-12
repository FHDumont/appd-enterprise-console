#!/bin/bash

source ./conf/settings.env

echo ""
echo "==> Setting envrionment"

cp ./conf/*.varfile $ARTIFACTS_FOLDER

sed -i "s|<controller-dns>|$HOST_NAME|g" $ARTIFACTS_FOLDER/ec_response.varfile
sed -i "s|<appdynamics>|$APPDYNAMICS_FOLDER|g" $ARTIFACTS_FOLDER/ec_response.varfile
sed -i "s|<primary-host>|$HOST_NAME|g" $ARTIFACTS_FOLDER/platform_response.varfile

# filecount=`cat ~/.bashrch | grep JAVA_HOME | wc -l`
# if [[ $filecount == 0  ]]
# then
#     echo 'export JAVA_HOME=/home/centos/appdynamics/platform/jre/1.8.0_282' >> ~/.bashrch
#     echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrch
# fi

sudo ./scripts/pre-req.sh

echo ""
echo "==> Downloading Platform"

cp ./scripts/getAgent.sh $ARTIFACTS_FOLDER/getAgent.sh
chmod +x $ARTIFACTS_FOLDER/getAgent.sh

RESULT_GET_AGENT=`$ARTIFACTS_FOLDER/getAgent.sh eum -listonly`
FILE_VERSION=`echo $RESULT_GET_AGENT | cut -d ':' -f3`
FILE_COUNT=`ls -1q $ARTIFACTS_FOLDER/*.* | grep -i $FILE_VERSION | wc -l`
if [[ $FILE_COUNT == 0  ]]
then
    $ARTIFACTS_FOLDER/getAgent.sh eum
else
    echo "EUM: Arquivo já existe $FILE_VERSION"
fi

RESULT_GET_AGENT=`$ARTIFACTS_FOLDER/getAgent.sh ec -listonly`
FILE_VERSION=`echo $RESULT_GET_AGENT | cut -d ':' -f3`
FILE_COUNT=`ls -1q $ARTIFACTS_FOLDER/*.* | grep -i $FILE_VERSION | wc -l`
if [[ $FILE_COUNT == 0  ]]
then
    $ARTIFACTS_FOLDER/getAgent.sh ec
else
    echo "EC:  Arquivo já existe $FILE_VERSION"
fi

echo ""
echo "==> Installing EC"
$ARTIFACTS_FOLDER/platform-setup*$FILE_VERSION.sh -q -varfile $ARTIFACTS_FOLDER/ec_response.varfile

echo ""
echo "==> Starting EC"
cd $APPDYNAMICS_FOLDER/platform/platform-admin/bin \
    && ./platform-admin.sh start-platform-admin

sed -i "s|glassfish_max_heap_size = \"1024m\"|glassfish_max_heap_size = \"4096m\"|g" $APPDYNAMICS_FOLDER/platform/platform-admin/archives/controller/2*/playbooks/controller-demo.groovy
sed -i "s|controller_data_min_disk_space_in_mb = 50|controller_data_min_disk_space_in_mb = 20|g" $APPDYNAMICS_FOLDER/platform/platform-admin/archives/controller/2*/playbooks/controller-demo.groovy

echo ""
echo "==> Logging Platform"
cd $APPDYNAMICS_FOLDER/platform/platform-admin \
    && ./bin/platform-admin.sh login --user-name admin --password appd

echo ""
echo "==> Installing Platform"
cd $APPDYNAMICS_FOLDER/platform/platform-admin \
    && ./bin/platform-admin.sh create-platform --name MyPlatform --installation-dir $APPDYNAMICS_FOLDER/platform \
    && ./bin/platform-admin.sh add-hosts --hosts $HOST_NAME \
    && ./bin/platform-admin.sh submit-job --platform-name MyPlatform --service controller --job install --arg-file $ARTIFACTS_FOLDER/platform_response.varfile

cd $APPDYNAMICS_FOLDER/platform/platform-admin \
    && ./bin/platform-admin.sh start-controller-appserver

echo ""
echo "==> Installing Event Services"
cd $APPDYNAMICS_FOLDER/platform/platform-admin \
    && ./bin/platform-admin.sh submit-job --platform-name MyPlatform --service events-service --job install --args profile=dev serviceActionHost=$HOST_NAME

cd $APPDYNAMICS_FOLDER/platform/platform-admin \
    && ./bin/platform-admin.sh restart-events-service

echo ""
echo "==> Installing Platform"
