throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Another useful, albeit more complex feature: Remote Desktop Services
# The following cmdlets should be run on PACKT-WB1

# First things first - the RemoteDesktop module cannot be used in PS Core
Import-WinModule RemoteDesktop, PKI

# Without enabling any role or feature yet, we have the module
Get-Command -Module RemoteDesktop

# Before we start with the deployment we should request a certificate
if (-not (Get-ChildItem Cert:\LocalMachine\my | Where-Object {$_.Subject -eq "CN=$env:COMPUTERNAME" -and $_.Issuer -like '*LabRootCA1*'}))
{
    $certParam = @{
        Url               = 'ldap:'
        SubjectName       = "CN=$env:COMPUTERNAME"
        Template          = 'ContosoWebServer'
        DnsName           = $env:COMPUTERNAME, ([System.Net.Dns]::GetHostByName($env:COMPUTERNAME)).HostName
        CertStoreLocation = 'Cert:\LocalMachine\my'
    }
    
    $null = Get-Certificate @certParam
}

# With Remote Desktop Services, we usually start with the session deployment.
# This cmdlet allows you to specify most components of your deployment, bar the licensing server and connection broker
# Important: Do not run this command on PACKT-WB1, as it will fail. Instead, use ANY other host
Invoke-Command -ComputerName PACKT-DC1 -ScriptBlock {
    New-RDSessionDeployment -ConnectionBroker PACKT-WB1.contoso.com -SessionHost PACKT-WB1.contoso.com -WebAccessServer PACKT-WB1.contoso.com -Verbose
}

# After PACKT-WB1 has restarted, we can continue. To complete our picture, we need
# the gateway with the correct external FQDN for our certificate
Add-RDServer -Server PACKT-WB1.contoso.com -Role RDS-GATEWAY -ConnectionBroker PACKT-WB1.contoso.com -GatewayExternalFqdn PACKT-WB1.contoso.com -Verbose

# as well as the licensing server
Add-RDServer -Server PACKT-WB1.contoso.com -Role RDS-LICENSING -ConnectionBroker PACKT-WB1.contoso.com -Verbose

# Now we should add our certificate to each role. To do this, we export it first.
# Remember to import the PKI module
Export-PfxCertificate -Cert (Get-ChildItem Cert:\LocalMachine\my | Where-Object {$_.Subject -eq "CN=$env:COMPUTERNAME" -and $_.Issuer -like '*LabRootCA1*'} | Select-Object -First 1) -Force -ChainOption BuildChain -FilePath C:\cert.pfx -ProtectTo contoso\install

# Now we can add the certificate by importing it again
Set-RDCertificate -ConnectionBroker PACKT-WB1.contoso.com -ImportPath C:\cert.pfx -Role RDGateway -Force
Set-RDCertificate -ConnectionBroker PACKT-WB1.contoso.com -ImportPath C:\cert.pfx -Role RDPublishing -Force
Set-RDCertificate -ConnectionBroker PACKT-WB1.contoso.com -ImportPath C:\cert.pfx -Role RDWebAccess -Force
Set-RDCertificate -ConnectionBroker PACKT-WB1.contoso.com -ImportPath C:\cert.pfx -Role RDRedirector -Force

# This is all great - but in order to connect and work, we should create a new session collection as well
New-RDSessionCollection -CollectionName PACKT -CollectionDescription "Get more great books at packt.com!" -SessionHost PACKT-WB1.contoso.com -COnnectionBroker PACKT-WB1.contoso.com -PersonalUnmanaged

# Install PowerShellGet in the recent version to prepare for next step
# The deployment of the new RDS Web Client
Install-Module -Name PowerShellGet -Force
exit # Restart PowerShell to reload the module

# The Remote Desktop Web Client provides a rich HTML5 experience for your users.
# We need to configure an SSL certificate and publish the client
Install-Module -Name RDWebClientManagement -Force -AcceptLicense
Install-RDWebClientPackage
Import-RDWebClientBrokerCert C:\cert.pfx
Publish-RDWebClientPackage -Type Production -Latest

# Now the URL is accessible!
start https://PACKT-WB1.contoso.com/RDWeb/WebClient
