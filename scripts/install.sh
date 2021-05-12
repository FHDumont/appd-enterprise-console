#!/bin/bash

source ../conf/settings.env

echo ""
echo "==> Setting envrionment"

cp ../conf/*.varfile $ARTIFACTS_FOLDER

sed -i "s|<controller-dns>|$HOST_NAME|g" $ARTIFACTS_FOLDER/ec_response.varfile
sed -i "s|<appdynamics>|$APPDYNAMICS_FOLDER|g" $ARTIFACTS_FOLDER/ec_response.varfile
sed -i "s|<primary-host>|$HOST_NAME|g" $ARTIFACTS_FOLDER/platform_response.varfile

sudo ./pre-req.sh

./downloadComponent.sh all

# VERIFICANDO SE O EC JÁ ESTÁ INSTALADO
if [[ ! -f  "$APPDYNAMICS_FOLDER/platform/platform-admin/bin/platform-admin.sh" ]]; then
    echo ""
    echo "==> Installing EC"
    $ARTIFACTS_FOLDER/platform-setup*$FILE_VERSION.sh -q -varfile $ARTIFACTS_FOLDER/ec_response.varfile
fi
./startComponent.sh ec

# VERIFICANDO SE A PLATAFORMA JÁ ESTÁ INSTALADA
if [[ ! -f  "$APPDYNAMICS_FOLDER/platform/controller/bin/startController.sh" ]]; then
    # ALTERANDO VALORES PADRÕES ANTES DE CRIAR A PLATAFORMA
    sed -i "s|glassfish_max_heap_size = \"1024m\"|glassfish_max_heap_size = \"4096m\"|g" $APPDYNAMICS_FOLDER/platform/platform-admin/archives/controller/2*/playbooks/controller-demo.groovy
    sed -i "s|controller_data_min_disk_space_in_mb = 50|controller_data_min_disk_space_in_mb = 20|g" $APPDYNAMICS_FOLDER/platform/platform-admin/archives/controller/2*/playbooks/controller-demo.groovy

    echo ""
    echo "==> Installing Platform"
    cd $APPDYNAMICS_FOLDER/platform/platform-admin \
        && ./bin/platform-admin.sh create-platform --name MyPlatform --installation-dir $APPDYNAMICS_FOLDER/platform \
        && ./bin/platform-admin.sh add-hosts --hosts $HOST_NAME \
        && ./bin/platform-admin.sh submit-job --platform-name MyPlatform --service controller --job install --arg-file $ARTIFACTS_FOLDER/platform_response.varfile
fi
./startComponent.sh controller

# VERIFICANDO SE O ES JÁ ESTÁ INSTALADO
if [[ ! -f  "$APPDYNAMICS_FOLDER/platform/events-service/processor/bin/events-service.sh" ]]; then
    echo ""
    echo "==> Installing Event Services"
    cd $APPDYNAMICS_FOLDER/platform/platform-admin \
        && ./bin/platform-admin.sh submit-job --platform-name MyPlatform --service events-service --job install --args profile=dev serviceActionHost=$HOST_NAME
fi
./startComponent.sh es

echo ""
echo "==> Enterprise Console installed!"
echo ""
