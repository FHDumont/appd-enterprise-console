#!/bin/bash

source ./settings.sh

echo ""
echo "==> Setting envrionment"

SKIP_UPDATE=true
SKIP_DOWNLOAD=true
INSTALL_LICENSE=false

INSTALL_EC=false
INSTALL_CONTROLLER=false
INSTALL_ES=false
INSTALL_EUM=false

while [ $# -gt 0 ]; do
  PARAM="${1,,}"
  if [ "$PARAM" = "--update" ]; then
    SKIP_UPDATE=false
  elif [ "$PARAM" = "--download" ]; then
    SKIP_DOWNLOAD=false
  elif [ "$PARAM" = "--license" ]; then
    INSTALL_LICENSE=true
  elif [ "$PARAM" = "ec" ]; then
    INSTALL_EC=true
  elif [ "$PARAM" = "controller" ]; then
    INSTALL_CONTROLLER=true
  elif [ "$PARAM" = "es" ]; then
    INSTALL_ES=true
  elif [ "$PARAM" = "eum" ]; then
    INSTALL_EUM=true
  elif [ "$PARAM" = "all" ]; then
    INSTALL_EC=true
    INSTALL_CONTROLLER=true
    INSTALL_ES=true
    INSTALL_EUM=true
  fi
  shift
done

sudo ./pre-req.sh $SKIP_UPDATE

# VERIFICANDO SE OS LIMITES ESTÃO OK
if [ `ulimit -n -H` != 96000 ];then
    echo 
    echo 
    echo "==> It's necessary to reboot the machine or logout/login for new limits values"
    echo 
    exit 1
fi

if [ $SKIP_DOWNLOAD == false ];then
    ./downloadComponent.sh all
fi

if [ $INSTALL_EC == true ];then
    if [[ ! -f  "$EC_FOLDER/platform-admin/bin/platform-admin.sh" ]]; then
        echo ""
        echo "==> Installing EC"
        FILE_VERSION=`$ARTIFACTS_FOLDER/getAgent.sh ec -listonly | cut -d ':' -f3`
        $ARTIFACTS_FOLDER/platform-setup*$FILE_VERSION.sh -q -varfile $ARTIFACTS_FOLDER/ec_response.varfile
    fi
    cd $PROJECT_FOLDER/scripts && ./startComponent.sh ec --login
fi

if [ $INSTALL_CONTROLLER == true ];then
    if [[ ! -f  "$PLATFORM_FOLDER/controller/bin/startController.sh" ]]; then
        sed -i "s|glassfish_max_heap_size = \"1024m\"|glassfish_max_heap_size = \"4096m\"|g" $EC_FOLDER/platform-admin/archives/controller/2*/playbooks/controller-demo.groovy
        sed -i "s|controller_data_min_disk_space_in_mb = 50|controller_data_min_disk_space_in_mb = 20|g" $EC_FOLDER/platform-admin/archives/controller/2*/playbooks/controller-demo.groovy

        echo ""
        echo "==> Creating platform"
        cd $EC_FOLDER/platform-admin && ./bin/platform-admin.sh create-platform --name MyPlatform --installation-dir $PLATFORM_FOLDER

        echo ""
        echo "==> Adding host"
        cd $EC_FOLDER/platform-admin && ./bin/platform-admin.sh add-hosts --platform-name MyPlatform --hosts $HOST_NAME

        echo ""
        echo "==> Installing Controller"
        cd $EC_FOLDER/platform-admin && ./bin/platform-admin.sh submit-job --platform-name MyPlatform --service controller --job install --arg-file $ARTIFACTS_FOLDER/platform_response.varfile

    fi
    cd $PROJECT_FOLDER/scripts && ./startComponent.sh controller
    cd $PROJECT_FOLDER/scripts && ./posInstallController.sh $HOST_NAME

    if [ $INSTALL_LICENSE == true ]; then
        cd $PROJECT_FOLDER/scripts && ./installLicense.sh controller
    fi
fi

# VERIFICANDO SE O ES JÁ ESTÁ INSTALADO
if [ $INSTALL_ES == true ];then
  if [[ ! -f  "$PLATFORM_FOLDER/events-service/processor/bin/events-service.sh" ]]; then
      echo ""
      echo "==> Installing Event Services"
      cd $EC_FOLDER/platform-admin \
          && ./bin/platform-admin.sh submit-job --platform-name MyPlatform --service events-service --job install --args profile=dev serviceActionHost=$HOST_NAME

      echo ""
      echo "==> Tunning System"
      cd $PLATFORM_FOLDER/events-service/processor/bin/tool \
          && chmod +x ./tune-system.sh \
          && sudo ./tune-system.sh
  fi
  cd $PROJECT_FOLDER/scripts && ./startComponent.sh es
fi

# VERIFICANDO SE O EUM JÁ ESTÁ INSTALADO
if [ $INSTALL_EUM == true ];then
  if [[ ! -f  "$EUM_FOLDER/eum-processor/bin/eum.sh" ]]; then
    if [[ ! -f  "$PLATFORM_FOLDER/events-service/processor/bin/events-service.sh" ]]; then
      echo ""
      echo "==> ES is required"
    else
      echo ""
      echo "==> Installing EUM"

      FILE_VERSION=`$ARTIFACTS_FOLDER/getAgent.sh eum -listonly | cut -d ':' -f3`
      $ARTIFACTS_FOLDER/euem-64bit-linux*$FILE_VERSION.sh -q -varfile $ARTIFACTS_FOLDER/eum_response.varfile
      
      if [ $INSTALL_LICENSE == true ]; then
          cd $PROJECT_FOLDER/scripts && ./installLicense.sh eum
      fi
    fi
  fi
fi

echo ""
echo "==> Enterprise Console installed!"
echo ""
