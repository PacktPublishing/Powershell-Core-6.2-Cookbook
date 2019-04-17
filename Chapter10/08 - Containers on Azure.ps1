throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# In recipe "Using the Azure container registry" you created your own private repo
# Lets pull from that

# List existing container groups
Get-AzContainerGroup

# Run your container in a group
$containerRegistry = Get-AzContainerRegistry -ResourceGroupName MyContainers -Name ContainersGalore
$containerCredential = $containerRegistry | Get-AzContainerRegistryCredential

# We need the following cmdlets
Get-Command -Module Az.ContainerInstance

$param = @{
    ResourceGroupName = 'MyContainers'
    Name = 'luckynumber7'
    Image = "$($containerRegistry.LoginServer)/luckynumber:v1"
    OsType = 'Windows'
    IpAddressType = 'Public'
    Port = 8080
    RegistryCredential = [pscredential]::new($containerCredential.UserName, ($containerCredential.Password | ConvertTo-SecureString -AsPlainText -Force))
}

# Create new container instances
New-AzContainerGroup @param

# List running containers - with Linux you can even deploy more than one container in a group
# like it was intended.
Get-AzContainerGroup

# Try it!
$ip = (Get-AzContainerGroup).IpAddress
Invoke-RestMethod -Method Get -Uri "http://$($ip):8080/containerizedapi"

# What is our container doing? Retrieve all output
Get-AzContainerInstanceLog -ResourceGroupName MyContainers -ContainerGroupName luckynumber7

# A container's life is finite...
Remove-AzContainerGroup -Name luckynumber7 -ResourceGroupName MyContainers
