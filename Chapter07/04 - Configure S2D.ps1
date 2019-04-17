throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# A new feature of Windows Server 2016, S2D clusters are perfect for
# your hyperconverged infrastructure that takes the form of a Scale-out file server
$fileServers = 'PACKT-FS-A','PACKT-FS-B','PACKT-FS-C'

# The list of features to deploy S2D is a bit longer
$features = @(
    'Failover-Clustering',
    'Data-Center-Bridging',
    'RSAT-Clustering-PowerShell',
    'Hyper-V-PowerShell',
    'FS-FileServer'
)

Invoke-Command -ComputerName $fileServers -ScriptBlock {
    Install-WindowsFeature -Name $using:features
}

# The storage module plays a major role. as a cdxml module, it is compatible with PS Core
# Since we can use CIM remoting, we start with sessions
$cimsessions = New-CimSession -ComputerName $fileServers

# First of all, you should update the storage cache. Remember that menu item in diskmgmt.msc?
# This is the accompanying PowerShell cmdlet.
Update-StorageProviderCache -CimSession $cimsessions

# We need disks that can be used in our S2D cluster
# i.e. Disks that are not yet part of a pool, that don't contain virtual disks and that are no system disks
Get-Disk -CimSession $cimsessions | Where-Object {
    -not $_.IsBoot -and -not $_.IsSystem -and $_.PartitionStyle -eq 'RAW'
}

# Before creating a cluster, it is recommended to run a test in order to determine the fitness of the components
# Sadly, this is another cmdlet not available to PS Core
Import-WinModule FailoverClusters
$clusterTest = Test-Cluster -Node $fileServers -Include 'Storage Spaces Direct', Inventory, Network, 'System Configuration'
start $clusterTest.FullName

# Test succesful? Then it's off to a supported cluster
$cluster = New-Cluster -Name S2DCluster -Node $fileServers -NoStorage -StaticAddress 192.168.56.99

# That wasn't too bad
# Next, we add a cluster witness to help build a quorum. If you want to, try the Azure Cloud Witness
$null = New-AzResourceGroup -Name witnesses -Location 'West Europe'
$account = New-AzStorageAccount -ResourceGroupName witnesses -Name packtwitnesses -Location 'West Europe' -SkuName Standard_LRS
$keys = $account | Get-AzStorageAccountKey
$cluster | Set-ClusterQuorum -CloudWitness -AccountName $account.StorageAccountName -AccessKey $keys[0].Value

# If your environment is not connected, a node majority will be enough
$cluster | Set-ClusterQuorum -NodeMajority

# The next step is unbelievably simple
Enable-ClusterStorageSpacesDirect -Confirm:$false

# Next we can start creating our CSVs - cluster-shared volumes
New-Volume -FriendlyName FirstVolume -FileSystem CSVFS_ReFS -StoragePoolFriendlyName S2D* -Size 10GB

# From here on you can go in many direction, for example a SOFS - or Scale Out File Server
Add-ClusterScaleOutFileServerRole -Name FiletMignon -Cluster S2DCluster
