#!/bin/bash

source ./settings.sh

EC_DOWNLOAD=false
EUM_DOWNLOAD=false

for ARGUMENT in "$@"
do
    if [ "$ARGUMENT" = "ec" ]; then
      EC_DOWNLOAD=true
    elif [ "$ARGUMENT" = "eum" ]; then
      EUM_DOWNLOAD=true
    elif [ "$ARGUMENT" = "all" ]; then
      EC_DOWNLOAD=true
      EUM_DOWNLOAD=true
    fi
done

echo ""
echo "==> Downloading Platform (if necessary)"

# VERIFICANDO SE O EUM JÁ ESTÁ INSTALADO
if [ $EUM_DOWNLOAD == true ]; then
    RESULT_GET_AGENT=`$ARTIFACTS_FOLDER/getAgent.sh eum -listonly`
    FILE_VERSION=`echo $RESULT_GET_AGENT | cut -d ':' -f3`
    FILE_COUNT=`ls -1q $ARTIFACTS_FOLDER/*.* | grep -i $FILE_VERSION | wc -l`
    if [[ $FILE_COUNT == 0  ]]
    then
        $ARTIFACTS_FOLDER/getAgent.sh eum
    else
        echo "EUM: Versão do arquivo já existe $FILE_VERSION"
    fi
fi

# VERIFICANDO SE O EC JÁ ESTÁ INSTALADO
if [ $EC_DOWNLOAD == true ]; then
    RESULT_GET_AGENT=`$ARTIFACTS_FOLDER/getAgent.sh ec -listonly`
    FILE_VERSION=`echo $RESULT_GET_AGENT | cut -d ':' -f3`
    FILE_COUNT=`ls -1q $ARTIFACTS_FOLDER/*.* | grep -i $FILE_VERSION | wc -l`
    if [[ $FILE_COUNT == 0  ]]
    then
        $ARTIFACTS_FOLDER/getAgent.sh ec
    else
        echo "EC: Versão do arquivo já existe $FILE_VERSION"
    fi
fi

if [[ $EC_DOWNLOAD = false && $EUM_DOWNLOAD == false ]]; then
  echo
  echo "Valid Components names:"
  echo "          ec"
  echo "          eum"
  echo "          all"
  echo
  echo "Example: ./downloadComponent.sh ec eum"
  echo
  exit 1
fi