throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# A private container registry provides a way of hosting your own containerized apps
# The containers come first though. Remember chapter 7?
#region chapter 7
mkdir polaris
Save-Module -Name Polaris -Path .\polaris
@"
# The image our container is based on
FROM mcr.microsoft.com/windows/servercore:ltsc2016

# Our image requires a port to be opened
EXPOSE 8080

# Copy the Polaris module
COPY ["Polaris/", "C:/Program Files/WindowsPowerShell/Modules/Polaris/"]

# Copy the script
COPY startpolaris.ps1 startpolaris.ps1

# We want to run something
CMD ["powershell.exe", "-File", "./startpolaris.ps1"]
"@ | Set-Content .\polaris\Dockerfile

# The Polaris script is very, very simple
@'
Install-PackageProvider -Name nuget -Force
Install-Module Polaris -Force
New-PolarisGetRoute -Path /containerizedapi -Scriptblock {$response.Send("{`"luckyNumber`": $(Get-Random -min 0 -max 9999)}");}
Start-Polaris -Port 8080
while ($true)
{ sleep 1 }
'@ | Set-Content .\polaris\startpolaris.ps1

# Awesome. Merge your customizations with the base image by using docker build
docker build .\polaris -t mypolariscore
#endregion

# First comes a resource group for your container registry
New-AzResourceGroup -Name MyContainers -Location westeurope

# Next, the container registry
New-AzContainerRegistry -ResourceGroupName MyContainers -Name ContainersGalore -Location Westeurope -Sku Basic -EnableAdminUser

# Your credentials are retrieved like this
Get-AzContainerRegistryCredential -ResourceGroupName MyContainers -Name ContainersGalore

# Next up, log in with Docker CLI
$containerRegistry = Get-AzContainerRegistry -ResourceGroupName MyContainers -Name ContainersGalore
$containerCredential = $containerRegistry | Get-AzContainerRegistryCredential
$containerCredential.Password | docker login $containerRegistry.LoginServer -u $containerCredential.Username --password-stdin

# Tag your container
docker tag mypolariscore "$($containerRegistry.LoginServer)/luckynumber:v1"

# Verify
docker images

# Push
docker push "$($containerRegistry.LoginServer)/luckynumber:v1"

# Remove the local image
docker rmi "$($containerRegistry.LoginServer)/luckynumber:v1"