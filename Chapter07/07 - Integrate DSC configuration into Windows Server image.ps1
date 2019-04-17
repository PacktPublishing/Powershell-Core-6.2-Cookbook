throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Windows PowerShell Desired State Configuration is a great way to configure your servers.
# Apart from configuring everything after the deployment, you can also integrate it directly
# into your build

# First of all, we will create our configurations, starting with the Local Configuration Manager
[DscLocalConfigurationManager()]
configuration LcmSettings
{
    Settings
    {
        RebootNodeIfNeeded        = $true
        ConfigurationMode         = 'ApplyAndAutoCorrect'
        StatusRetentionTimeInDays = 5
    }
}

$configurationPath = Join-Path -Path $env:TEMP -ChildPath 'PacktDscConfigs'
$metaConfig = LcmSettings -OutputPath $configurationPath

# In addition to the meta config we would like some system configuration as well
configuration InitialSystemConfig
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName NetworkingDsc

    node $AllNodes.NodeName
    {
        IPAddress nodeIp
        {
            InterfaceAlias = 'Ethernet'
            IPAddress = '192.168.56.77'
            AddressFamily = 'IPv4'
        }

        DnsServerAddress dns1
        {
            Address = '192.168.56.9'
            AddressFamily = 'IPv4'
            InterfaceAlias = 'Ethernet'
            DependsOn = '[IPAddress]nodeIp'
        }

        Computer $Node.NodeName
        {
            DomainName  = $Node.DomainName
            Name        = $Node.NodeName
            Credential  = $Node.DomainJoinCredential
            Description = 'Automation is THE BEST ♥'
            DependsOn = '[DnsServerAddress]dns1'
        }
    }
}

# To be able to use plaintext credentials without a valid certificate, we can use configuration data
$configData = @{
    AllNodes = @(
        @{
            NodeName = '*'
            PSDSCAllowPlaintextPassword = $true
            PSDSCAllowDomainUser = $true
        }
        @{
            NodeName = 'PACKT-SV1'
            DomainName = 'contoso.com'
            DomainJoinCredential = [pscredential]::new('contoso\Install', $('Somepass1' | ConvertTo-SecureString -AsPlaintext -Force))
        }
    )
}

# Compile the config
$dscConfig = InitialSystemConfig -ConfigurationData $configData -OutputPath $configurationPath

<#
DSC uses the path /Windows/System32/configuration to store the configurations.
To bootstrap both LCM settings as well as the configuration, we need two files:
- pending.mof: The configuration to be applied
- MetaConfig.mof: The LCM configuration to be applied
#>

# We start with our Windows Server VHD file (on PACKT-HV1)
Import-Module Storage -SkipEditionCheck
$disk = Mount-DiskImage -ImagePath 'D:\BASE_WindowsServer2016Datacenter_10.0.14393.0.vhdx' -Access ReadWrite -StorageType VHDX -PassThru | Get-DiskImage

# Copy the meta config
Copy-Item $metaConfig.FullName -Destination E:\Windows\System32\configuration\metaconfig.mof

# Copy the pending config
Copy-Item $dscConfig.FullName -Destination E:\Windows\System32\configuration\pending.mof

# And the modules
Copy-Item "C:\Program Files\WindowsPowerShell\Modules\ComputerManagementDsc","C:\Program Files\WindowsPowerShell\Modules\NetworkingDsc" -Destination "E:\Program Files\WindowsPowerShell\Modules" -Recurse

# Unmount the image
$disk | Dismount-DiskImage

# Create a new VM from it
$null = New-VmSwitch -Name DomainEnv -SwitchType External
$vm = New-Vm -Name DscConfiguredThisVm -MemoryStartupBytes 2GB -VHDPath 'D:\BASE_WindowsServer2016Datacenter_10.0.14393.0.vhdx' -SwitchName DomainEnv -Generation 2

# And start it
$vm | Start-Vm