#!/bin/bash

source ./settings.sh

INSTALL_CONTROLLER=false
INSTALL_EUM=false

for ARGUMENT in "$@"
do
    if [ "$ARGUMENT" = "controller" ]; then
      INSTALL_CONTROLLER=true
    elif [ "$ARGUMENT" = "eum" ]; then
      INSTALL_EUM=true
    elif [ "$ARGUMENT" = "all" ]; then
      INSTALL_CONTROLLER=true
      INSTALL_EUM=true
    fi
done

if [ $INSTALL_CONTROLLER == true ];
then
  echo ""
  echo "==> Installing License for Controller"

  if [[ -f "$PLATFORM_FOLDER/controller/license.lic" ]]; then
    echo "old license backuped"
    cp $PLATFORM_FOLDER/controller/license.lic $PLATFORM_FOLDER/controller/license.lic.bkp
  fi
  cp $PROJECT_FOLDER/conf/license.lic $PLATFORM_FOLDER/controller/license.lic
  touch $PLATFORM_FOLDER/controller/license.lic

  cd $PROJECT_FOLDER/scripts && ./updateAccountLicense.sh $HOST_NAME
fi

if [ $INSTALL_EUM == true ];
then
  if [[ -f "$PLATFORM_FOLDER/controller/license.lic" ]]; then
    echo ""
    echo "==> Installing License for EUM"

    cd $EUM_FOLDER/eum-processor && ./bin/provision-license $PLATFORM_FOLDER/controller/license.lic
    cd $PROJECT_FOLDER/scripts && ./stopComponent.sh eum
    cd $PROJECT_FOLDER/scripts && ./startComponent.sh eum
  fi
fi
