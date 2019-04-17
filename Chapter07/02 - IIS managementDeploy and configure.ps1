throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# All cmdlets are assumed to be executed on PACKT-WB1, e.g. in a session.

# Deploying IIS is easy enough
Import-WinModule ServerManager
Get-WindowsFeature -Name Web*

# While there are plenty of features to choose from, let's just install all of them
# Note: Depending on your requirements, you might select less features

# This installation requires features that are on the installation medium
# To continue, we need to mount the Windows Server iso file
# Execute the next command on the hypervisor
$isoLocation = throw "Fill this in before continuing!"
Add-VMDvdDrive -VMName PACKT-WB1 -Path $isoLocation

# Then we can install, using the side by side (sxs) folder
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools -Source D:\sources\sxs -Verbose

# If the installation was successful, you should be able to find the WebAdministration module
Get-Module -ListAvailable -Name WebAdministration -SkipEditionCheck
Get-Command -Module WebAdministration

Import-WinModule Pki, WebAdministration

# Request a certificate
if (-not (Get-ChildItem Cert:\LocalMachine\my | Where-Object {$_.Subject -eq "CN=$env:COMPUTERNAME" -and $_.Issuer -like '*LabRootCA1*'}))
{
    $certParam = @{
        Url               = 'ldap:'
        SubjectName       = "CN=$env:COMPUTERNAME"
        Template          = 'ContosoWebServer'
        DnsName           = $env:COMPUTERNAME, ([System.Net.Dns]::GetHostByName($env:COMPUTERNAME))
        CertStoreLocation = 'Cert:\LocalMachine\my'
    }
    
    $null = Get-Certificate @certParam
}

# Verify (with Windows PowerShell)
powershell.exe -Command "& {Get-ChildItem -Path Cert:\LocalMachine\My -SSLServerAuthentication}"

# Many web site require PHP or other CGI software. This is not a complex
# Be aware that the VC redist package is required: https://www.microsoft.com/en-us/download/details.aspx?id=48145
Invoke-WebRequest -Uri https://windows.php.net/downloads/releases/php-7.3.3-nts-Win32-VC15-x64.zip -OutFile php.zip
Expand-Archive -Path .\php.zip -DestinationPath C:\php

# We can already make some adjustments to the configuration
# ConvertFrom-StringData works with key=value entries - unfortunately it does not work yet
Get-Content c:\php\php.ini-production | ConvertFrom-StringData # Fails

# Filtering the content a little bit looks better already
Get-Content c:\php\php.ini-production | 
    Where {-not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith(';') -and -not $_.StartsWith('[')} |
    ConvertFrom-StringData

# Now that we can search better, we can start setting some settings
# please be aware of the backtick for formatting purposes - copy/paste might get broken
(Get-Content c:\php\php.ini-production) `
    -replace 'upload_max_filesize.*', 'upload_max_filesize = 1G' `
    -replace 'max_execution_time.*', 'max_execution_time = 300' | Set-Content C:\php\php.ini

# That is not enough to execute a script though. A handler mapping is necessary
New-WebHandler -Name PHPCGI -Path *.php -Verb * -Modules FastCgiModule -ScriptProcessor C:\php\php-cgi.exe -ResourceType File
Add-WebConfiguration -Filter 'system.webserver/fastcgi' -Value @{'fullPath' = 'C:\php\php-cgi.exe' }
Get-WebHandler -Location 'IIS:\Sites\Default Web Site' -Name PHPCGI | Set-WebHandler -RequiredAccess Execute

# Add e.g. index.php to the default site
Add-WebConfigurationProperty //defaultDocument/files "IIS:\sites\Default Web Site" -AtIndex 0 -Name collection -Value index.php

# Restart IIS and give it a go
iisreset

# Try it!
@'
<html>
 <head>
  <title>PHP Test</title>
 </head>
 <body>
 <?php echo '<p>Hello World</p>'; ?> 
 <?php phpinfo(); ?>
 </body>
</html>
'@ | Set-Content C:\inetpub\wwwroot\index.php

start http://localhost/index.php
