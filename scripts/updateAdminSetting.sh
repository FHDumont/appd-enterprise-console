#!/bin/bash

source ./settings.sh

#base 64 auth key
b64AuthKey="cm9vdCU0MHN5c3RlbTphcHBk"

#controller info
HOST_NAME_PARAM=$1
PORT=`cat $ARTIFACTS_FOLDER/platform_response.varfile | grep controllerPrimaryPort | cut -d '=' -f2`
ADMIN_SETTING=$2
ADMIN_SETTING_VALUE=$3

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

if [[ $jsessionId != "" ]] && [[ $csrfToken != "" ]]; then

	JSON="{\"name\":\"$ADMIN_SETTING\",\"value\":\"$ADMIN_SETTING_VALUE\"}"

    # echo "jsessionId: $jsessionId - csrfToken:$csrfToken"
	# echo "json $JSON"

	# curl --verbose -s \
	# RETURN=`curl --verbose -s -i \
	RETURN=`curl -s \
			--header "Accept: application/json, text/plain, */*" \
			--header "Accept-Encoding: gzip, deflate" \
			--header "Cache-Control: no-cache" \
			--header "Content-Type: application/json;charset=utf-8" \
			--header "Cookie: $jsessionId X-CSRF-TOKEN=$csrfToken" \
			--header "Host: ${HOST_NAME_PARAM}:${PORT}" \
			--header "X-CSRF-TOKEN: $csrfToken" \
			--data "${JSON}" \
			http://${HOST_NAME_PARAM}:${PORT}/controller/restui/admin/configuration/set`
	
	# echo "RETORNO: $RETURN"

# Request URL: http://labs-nosshcontroller-coupfb6d.appd-cloudmachine.com:8080/restui/admin/account/update/v2
# {"accountData":{"id":2,"browserRumLicenseType":null,"browserRumOverageAllowed":null,"globalAccountName":"customer1_5fc78e6a-f187-45ea-bb4d-66afedb7e13e","mobileRumLicenseType":null,"mobileRumOverageAllowed":null,"securityProvider":"INTERNAL","accessKey":"19315ac4-1d05-4ef6-896c-23b14d101a66","licenseId":"customer1-license","licenseType":"ONPREM-ACCOUNT","hardwareFingerprint":"ANY","displayName":"customer1","licenseModel":"INFRASTRUCTURE_BASED","environmentSku":"PROD","name":"customer1","properties":[{"name":"appdynamics.licensing.infra-based.account.migration-date","value":"1620882892046"},{"name":"appdynamics.licensing.infra-based.account.migration-status","value":"MIGRATED"}],"expirationDate":"2021-08-10T00:00:00.000Z","provisioningEntries":[{"packageName":"INFRA","provisionedUnits":100,"retentionPeriod":null,"startDate":"2021-05-12T00:00:00Z","expirationDate":"2021-08-10T00:00:00Z"},{"packageName":"LOG_ANALYTICS_PRO","provisionedUnits":10,"retentionPeriod":null,"startDate":"2021-05-12T00:00:00Z","expirationDate":"2021-08-10T00:00:00Z"},{"packageName":"ENTERPRISE","provisionedUnits":100,"retentionPeriod":null,"startDate":"2021-05-12T00:00:00Z","expirationDate":"2021-08-10T00:00:00Z"},{"packageName":"PREMIUM","provisionedUnits":100,"retentionPeriod":null,"startDate":"2021-05-12T00:00:00Z","expirationDate":"2021-08-10T00:00:00Z"}],"edition":null,"eumCloudLicenseKey":"1f01ffaf-ff94-42ec-95a9-cec54295a536","eumAccountName":"test-eum-account-fernandodumont-1620869929886"},"accountAdmin":null,"systemAccount":false,"hasValidServerVisibilityPackage":null}

# curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"id":100}' http://localhost/api/postJsonReader.do

else
	echo "Problem with response headers."
fi
