throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# To use DSC with Azure Stack VMs, you will need to get familiar with ARM templates

# Start with the configuration scipt and the config data
$cData = {
    @{
        Files = @(
            @{
                DestinationPath = 'C:\File1'
                Type            = 'File'
                Contents        = 'On Azure as well'
            }
            @{
                DestinationPath = 'C:\File2'
                Type            = 'File'
                Contents        = 'On Azure as well'
            }
            @{
                DestinationPath = 'C:\File3'
                Type            = 'File'
                Contents        = 'On Azure as well'
            }
        )
    }
}

$cScript = {
    configuration config
    {
        Import-DscResource -ModuleName PSDesiredStateConfiguration

        foreach ($file in $ConfigurationData.Files)
        {
            File (Split-Path -Leaf $file)
            {
                DestinationPath = $file.DestinationPath
                Type            = $file.Type
                Contents        = $file.Contents
            }
        }
    }
}

$cData.ToString() | Set-Content configdata.psd1


# Prepare the configuration archive
mkdir config
$cScript.ToString() | Set-Content .\config\configscript.ps1
Compress-Archive .\config\* -DestinationPath .\config.zip

# Create a storage account and upload the configuration
New-AzureRmResourceGroup -Name alltheconfigs -Location local
$account = New-AzureRmStorageAccount -Name dscthings -ResourceGroupName alltheconfigs -Location local -SkuName Standard_LRS
$container = New-AzureStorageContainer -Name mofs -Context $account.Context 
$content = Set-AzureStorageBlobContent -File .\config.zip -CloudBlobContainer $container.CloudBlobContainer -Blob config.zip -Context $account.Context -Force
$token = New-AzureStorageBlobSASToken -CloudBlob $content.ICloudBlob -StartTime (Get-Date) -ExpiryTime (Get-date).AddMonths(2) -Protocol HttpsOnly -Context $account.Context -Permission r

# Upload the confg data as well
$contentData = Set-AzureStorageBlobContent -File .\configdata.psd1 -CloudBlobContainer $container.CloudBlobContainer -Blob configdata.psd1 -Context $account.Context -Force
$tokenData = New-AzureStorageBlobSASToken -CloudBlob $contentData.ICloudBlob -StartTime (Get-Date) -ExpiryTime (Get-date).AddMonths(2) -Protocol HttpsOnly -Context $account.Context -Permission r


# Create the template
@"
{
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "adminUsername": {
            "type": "string",
            "metadata": {
                "description": "Username for the Virtual Machine."
            }
        },
        "adminPassword": {
            "type": "securestring",
            "metadata": {
                "description": "Password for the Virtual Machine."
            }
        }
    },
    "variables": {
        "storageAccountName": "[concat(uniquestring(resourceGroup().id), 'saddiskvm')]",
        "addressPrefix": "10.0.0.0/16",
        "subnet1Name": "Subnet-1",
        "subnet1Prefix": "10.0.0.0/24",
        "imagePublisher": "MicrosoftWindowsServer",
        "imageOffer": "WindowsServer",
        "imageSKU": "2016-Datacenter",
        "imageVersion": "latest",
        "storageAccountType": "Standard_LRS",
        "virtualNetworkName": "azStackVnet",
        "vmName": "AzSVm01",
        "vnetID": "[resourceId('Microsoft.Network/virtualNetworks',variables('virtualNetworkName'))]",
        "nicName": "azStackNic",
        "subnet1Ref": "[concat(variables('vnetID'),'/subnets/',variables('subnet1Name'))]"
    },
    "resources": [
        {
            "type": "Microsoft.Storage/storageAccounts",
            "name": "[variables('storageAccountName')]",
            "apiVersion": "2017-11-09",
            "location": "[resourceGroup().location]",
            "sku": {
                "name": "[variables('storageAccountType')]"
            }
        },
        {
            "apiVersion": "2017-10-01",
            "type": "Microsoft.Network/virtualNetworks",
            "name": "[variables('virtualNetworkName')]",
            "location": "[resourceGroup().location]",
            "properties": {
                "addressSpace": {
                    "addressPrefixes": [
                        "[variables('addressPrefix')]"
                    ]
                },
                "subnets": [
                    {
                        "name": "[variables('subnet1Name')]",
                        "properties": {
                            "addressPrefix": "[variables('subnet1Prefix')]"
                        }
                    }
                ]
            }
        },
        {
            "apiVersion": "2018-10-01",
            "type": "Microsoft.Network/networkInterfaces",
            "name": "[variables('nicName')]",
            "location": "[resourceGroup().location]",
            "dependsOn": [
                "[concat('Microsoft.Network/virtualNetworks/', variables('virtualNetworkName'))]"
            ],
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "ipconfig1",
                        "properties": {
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[variables('subnet1Ref')]"
                            }
                        }
                    }
                ]
            }
        },
        {
            "apiVersion": "2016-03-30",
            "type": "Microsoft.Compute/virtualMachines",
            "name": "[variables('vmName')]",
            "location": "[resourceGroup().location]",
            "dependsOn": [
                "[concat('Microsoft.Storage/storageAccounts/', variables('storageAccountName'))]",
                "[concat('Microsoft.Network/networkInterfaces/', variables('nicName'))]"
            ],
            "properties": {
                "hardwareProfile": {
                    "vmSize": "Standard_A2"
                },
                "osProfile": {
                    "computerName": "[variables('vmName')]",
                    "adminUsername": "[parameters('adminUsername')]",
                    "adminPassword": "[parameters('adminPassword')]"
                },
                "storageProfile": {
                    "imageReference": {
                        "publisher": "[variables('imagePublisher')]",
                        "offer": "[variables('imageOffer')]",
                        "sku": "[variables('imageSKU')]",
                        "version": "[variables('imageVersion')]"
                    },
                    "osDisk": {
                        "osType": "Windows",
                        "name": "azStackOs",
                        "caching": "ReadWrite",
                        "createOption": "FromImage",
                        "managedDisk": {
                            "storageAccountType": "StandardSSD_LRS"
                        },
                        "diskSizeGB": 128
                    }
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "id": "[resourceId('Microsoft.Network/networkInterfaces',variables('nicName'))]"
                        }
                    ]
                }
            }
        },
        {
            "apiVersion": "2016-03-30",
            "type": "Microsoft.Compute/virtualMachines/extensions",
            "name": "AzSVm01/dscconfig",
            "location": "[resourceGroup().location]",
            "dependsOn": [
                "[resourceId('Microsoft.Compute/virtualMachines', 'AzSVm01')]"
            ],
            "properties": {
                "publisher": "Microsoft.Powershell",
                "type": "DSC",
                "typeHandlerVersion": "2.76",
                "autoUpgradeMinorVersion": true,
                "settings": {
                    "configuration": {
                        "url": "$($content.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri)",
                        "script": "configscript.ps1",
                        "function": "config"
                    },
                    "configurationData": {
                        "url": "$($contentData.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri)"
                    }
                },
                "protectedSettings": {
                    "configurationUrlSasToken": "$token",
                    "configurationDataUrlSasToken": "$tokenData"
                }
            }
        }
    ]
}
"@ | Set-Content template.json


# Deploy the template
New-AzureRmResourceGroup -Name fromTemplate -Location local

$parma = @{
    Name = 'dep01'
    ResourceGroupName = 'fromTemplate'
    TemplateFile = '.\template.json'
    adminUsername = 'ScroogeMcDuck'
    adminPassword = ('M0neyM4ker!' | ConvertTo-SecureString -AsPlainText -Force)
}
New-AzureRmResourceGroupDeployment @parma