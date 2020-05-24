#!/bin/bash
exec &> >(tee -a ./install.log)
exec 2>&1
set -ex
function retryop()
{
  retry=0
  max_retries=$2
  interval=$3
  while [ ${retry} -lt ${max_retries} ]; do
    echo "Operation: $1, Retry #${retry}"
    eval $1
    if [ $? -eq 0 ]; then
      echo "Successful"
      break
    else
      let retry=retry+1
      echo "Sleep $interval seconds, then retry..."
      sleep $interval
    fi
  done
  if [ ${retry} -eq ${max_retries} ]; then
    echo "Operation failed: $1"
    exit 1
  fi
}
echo "Installing jq"
curl -s -O -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod 755 jq-linux64
chmod +X  jq-linux64
mv jq-linux64 /usr/local/bin/jq
export PATH=/opt/emc-tools/bin:$PATH
printenv

function get_setting() {
  key=$1
  local value=$(echo $settings | jq ".$key" -r)
  echo "${value}" ## ( use "${VAR}" to retain spaces, KB)
}


until [ -f /var/lib/waagent/CustomDataClear ]
do
     sleep 5
done
custom_data_file="/var/lib/waagent/CustomDataClear"
settings=$(cat ${custom_data_file})
AVE_UPGRADE_CLIENT_DOWNLOADS_URL="https://opsmanagerimage.blob.local.azurestack.external/packages/UpgradeClientDownloads-19.2.0-155.avp?sv=2017-04-17&ss=bqt&srt=sco&sp=rwdlacup&se=2020-05-30T13:42:54Z&st=2020-05-24T05:42:54Z&spr=https&sig=tjgTdJqheRDNMn4aS1TgkLOulpfe8IKLN1ofHt9U9Ps%3D"
AVE_UPGRADE_CLIENT_DOWNLOADS_URL="http://nasug.home.labbuildr.com:9000/dps-products/avamar/19.2/UpgradeClientDownloads-19.2.0-155.avp?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3admin%2F20200524%2F%2Fs3%2Faws4_request&X-Amz-Date=20200524T042555Z&X-Amz-Expires=432000&X-Amz-SignedHeaders=host&X-Amz-Signature=762d8c4d52804c427ae140e45ab19afd85b253d9e4ce2aba053a3d4087fbc68d"
AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE=UpgradeClientDownloads-19.2.0-155.avp
AVE_UPGRADE_CLIENT_DOWNLOADS_URL=$(get_setting AVE_UPGRADE_CLIENT_DOWNLOADS_URL)
AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE=$(get_setting AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE)
AVE_PASSWORD=$(get_setting AVE_PASSWORD)
AVE_COMMON_PASSWORD=$(get_setting AVE_COMMON_PASSWORD)
EXTERNAL_HOSTNAME=$(get_setting EXTERNAL_HOSTNAME)


WORKFLOW=AveConfig
echo "waiting for AVAMAR $WORKFLOW  to be available"
### get the SW Version
until [[ ! -z $AVE_CONFIG ]]
do
AVE_CONFIG=$(/opt/emc-tools/bin/avi-cli --user root --password "${AVE_PASSWORD}" \
 --listrepository ${AVE_PASSWORD} \
 | grep ${WORKFLOW} | awk  '{print $1}' )
sleep 5
printf "."
done


echo "waiting for ave-config to become ready"
until [[ $(/opt/emc-tools/bin/avi-cli --user root --password "${AVE_PASSWORD}" \
 --listhistory ${AVE_PASSWORD} | grep ave-config | awk  '{print $5}') == "ready" ]]
do
printf "."
sleep 5
done



AVE_TIMEZONE="Europe/Berlin"
AVE_COMMON_PASSWORD="Change_Me12345_"
/opt/emc-tools/bin/avi-cli --user root --password "${AVE_PASSWORD}" --install ave-config  \
    --input timezone_name="${AVE_TIMEZONE}" \
    --input common_password=${AVE_COMMON_PASSWORD} \
    --input use_common_password=true \
    --input repl_password=${AVE_COMMON_PASSWORD} \
    --input rootpass=${AVE_COMMON_PASSWORD} \
    --input mcpass=${AVE_COMMON_PASSWORD} \
    --input viewuserpass=${AVE_COMMON_PASSWORD} \
    --input admin_password_os=${AVE_COMMON_PASSWORD} \
    --input root_password_os=${AVE_COMMON_PASSWORD} \
    ${AVE_PASSWORD}

if [[ -z  ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} ]]
then
    unset AVE_UPGRADE_CLIENT_DOWNLOADS_URL
    echo "No Avamar Package Provided"
elif [[ ! -z ${AVE_UPGRADE_CLIENT_DOWNLOADS_URL} ]]
then
    echo "Downloading ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE}"
    curl -k "${AVE_UPGRADE_CLIENT_DOWNLOADS_URL}" --output /space/avamar/repo/packages/${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE}
    echo "Waiting for Package ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} to become available"
    until [[ $(/opt/emc-tools/bin/avi-cli --user root --password "${AVE_COMMON_PASSWORD}" --listrepository localhost \
    | grep ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} \
    | awk '{print $5}') == "Accepted" ]]
    do
        printf "."
        sleep 5
    done
    echo "${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} Accepted"
    echo "Starting Installation, this could take 40 Mintes"
    /opt/emc-tools/bin/avi-cli --user root --password "${AVE_COMMON_PASSWORD}" \
    --install upgrade-client-downloads localhost
    echo "Done installing UpgradeClientDownloads"
else
    echo "No curlable URL Provided"        
fi



# this also installs :-)
# /opt/emc-tools/bin/avi-cli --user root --password "${AVE_COMMON_PASSWORD}" --install upgrade-client-downloads localhost