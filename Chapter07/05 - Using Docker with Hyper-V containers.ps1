throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Docker and containers are all the rage. Using them on Windows is not that
# complicated, and entirely done with PowerShell Core.
# Execute the following steps on PACKT-HV1

# To be able to use containers, we need to activate them
powershell -command "& {Install-WindowsFeature Containers}"

# Docker is a popular container engine. We can use the PowerShell Gallery to deploy
Install-Module -Name Docker -Force

# With the module installed, we can use it to install dockerd
Install-Docker

# To make use of docker, you will - at some point - need to download a container image
# Notice that the commands are the same on Windows as well as Linux
docker pull mcr.microsoft.com/powershell:6.2.0-nanoserver-1809

# Are you wondering where your image is stored?
Get-ChildItem -Path (Join-Path -Path $env:ProgramData -ChildPath Docker) -File -Recurse

# You can more comfortably list them like this
docker images

# Run the container. -it gives you an interactive prompt
docker run -it mcr.microsoft.com/powershell:6.2.0-nanoserver-1809

# After a few seconds, you are running PowerShell Core on a Nano Server image
$PSVersionTable # 6.2.0, Core

# Exit the container
exit

# To list running containers you use
docker ps

# An in our special case to see stopped containers
docker ps -a

# A container is an image with an additional layer merged on top of it
# You can prepare this using a DockerFile
# Download one dependency
Save-Module -Name Polaris -Path .\polaris
@"
# The image our container is based on
FROM mcr.microsoft.com/powershell:6.2.0-nanoserver-1809

# Our image requires a port to be opened
EXPOSE 8080

# Copy the Polaris module
COPY ["Polaris/", "C:/Program Files/PowerShell/Modules/Polaris/"]

# Copy the script
COPY startpolaris.ps1 startpolaris.ps1

# We want to run something
CMD ["pwsh.exe", "-File", "./startpolaris.ps1"]
"@ | Set-Content .\polaris\Dockerfile

# The Polaris script is very, very simple
@'
New-PolarisGetRoute -Path /containerizedapi -Scriptblock {$response.Send("Your lucky number is $(Get-Random -min 0 -max 9999)");}
Start-Polaris -Port 8080
while ($true)
{ sleep 1 }
'@ | Set-Content .\polaris\startpolaris.ps1

# Awesome. Merge your customizations with the base image by using docker build
docker build .\polaris -t myrepo:mypolaris

# You can start your tagged image now as a daemon (-d) and with source port 8080 bound to container port 8080
$containerId = docker run -d -p 8080:8080 myrepo:mypolaris

# Have a look at your container - the format is JSON
$result = docker inspect $containerId
$ip = ($result | ConvertFrom-Json).networksettings.networks.nat.ipaddress
Invoke-RestMethod -Uri "http://$($ip):8080" -Method Get

# Examine the running processes with top
docker top $containerId

# And - when done - kill it
docker kill $containerId
