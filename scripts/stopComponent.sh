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
  echo "          eum"
  echo
  echo "Example: ./startComponent.sh ec controller"
  echo
  exit 1
fi

if [ $STOP_EUM == true ]; then
  if [[ ! -f  "$EUM_FOLDER/eum-processor/bin/eum.sh" ]]; then
    error "EUM doesn't installed"
  fi
  echo "Stopping EUM"
  cd $EUM_FOLDER/eum-processor \
      && ./bin/eum.sh stop
fi