# 201-solution-azurestack-avamar

This Template Deploys and Configures DELL|EMC Avamar Virtual Edition onto Azurestack

Prework and Requirements:
  -  Have Custom Script for Linux extensions Available on AzureStackHub
  -  Upload Avamar AVE VHD for Azure* to Blob in Subscription

Patch /usr/local/avamar/bin/setnet.lib

detectHyperV() {
    isHV=n
    isAZ=n
    grep -A 2 "scsi" /proc/scsi/scsi | grep -qi "msft"
    if [ $? -eq 0 ]; then
        # Its HyperV
        important "Hyper-V environment detected"
        isHV="y"
        hypervisorDetected=2

        # see if its also Azure
        MDATA=`curl -s $AZUREMETADATAURL`
        if [ $? -eq 0 ]; then
            # May be Azure since we got metadata from curl
            JUNK=`echo $MDATA | egrep '^[{].+ID.+UD.+[}]'`
            if [ $? -eq 0 ]; then
              # Azure since we got proper metadata from curl
              isAZ=y
              important "Azure environment detected"
              hypervisorDetected=3
            else
## insert here for AzureStack            
              important "AzureStack environment detected"
              isAZ=y
              hypervisorDetected=3
## End insert, 
# comment next line              
#           warn "Got '$MDATA' from 'curl -s $AZUREMETADATAURL' but not recognized as Azure so ignoring"
            fi
        fi
    fi
}

Optional:
If AVEUpgradeClientDownload URI and Package are Specified, the Custom Script
will try to install the Avamar Client Packages
Load UpgradeClientDownlods to BLOB,S3 or FTP Location with URL Decoded URI
**Examples**:
    - Minio/S3 : http://nasug.home.labbuildr.com:9000/dps-products/avamar/19.2/UpgradeClientDownloads-19.2.0-155.avp?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3admin%2F20200524%2F%2Fs3%2Faws4_request&X-Amz-Date=20200524T042555Z&X-Amz-Expires=432000&X-Amz-SignedHeaders=host&X-Amz-Signature=762d8c4d52804c427ae140e45ab19afd85b253d9e4ce2aba053a3d4087fbc68d

    - AzureBlob with SAS TOKEN: https://opsmanagerimage.blob.local.azurestack.external/packages/UpgradeClientDownloads-19.2.0-155.avp?sv=2017-04-17&ss=bqt&srt=sco&sp=rwdlacup&se=2020-05-30T13:42:54Z&st=2020-05-24T05:42:54Z&spr=https&sig=tjgTdJqheRDNMn4aS1TgkLOulpfe8IKLN1ofHt9U9Ps%3D


AZ CLI Deployment Example:

```azurecli-interactive
az group create --name ave_from_cli --location local
```

```azurecli-interactive
az deployment group validate  \
--template-file azuredeploy.json \
--parameters azuredeploy.parameters.json \
--resource-group ave_from_cli
```

```azurecli-interactive
az deployment group create  \
--template-file azuredeploy.json \
--parameters azuredeploy.parameters.json \
--resource-group ave_from_cli
```


```
az deployment group create  \
--template-uri https://raw.githubusercontent.com/bottkars/201-solution-azurestack-avamar/master/azuredeploy.json \
--parameters https://raw.githubusercontent.com/bottkars/201-solution-azurestack-avamar/master/azuredeploy.parameters.json \
--resource-group ave_from_cli
```
delete

```azurecli-interactive
az group delete --name ave_from_cli  -y
```
