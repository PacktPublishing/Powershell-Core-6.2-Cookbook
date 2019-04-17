throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Very basic Windows component, the file server
Get-WindowsFeature -Name FileAndStorage-Services

# To enable a feature, we can use Install-WindowsFeature
Install-WindowsFeature -Name FileAndStorage-Services -WhatIf

# With the parameter IncludeManagementTools we also get additional, useful features
Install-WindowsFeature -Name FileAndStorage-Services -IncludeManagementTools -WhatIf

# File services alone might not be enough. Let's activate DFS as well
Install-WindowsFeature -Name FileAndStorage-Services,FS-DFS-Replication -IncludeManagementTools

# The management tools for DFS are pretty useful and include e.g. dfsdiag which is still used
Get-Module -Name DFSR -ListAvailable

# Let's create a simple DFS replication group that uses the hub and spoke model with read-only spokes
# This is a pretty common scenario
$hubComputer = 'DFS-FS-A'
$spokeComputer = 'DFS-FS-B','DFS-FS-C'
$allComputers = $hubComputer + $spokeComputer
$replicationGroupName = 'MyReplicationGroup'
$folderName = 'MyFolderTarget'
$contentPath = 'C:\DfsReplicatedFolder'

# First of all, let's see if there already is a replication group
if (Get-DfsReplicationGroup -GroupName $replicationGroupName -ErrorAction SilentlyContinue) { return }

# Very well. Now we can create one. Let's preseed some content
$root = New-Item -ItemType Directory -Path $contentPath 
$null = 1..1000 | % {New-Item -Path $root.FullName -Name "File$_"}

# Now we can enable the feature on the rest of the machines
Invoke-Command -ComputerName $spokeComputer -ScriptBlock {
    Install-WindowsFeature -Name FS-DFS-Replication -IncludeManagementTools
}

# Finally - we can start
$replicationGroup = New-DfsReplicationGroup -GroupName $replicationGroupName -Description 'A simple hub and spoke group' -DomainName contoso.com

# Add the folder
$replicatedFolder = $replicationGroup | New-DfsReplicatedFolder -FolderName $folderName -Description 'Some folder' -DomainName contoso.com

# With that done, add the members
$replicationGroup | Add-DfsrMember -ComputerName $allComputers

# And the connections

foreach ($spokeComputerName in $spokeComputer) 
{
    $connection = Add-DfsrConnection -GroupName $replicationGroupName -SourceComputerName $HubComputer -DestinationComputerName $spokeComputerName -CreateOneWay
}

$memberships = Set-DfsrMembership -GroupName $replicationGroupName -FolderName $folderName -ComputerName ($hubComputer + $spokeComputer) -ContentPath $ContentPath -Force

# Declare this server as primary
$primaryMember = Set-DfsrMembership -GroupName $replicationGroupName -FolderName $folderName -ComputerName $hubComputer -PrimaryMember $true -Force
Update-DfsrConfigurationFromAD -ComputerName $allComputers

# This should not take long. Have a look at the folder contents:
foreach ($spoke in $spokeComputer)
{
    Get-ChildItem "\\$spoke\c$\$(Split-Path $contentPath -Leaf )"
}
