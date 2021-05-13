#!/bin/bash

source ./settings.sh

HOST_NAME_PARAM=$1

if [ x${HOST_NAME_PARAM} == "x" ];
then
    HOST_NAME_PARAM=localhost
fi

./updateAdminSetting.sh $HOST_NAME_PARAM "appdynamics.on.premise.event.service.url" "http://localhost:9080"
./updateAdminSetting.sh $HOST_NAME_PARAM "eum.es.host" "http://localhost:9080"
./updateAdminSetting.sh $HOST_NAME_PARAM "eum.cloud.host" "http://localhost:7001"
./updateAdminSetting.sh $HOST_NAME_PARAM "eum.beacon.host" "$STATIC_DNS:7001"
./updateAdminSetting.sh $HOST_NAME_PARAM "eum.beacon.https.host" "$STATIC_DNS:7002"
./updateAdminSetting.sh $HOST_NAME_PARAM "eum.mobile.screenshot.host" "$STATIC_DNS:7001"

# ./updateAdminSetting.sh $HOST_NAME_PARAM "analytics.agentless.event.service.url" "http://localhost:9080"


