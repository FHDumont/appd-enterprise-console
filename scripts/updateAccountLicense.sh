#!/bin/bash

source ./settings.sh

#base 64 auth key
b64AuthKey="cm9vdCU0MHN5c3RlbTphcHBk"

#controller info
HOST_NAME_PARAM=$1
PORT=`cat $ARTIFACTS_FOLDER/platform_response.varfile | grep controllerPrimaryPort | cut -d '=' -f2`

jsessionId=""
csrfToken=""

cookies=($(curl -I --header "Authorization: Basic ${b64AuthKey}" -X GET http://${HOST_NAME_PARAM}:${PORT}/controller/auth?action=login | grep -Fi set-cookie))
length=${#cookies[@]}

for ((i = 0; i != length; i++)); do

	cookie=${cookies[i]}
	
	if [[ $cookie == *"JSESSIONID"* ]]; then
  		jsessionId=$cookie
  	elif [[ $cookie == *"X-CSRF-TOKEN"* ]]; then
  		IFS='=' 
  		read -ra ADDR <<< "$cookie"
  		csrfToken=${ADDR[1]}
        csrfToken=${csrfToken%?}
	fi

done

EUM_ACCOUNT_NAME=`cat $PLATFORM_FOLDER/controller/license.lic | grep -i eum-account-name |  cut -d ':' -f2 | xargs`
EUM_LICENSE_KEY=`cat $PLATFORM_FOLDER/controller/license.lic | grep -i eum-license-key |  cut -d ':' -f2 | xargs`

if [[ $jsessionId != "" ]] && [[ $csrfToken != "" ]]; then

	JSON=`curl -s \
			--header "Accept: application/json, text/plain, */*" \
			--header "Accept-Encoding: gzip, deflate" \
			--header "Cache-Control: no-cache" \
			--header "Content-Type: application/json;charset=utf-8" \
			--header "Cookie: $jsessionId X-CSRF-TOKEN=$csrfToken" \
			--header "Host: ${HOST_NAME_PARAM}:${PORT}" \
			--header "X-CSRF-TOKEN: $csrfToken" \
			http://${HOST_NAME_PARAM}:${PORT}/restui/admin/account/v2/2`


	JSON=`echo ${JSON} | jq '.accountData.eumAccountName = $v' --arg v ${EUM_ACCOUNT_NAME}`
	JSON=`echo ${JSON} | jq '.accountData.eumCloudLicenseKey = $v' --arg v ${EUM_LICENSE_KEY}`

	POST_RETURN=`curl \
			--header "Accept: application/json, text/plain, */*" \
			--header "Accept-Encoding: gzip, deflate" \
			--header "Cache-Control: no-cache" \
			--header "Content-Type: application/json;charset=utf-8" \
			--header "Cookie: $jsessionId X-CSRF-TOKEN=$csrfToken" \
			--header "Host: ${HOST_NAME_PARAM}:${PORT}" \
			--header "X-CSRF-TOKEN: $csrfToken" \
			-X POST \
			-d ${JSON} \
			http://${HOST_NAME_PARAM}:${PORT}/restui/admin/account/update/v2`

else
	echo "Problem with response headers."
fi
