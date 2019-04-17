#requires -RunAsAdministrator

if (-not (Get-Module AutomatedLab -List))
{
    $null = Install-PackageProvider -Name nuget -Force
    Install-Module powershell-yaml,newtonsoft.json,automatedlab,automatedlab.ships -Force
    [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTOUT', 'yes') # opt in to telemetry if you like, it helps us! To opt in, change yes to no here
    Enable-LabHostRemoting -Force
    $null = New-LabSourcesFolder -Drive C -Force
}

$null = Read-Host -Prompt "Please store your ISO files (Server 2016, SQL Server 2017) in $(Get-LabSourcesLocationInternal -Local) and press any key to continue"

$labName = 'PSCookBook'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.56.0/24
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

$sqlIso = Get-ChildItem -Path "$(Get-LabSourcesLocationInternal -Local)\isos" -File -Filter *SQL*2017* | Select -First 1
if (-not $sqlIso)
{
    Write-Warning -Message "Your lab will not contain a SQL Server since no SQL 2017 ISO was found."
}

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network'         = $labName
    'Add-LabMachineDefinition:DnsServer1'      = '192.168.56.9'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'          = 1gb
}

Add-LabDiskDefinition -Name PACKT-FS-A-D -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-B-D -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-C-D -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-A-E -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-B-E -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-C-E -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-A-F -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-B-F -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-C-F -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-HV1-D -DiskSizeInGb 50
Add-LabDiskDefinition -Name PACKT-HV2-D -DiskSizeInGb 50

#Domain Controller
$roles = @(
    Get-LabMachineRoleDefinition -Role RootDC
    Get-LabMachineRoleDefinition -Role CaRoot @{ InstallWebEnrollment = 'Yes'; InstallWebRole = 'Yes'}
    Get-LabMachineRoleDefinition -Role Routing
)
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.56.9
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name PACKT-DC1 -Roles $roles -NetworkAdapter $netAdapter -PostInstallationActivity $postInstallActivity -DomainName contoso.com -Memory 4gb
Add-LabMachineDefinition -Name PACKT-DC2 -IpAddress 192.168.56.77

#File servers, S2D
Add-LabMachineDefinition -Name PACKT-FS-A -Roles FileServer -IpAddress 192.168.56.11 -DiskName PACKT-FS-A-D, PACKT-FS-A-E, PACKT-FS-A-F -DomainName contoso.com
Add-LabMachineDefinition -Name PACKT-FS-B -Roles FileServer -IpAddress 192.168.56.18 -DiskName PACKT-FS-B-D, PACKT-FS-B-E, PACKT-FS-B-F -DomainName contoso.com
Add-LabMachineDefinition -Name PACKT-FS-C -Roles FileServer -IpAddress 192.168.56.25 -DiskName PACKT-FS-C-D, PACKT-FS-C-E, PACKT-FS-C-F -DomainName contoso.com

# Later to be joined
Add-LabMachineDefinition -Name NEWVM01 -IpAddress 192.168.56.101
Add-LabMachineDefinition -Name NEWVM02 -IpAddress 192.168.56.102

# Web Server to be, RDS Host
if ($sqlIso)
{
    $null = Add-LabIsoImageDefinition -Name SQLServer2017 -Path $sqlIso.FullName -NoDisplay
    $role = Get-LabMachineRoleDefinition -Role SQLServer2017 @{InstallSampleDatabase = 'true' }
    Add-LabMachineDefinition -Name PACKT-WB1 -DomainName contoso.com -Roles $role -Memory 4GB
}
else
{
    Add-LabMachineDefinition -Name PACKT-WB1 -DomainName contoso.com
}

# Hypervisor
Add-LabMachineDefinition -Name PACKT-HV1 -DiskName PACKT-HV1-D -DomainName contoso.com
Add-LabMachineDefinition -Name PACKT-HV2 -DiskName PACKT-HV2-D -DomainName contoso.com

# Maybe a Linux VM
Add-LabMachineDefinition -Name PACKT-CN1 -Memory 2GB -DomainName contoso.com -OperatingSystem 'Centos 7.4'

Install-Lab

Invoke-LabCommand -ComputerName PACKT-DC1 -ScriptBlock {
    New-ADUser -SamAccountName elbarto -Name Bart -Surname Simpson -AccountPassword ('c0waBung4!' | ConvertTo-SecureString -AsPlaintext -Force) -Enabled $true
    Add-ADGroupMember -Identity 'Domain Admins' -Members elbarto
    New-ADOrganizationalUnit -Name RebootOU
    Get-ADComputer -Filter 'Name -like "*FS*"' | Move-ADObject -TargetPath 'OU=RebootOU,DC=contoso,DC=com'
}

Enable-LabCertificateAutoEnrollment -Computer

New-LabCATemplate -TemplateName ContosoWebServer -DisplayName 'Web Server cert' -SourceTemplateName WebServer -ApplicationPolicy 'Server Authentication' -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName (Get-LabIssuingCa) -ErrorAction Stop

Stop-LabVm -ComputerName PACKT-HV1,PACKT-HV2 -Wait
Get-Vm -VMName PACKT-HV1,PACKT-HV2 | Set-VMProcessor -ExposeVirtualizationExtensions $true
Start-LabVm -ComputerName PACKT-HV1,PACKT-HV2 -Wait

$pscore = Get-LabInternetFile -Uri https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/PowerShell-6.2.0-win-x64.msi -PassThru -path $labsources\Tools -FileName pscore.msi -Force

Install-LabSoftwarePackage -Path $pscore.FullName -ComputerName (Get-LabVm)
Save-Module -Name WindowsCompatibility -Path $labsources\Tools
Copy-LabFileItem -Path $labsources\Tools\WindowsCompatibility -Destination 'C:\Program Files\PowerShell\6\Modules' -ComputerName (Get-LabVm)
Copy-LabFileItem -Path (Get-LabVm PACKT-HV1).OperatingSystem.BaseDiskPath -Destination D: -ComputerName PACKT-HV1,PACKT-HV2
Save-Module -Path $labsources\Tools -Name ComputerManagementDsc,NetworkingDsc,StorageDsc,xFailoverCluster,xHyper-V
Copy-LabFileItem -Path $labsources\Tools\ComputerManagementDsc,$labsources\Tools\NetworkingDsc,$labsources\Tools\StorageDsc,$labsources\Tools\xFailoverCluster,$labsources\Tools\xHyper-V -ComputerName packt-hv1,PACKT-HV2 -Destination 'C:\Program Files\PowerShell\6\Modules'
Copy-LabFileItem -Path $labsources\Tools\ComputerManagementDsc,$labsources\Tools\NetworkingDsc,$labsources\Tools\StorageDsc,$labsources\Tools\xFailoverCluster,$labsources\Tools\xHyper-V -ComputerName packt-hv1,PACKT-HV2 -Destination 'C:\Program Files\WindowsPowerShell\Modules'
Restart-LabVm -ComputerName packt-hv1,PACKT-HV2


Show-LabDeploymentSummary -Detailed
