#!/bin/bash
exec &> >(tee -a /root/install.log)
exec 2>&1
set -e
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
AVE_UPGRADE_CLIENT_DOWNLOADS_URL=$(get_setting AVE_UPGRADE_CLIENT_DOWNLOADS_URL)
AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE=$(get_setting AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE)
AVE_PASSWORD=$(get_setting AVE_PASSWORD)
AVE_COMMON_PASSWORD=$(get_setting AVE_COMMON_PASSWORD)
AVE_TIMEZONE=$(get_setting AVE_TIMEZONE)
AVE_EXTERNAL_FQDN=$(get_setting AVE_EXTERNAL_FQDN)
EXTERNAL_HOSTNAME=$(get_setting EXTERNAL_HOSTNAME)
AVE_ADD_DATADOMAIN_CONFIG=$(get_setting AVE_ADD_DATADOMAIN_CONFIG)
AVE_DATADOMAIN_HOST=$(get_setting AVE_DATADOMAIN_HOST)
AVE_DDBOOST_USER=$(get_setting AVE_DDBOOST_USER)
AVE_DDBOOST_USER_PWD=$(get_setting AVE_DDBOOST_USER_PWD)
AVE_DATADOMAIN_SYSADMIN=$(get_setting AVE_DATADOMAIN_SYSADMIN)
AVE_DATADOMAIN_SYSADMIN_PWD=$(get_setting AVE_DATADOMAIN_SYSADMIN_PWD)

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
echo "ave-config ready"

if [[ -z  ${AVE_EXTERNAL_FQDN} ]]
then
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
    --input keystore_passphrase=${AVE_COMMON_PASSWORD} \
    --input add_datadomain_config=${AVE_ADD_DATADOMAIN_CONFIG} \
    --input attach_dd_with_cert=false \
    --input accept_eula=true \
    --input datadomain_host=${AVE_DATADOMAIN_HOST} \
    --input ddboost_user=${AVE_DDBOOST_USER} \
    --input ddboost_user_pwd=${AVE_DDBOOST_USER_PWD} \
    --input ddboost_user_pwd_cf=${AVE_DDBOOST_USER_PWD} \
    --input datadomain_sysadmin=${AVE_DATADOMAIN_SYSADMIN} \
    --input datadomain_sysadmin_pwd=${AVE_DATADOMAIN_SYSADMIN_PWD} \
    --input datadomain_snmp_string=public \
    ${AVE_PASSWORD}
else
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
    --input keystore_passphrase=${AVE_COMMON_PASSWORD} \
    --input add_datadomain_config=${AVE_ADD_DATADOMAIN_CONFIG} \
    --input attach_dd_with_cert=false \
    --input accept_eula=true \
    --input datadomain_host=${AVE_DATADOMAIN_HOST} \
    --input ddboost_user=${AVE_DDBOOST_USER} \
    --input ddboost_user_pwd=${AVE_DDBOOST_USER_PWD} \
    --input ddboost_user_pwd_cf=${AVE_DDBOOST_USER_PWD} \
    --input datadomain_sysadmin=${AVE_DATADOMAIN_SYSADMIN} \
    --input datadomain_sysadmin_pwd=${AVE_DATADOMAIN_SYSADMIN_PWD} \
    --input datadomain_snmp_string=public \
    --input rmi_address=${AVE_EXTERNAL_FQDN} \
    ${AVE_PASSWORD}
fi
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
    echo "Starting Installation, this could take 40 Minutes"
    /opt/emc-tools/bin/avi-cli --user root --password "${AVE_COMMON_PASSWORD}" \
    --install upgrade-client-downloads localhost
    echo "Done installing UpgradeClientDownloads"
else
    echo "No curlable URL Provided"        
fi

echo "finished deployment"
