throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Resource group templates can automate the deployment of a complete
# service, e.g. a web app consisting of a highly available database,
# a web frontend, an authentication component, networking and so on
$template = @{
    # Schema and content are mandatory
    '$schema'      = "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"

    # Each template should at the very least contain some resource
    resources      = @(
        @{
            # The type of each resource is fixed. Here, we deploy a storage account
            type       = "Microsoft.Storage/storageAccounts"

            # The name of the resource. A storage account needs to be unique in a region
            name       = -join [char[]](1..10 | foreach {Get-Random -Minimum 97 -Maximum 123})
            apiVersion = "2018-07-01"

            # You can use many different functions inside a template
            location   = "[resourceGroup().location]"
            sku        = @{
                name = "[parameters('storageaccounttype')]"
            }
        }
    )

    # Parameters are requested at runtime and can contain something like a ValidateSet
    parameters     = @{
        storageaccounttype = @{
            type          = "string"
            defaultValue  = "Standard_LRS"
            allowedValues = @(
                "Premium_LRS",
                "Standard_LRS",
                "Standard_GRS"
            )
        }
    }

    # and Variables can be used within a template
    variables      = @{}    
}

# Store or use directly
$template | ConvertTo-Json | Set-Content template.json

# Deploy!
New-AzResourceGroup WithDeployment -Location 'West europe'

# File
New-AzResourceGroupDeployment -Name MyDeployment -ResourceGroupName WithDeployment -Mode Complete -TemplateFile .\template.json -storageaccounttype Standard_LRS

# Hashtable
New-AzResourceGroupDeployment -Name MyDeployment -ResourceGroupName WithDeployment -Mode Complete -TemplateObject $template -storageaccounttype Standard_LRS

# After the validation, the deployment will commence
Get-AzStorageAccount -ResourceGroupName WithDeployment