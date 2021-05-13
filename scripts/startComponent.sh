#!/bin/bash

source ./settings.sh

START_EC=false
START_CONTROLLER=false
START_ES=false
START_EUM=false

EC_RUNNING=false
FORCE_LOGIN=false

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
    START_EC=true
  elif [[ "$PARAM" == "controller" ]]; then
    START_CONTROLLER=true
  elif [[ "$PARAM" == "es" ]]; then
    START_ES=true
  elif [[ "$PARAM" == "eum" ]]; then
    START_EUM=true
  elif [[ "$PARAM" == "all" ]]; then
    START_EC=true
    START_CONTROLLER=true
    START_ES=true
    START_EUM=true
  elif [ "$PARAM" = "--login" ]; then
    FORCE_LOGIN=true
  fi
  shift
done

if [[ $START_EC = false && $START_CONTROLLER = false && $START_ES = false && $START_EUM = false ]]; then
  echo
  echo "Valid Components names:"
  echo "          ec"
  echo "          controller"
  echo "          es"
  echo "          eum"
  echo "          all"
  echo
  echo "Example: ./startComponent.sh ec controller"
  echo
  exit 1
fi

if [[ ! -f  "$EC_FOLDER/platform-admin/bin/platform-admin.sh" ]]; then
  error "EC doesn't installed"
fi

if [ `ps aux | grep -v grep | grep -i platformadminApplication.yml | wc -l` -ne 0 ]; then
  EC_RUNNING=true
fi

if [[ $EC_RUNNING == false && $START_EC == true ]]; then
  echo ""
  echo "Starting EC"
  cd $EC_FOLDER/platform-admin/bin \
      && ./platform-admin.sh start-platform-admin

  if [ `ps aux | grep -v grep | grep -i platformadminApplication.yml | wc -l` -ne 0 ]; then
    EC_RUNNING=true
  fi
fi

if [ $EC_RUNNING == false ]; then
  error "Couldn't start EC, it's required!"
fi

# NECESSÁRIO PARA OS PRÓXIMOS COMANDOS, TAMBÉM VALIDA QUE A EC ESTÁ OK
if [[ ! -f  "$EC_FOLDER/platform-admin/.appd.rc" || $FORCE_LOGIN == true ]]; then
  echo ""
  echo "Logging Platform"
  cd $EC_FOLDER/platform-admin \
      && ./bin/platform-admin.sh login --user-name admin --password appd
fi

if [ $START_CONTROLLER == true ]; then
  if [[ ! -f  "$PLATFORM_FOLDER/controller/bin/startController.sh" ]]; then
    error "Controller doesn't installed"
  fi

  if [ `ps aux | grep -v grep | grep -i glassfish | wc -l` -eq 0 ]; then
    echo ""
    echo "Starting Controller"
    cd $EC_FOLDER/platform-admin \
        && ./bin/platform-admin.sh start-controller-appserver
  fi
fi

if [ $START_ES == true ]; then
  if [[ ! -f  "$PLATFORM_FOLDER/events-service/processor/bin/events-service.sh" ]]; then
    error "Event Services doesn't installed"
  fi

  if [ `ps aux | grep -v grep | grep -i events-service | wc -l` -eq 0 ]; then
    echo ""
    echo "Starting Event Services"
    cd $EC_FOLDER/platform-admin \
        && ./bin/platform-admin.sh restart-events-service
  fi
fi

if [ $START_EUM == true ]; then
  if [[ ! -f  "$EUM_FOLDER/eum-processor/bin/eum.sh" ]]; then
    error "EUM doesn't installed"
  fi

  echo "Starting EUM"
  cd $EUM_FOLDER/eum-processor \
      && ./bin/eum.sh start
fi