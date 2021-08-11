#!/bin/bash

source ./settings.sh

STOP_EC=false
STOP_CONTROLLER=false
STOP_ES=false
STOP_EUM=false

EC_RUNNING=false

function error() {
  echo
  echo "==> ERROR <=="
  echo $1
  echo
  exit 1
}

while [ $# -gt 0 ]; do
  PARAM="${1,,}"
  if [ "$PARAM" == "ec" ]; then
    STOP_EC=true
  elif [[ "$PARAM" == "controller" ]]; then
    STOP_CONTROLLER=true
  elif [[ "$PARAM" == "es" ]]; then
    STOP_ES=true
  elif [[ "$PARAM" == "eum" ]]; then
    STOP_EUM=true
  elif [[ "$PARAM" == "all" ]]; then
    STOP_EC=true
    STOP_CONTROLLER=true
    STOP_ES=true
    STOP_EUM=true
  fi
  shift
done

if [[ $STOP_EC = false && $STOP_CONTROLLER = false && $STOP_ES = false && $STOP_EUM = false ]]; then
  echo
  echo "Valid Components names:"
  echo "          ec"
  echo "          controller"
  echo "          es"
  echo "          eum"
  echo "          all"
  echo
  echo "Example: ./stopComponent.sh ec controller"
  echo
  exit 1
fi

if [[ ! -f  "$EC_FOLDER/platform-admin/bin/platform-admin.sh" ]]; then
  error "EC doesn't installed"
fi

if [ $STOP_CONTROLLER == true ]; then
  echo ""
  echo "Stopping Controller"
  cd $EC_FOLDER/platform-admin \
      && ./bin/platform-admin.sh stop-controller-appserver
  echo ""
  echo "Stopping Controller Database"
  cd $EC_FOLDER/platform-admin \
      && ./bin/platform-admin.sh stop-controller-db
fi

if [ $STOP_ES == true ]; then
  echo ""
  echo "==> Stopping Event Services"
  cd $EC_FOLDER/platform-admin \
      && ./bin/platform-admin.sh submit-job --platform-name MyPlatform --service events-service --job stop
fi

if [ $STOP_EUM == true ]; then
  if [[ ! -f  "$EUM_FOLDER/eum-processor/bin/eum.sh" ]]; then
    error "EUM doesn't installed"
  fi
  echo "Stopping EUM"
  cd $EUM_FOLDER/eum-processor \
      && ./bin/eum.sh stop
fi

if [[ $STOP_EC == true ]]; then
  echo ""
  echo "Stopping EC"
  cd $EC_FOLDER/platform-admin/bin \
      && ./platform-admin.sh stop-platform-admin
fi
