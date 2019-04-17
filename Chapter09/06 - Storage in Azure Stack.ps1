throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Provisioning storage for VM OS disks, applications, ... starts with
# The cmdlets
Get-Command -Noun AzureRmStorage*, AzureStorage*

# a Resource Group
New-AzureRmResourceGroup -Name StorageAccounts -Location 'local'

# Before you can create a storage account (Only v1! Only LRS!)
$saParam = @{
    ResourceGroupName = 'StorageAccounts'
    Name              = -join (1..15 | % {Get-Random -min 1 -max 9})
    SkuName           = 'Standard_LRS'
    Location          = 'local'
    Kind              = 'Storage'
}

$sa = New-AzureRmStorageAccount @saParam

# Typically used for VHD files is a blob storage with page blobs
$blobby = New-AzureStorageContainer -Name vmDisks -Context $sa.Context

# These blob containers are also used in an automated deployment
# and can for example host your DSC configurations or PowerShell scripts

# To manually upload, create a new container
$container = New-AzureStorageContainer -Name dscmofs -Context $sa.Context -ErrorAction SilentlyContinue

configuration AzSBaseline
{
    node @('vm1', 'vm2', 'vm3')
    {
        File TimeStamp
        {
            DestinationPath = 'C:\DeployedOn'
            Contents        = Get-Date -Format yyyy-MM-dd
            Type            = 'File'
        }
    }
}

$content = AzSBaseline | ForEach-Object {
    Set-AzureStorageBlobContent -File $_.FullName -CloudBlobContainer $container.CloudBlobContainer -Blob $_.Name -Context $account.Context -Force
}

# most other features of storage accounts are not supported
# Should you need your storage account credentials nevertheless, try
$sa.Context
$sa | Get-AzureRmStorageAccountKey