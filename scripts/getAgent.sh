#!/bin/bash

current_dir=$(pwd)
script_dir=$(dirname $0)

if [ $script_dir = '.' ]
then
  script_dir="$current_dir"
fi

function showValidComponents () {
    echo "Valid Components names:"
    echo "          enterpriseconsole or ec"
    echo "          db"
    echo "          eum"
    echo "          events-service or es"
    echo "          machineagent or ma"
    echo "          javaagent or agent"
    echo "          webserver"
    echo "          netviz"
    echo "          php"
    echo "          go"
    echo "          synthetics"
    echo "          nodejs"
}

function isVersionGreater()
{
    V1=`printf "%09d%09d%09d%09d" ${1//./ }`
    V2=`printf "%09d%09d%09d%09d" ${2//./ }`

    if [[ "$V1" > "$V2" ]]; then
      echo "1"
    else
      echo "0"
    fi
}

while [ $# -gt 0 ]; do

  PARAM="${1,,}"
  if [ "$PARAM" = "-listonly" ]; then
    LISTONLY=true
  elif [[ "$PARAM" == -minversion=* ]]; then
    MIN_VERSION="${PARAM#*=}"
  elif [[ "$PARAM" == -version=* ]]; then
    VERSION="${PARAM#*=}"
  else
    COMPONENT=$PARAM
  fi
  shift

done

# Usage
if [ "x${COMPONENT}" = "x" ]; then
    echo
    echo "Usage: component [-listonly] [-minversion=] [-version=]"
    echo "ERROR: component is required"
    echo ""
    showValidComponents
  exit 1
fi

echo "Component: $COMPONENT"

#
# Download options
#
if [ "$COMPONENT" = "enterpriseconsole" -o "$COMPONENT" = "ec" ]; then
    PLATFORM="linux"
    matchString="enterprise-console"

elif [ "$COMPONENT" = "db" ]; then
    APPAGENT="db"
    matchString="dbagent"

elif [ "$COMPONENT" = "eum" ]; then
    EUM="linux"
    matchString="euem-64bit-linux\\\S{10,20}.sh"

elif [ "$COMPONENT" = "events-service" -o "$COMPONENT" = "es" ]; then
    EVENTS="linuxwindows"
    matchString="events-service"

elif [ "$COMPONENT" = "machineagent" -o "$COMPONENT" = "ma" ]; then
    APPAGENT="machine"
    matchString="machineagent-bundle-64bit-linux"
    RENAME_TO="MachineAgent.zip"

elif [ "$COMPONENT" = "agent" -o "$COMPONENT" = "javaagent" ]; then
    APPAGENT="jvm"
    matchString="sun-jvm"
    RENAME_TO="AppServerAgent.zip"

elif [ "$COMPONENT" = "dotnet" -o "$COMPONENT" = ".net" ]; then
    APPAGENT="dotnet"
    matchString="dotnet"

elif [ "$COMPONENT" = "webserver" ]; then
    APPAGENT="webserver"
    matchString="appdynamics-sdk-native-nativeWebServer-64bit-linux"

elif [ "$COMPONENT" = "netviz" ]; then
    APPAGENT="netviz"
    matchString="netviz-linux"

elif [ "$COMPONENT" = "ua" ]; then
    APPAGENT="universal-agent"
    matchString="universal-agent-x64-linux"

elif [ "$COMPONENT" = "php" ]; then
    APPAGENT="php"
    matchString="appdynamics-php-agent-x64-linux"

elif [ "$COMPONENT" = "go" ]; then
    APPAGENT="golang-sdk"
    matchString="golang-sdk-x64-linux"

elif [ "$COMPONENT" = "synthetics" ]; then
    EUM="synthetic-server"
    matchString="appdynamics-synthetic-server"

elif [ "$COMPONENT" = "nodejs" ]; then
    APPAGENT="nodejs"
    matchString="golang-sdk-x64-linux"

else
    echo
    echo "ERROR: >$COMPONENT< is invalid"
    echo
    showValidComponents
    exit 1
fi

BASE_URL="https://download.appdynamics.com/download/downloadfile/?"
EXTRA_OPTIONS="&apm_os=windows%2Clinux%2Calpine-linux%2Cosx%2Csolaris%2Csolaris-sparc%2Caix"

curl -s -L -o "${script_dir}/tmpout.json" "${BASE_URL}version=${VERSION}&apm=${APPAGENT}&os=${PLATFORM}&platform_admin_os=${PLATFORM}&events=${EVENTS}&eum=${EUM}${EXTRA_OPTIONS}"

fileJson=`cat "${script_dir}/tmpout.json" | jq "first(.results[]  | select(.s3_path | test(\"${matchString}\"))) | ."`

# Grab the file path from the json output from previous command
fileToDownload=`echo ${fileJson} | jq .s3_path | xargs`
fileVersion=`echo ${fileJson} | jq .version | xargs`

echo "File Version: ${fileVersion}"

if [ -z "$fileToDownload" ]; then
    echo "ERROR: Could not download your request: $COMPONENT"
    exit 1
fi

# If listonly specified, then do not download file.  -z is empty string.
if [ -z "$LISTONLY" ]; then

    if [[ $(isVersionGreater ${fileVersion} ${MIN_VERSION}) = "0" ]]; then

        echo
        echo "No newer version found: Existing version: ${MIN_VERSION}, Found version: ${fileVersion}"
        echo

    else

        echo
        echo "Downloading file : ${fileToDownload}"
        echo

        downloadedFile=$(basename ${fileToDownload})
        curl -L -o "${script_dir}/${downloadedFile}" -O https://download-files.appdynamics.com/${fileToDownload}

        echo
        echo "FILENAME: $downloadedFile"

        if [ "${downloadedFile##*.}" == "sh" ]; then
            chmod 755 ${script_dir}/${downloadedFile}
        fi

        if [ "${RENAME_TO}" != "" ]; then
            mv "${script_dir}/${downloadedFile}" "${script_dir}/${RENAME_TO}"
            echo "${RENAME_TO} file is version: ${fileVersion}" >> $script_dir/file-version.log
        fi

    fi

fi

# cleanup
rm -f $script_dir/cookies.txt $script_dir/tmpout.json $script_dir/index.html