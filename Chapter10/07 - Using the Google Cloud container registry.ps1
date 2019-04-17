throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# As opposed to Azure, you cannot create your own Docker registry
# Google Cloud instead provides a registry for each project

# Get your current project first
$project =  Get-GcpProject -Name testproject

<# The project ID is part of your container registry
US
gcr.io
us.gcr.io

EU
eu.gcr.io

APAC
asia.gcr.io
#>
$imageName = 'eu.gcr.io/{0}/luckynumber:v1' -f $project.ProjectId

# For Docker to be able to authenticate, login with your access token
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://eu.gcr.io

# Enable the container registry API first:
start "https://console.cloud.google.com/apis/api/containerregistry.googleapis.com/overview?project=$($project.ProjectId)"

# The next steps are very similar to Azure
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

docker tag mypolariscore $imageName

# Verify
docker images

# Push
docker push $imageName

# Remove the local image
docker rmi $imageName