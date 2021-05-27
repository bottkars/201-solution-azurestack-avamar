# 201-solution-azurestack-avamar

This Template Deploys and Configures DELL|EMC Avamar Virtual Edition onto Azurestack

Prework and Requirements:
  -  Have Custom Script for Linux extensions Available on AzureStackHub
  -  Upload Avamar AVE VHD for Azure to Blob in Subscription
  -  Mont the vhd to a linux vm and modify the cloud detection script
  -  
## How To create the Avamar VHD for AzureStack
We need to get the Avamar Azure vhd. It is Available from >Dell Support. Keep in mind, it has 180GB in Size when extracted.
There are Multiple Methods how to obtain The Image, the Preerred one is Method 1.
### Obtaining the Image: 
Download the Azure Version from Dell Support (Login required)
[Avamar 19.4 Virtual Edition for Microsoft (Azure) Cloud](https://dl.dell.com/downloads/DL100999_Avamar-19.4-Virtual-Edition-for-Microsoft-(Azure)-Cloud.7z)



### Expand and upload the Image

```bash
7z e AZURE-AVE-19.4.0.116.vhd.7z
``` 

Use Azure CLI or AzureSTack Portal to upload the image to a blob container:


```bash
ACCOUNT_NAME=opsmanagerimage
DESTINATION="Avamar/19.4"
az storage blob upload-batch --account-name ${ACCOUNT_NAME} -d images --destination-path ${DESTINATION} --source ./ --pattern "AVE-19.4.0.116-disk*.vhd"
```


## Patch /usr/local/avamar/bin/setnet.lib
Avamar detects the CLoud t runś on Upon first boot. This will modify some behaviour for services like wicked, dhcp, boot and reseource disks.
Once Uploaded to a Storage Account, 
In order to make Avamar be happy with Azure Stack, modify the following Lines in the detectHyperv() function in the vhd in /usr/local/avamar/bin/setnet.lib


```bash
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
```

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


## Gitops Direnv




```azurecli-interactive
az group create --name ${AZS_RESOURCE_GROUP} \
  --location ${AZS_LOCATION}
```

```azurecli-interactive
az deployment group validate  \
--template-file $HOME/workspace/201-solution-azurestack-avamar/azuredeploy.json \
--parameters $HOME/workspace/201-solution-azurestack-avamar/azuredeploy.parameters.json \
--parameters aveName=${AZS_HOSTNAME} \
--parameters aveImageURI=${AZS_IMAGE_URI} \
--parameters aveUpgradeClientDownloadsPackage="${AZS_PACKAGE}" \
--parameters diagnosticsStorageAccountExistingResourceGroup=${AZS_diagnosticsStorageAccountExistingResourceGroup} \
--parameters diagnosticsStorageAccountName=${AZS_diagnosticsStorageAccountName} \
--parameters vnetName=${AZS_vnetName} \
--parameters vnetSubnetName=${AZS_vnetSubnetName} \
--resource-group ${AZS_RESOURCE_GROUP}

```

```azurecli-interactive
az deployment group create  \
--template-file $HOME/workspace/201-solution-azurestack-avamar/azuredeploy.json \
--parameters $HOME/workspace/201-solution-azurestack-avamar/azuredeploy.parameters.json \
--parameters aveName=${AZS_HOSTNAME} \
--parameters aveImageURI=${AZS_IMAGE_URI} \
--parameters aveUpgradeClientDownloadsPackage="${AZS_PACKAGE}" \
--parameters diagnosticsStorageAccountExistingResourceGroup=${AZS_diagnosticsStorageAccountExistingResourceGroup} \
--parameters diagnosticsStorageAccountName=${AZS_diagnosticsStorageAccountName} \
--parameters vnetName=${AZS_vnetName} \
--parameters vnetSubnetName=${AZS_vnetSubnetName} \
--resource-group ${AZS_RESOURCE_GROUP}
```

```
az group delete --name ${AZS_RESOURCE_GROUP}
```
## Alternate Method for Creating a VHD, e.g from OVA (does not include waagent, so needs to be applied )
#### install qemu-utils and p7zip
```bash
sudo apt install p7zip-full qemu-utils
``` 

#### Extract and Convert
```
7z e AVE-19.4.0.116.ova

qemu-img convert -f vmdk -o subformat=fixed,force_size -O vpc AVE-19.4.0.116-disk1.vmdk AVE-19.4.0.116-disk1.vhd
``` 
