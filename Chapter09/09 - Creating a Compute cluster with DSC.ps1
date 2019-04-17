throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# a more advanced exercise might be to configure your Compute resources via DSC
# Note that this execise is not usable with PS Core.

# Starting with the data we will put in
$confData = @{
    # Reserved Key first
    AllNodes = @(
        @{
            NodeName                    = '*'
            PSDSCAllowPlaintextPassword = $true
            PSDSCAllowDomainUser        = $true
        }
        @{
            NodeName = 'PACKT-HV1'
            Cluster  = 'CLU001'
        }
        @{
            NodeName = 'PACKT-HV2'
            Cluster  = 'CLU001'
        }
    )

    Domain   = @{
        DomainName           = 'contoso.com'
        DomainJoinCredential = [pscredential]::new('contoso\Install', ('Somepass1' | ConvertTo-SecureString -AsPlaintext -force))
    }
}

configuration TheCluster
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xFailOverCluster -ModuleVersion 1.12.0.0
    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 6.2.0.0
    Import-DscResource -ModuleName xHyper-V -ModuleVersion 3.16.0.0
    IMport-DscResource -ModuleName StorageDsc -ModuleVersion 4.5.0.0

    node $ConfigurationData.AllNodes.Where( { $_.Cluster -eq 'CLU001' }).NodeName
    {
        # Domain join first
        Computer computer
        {
            Name       = $Node.NodeName
            DomainName = $ConfigurationData.Domain.DomainName
            Credential = $ConfigurationData.Domain.DomainJoinCredential
        }

        # Features
        $itDepends = @()
        foreach ($feature in @("Hyper-V", 'Failover-Clustering', 'Multipath-IO', 'RSAT-Shielded-VM-Tools', 'RSAT-Clustering-Powershell', 'Hyper-V-PowerShell'))
        {
            $itDepends += "[WindowsFeature]$feature"
            WindowsFeature $feature
            {
                Name                 = $feature
                IncludeAllSubFeature = $true
            }
        }

        Disk DDrive
        {
            DiskId           = 1
            DriveLetter      = 'D'
            DiskIdType       = 'Number'
            PartitionStyle   = 'GPT'
            FSFormat         = 'ReFS'
            AllowDestructive = $true
        }

        File Disks
        {
            DependsOn       = '[Disk]DDrive'
            DestinationPath = 'D:\Disks'
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        File VMs
        {
            DependsOn       = '[Disk]DDrive'
            DestinationPath = 'D:\VMs'
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        xVMHost hv
        {
            DependsOn                 = $itDepends, '[File]Disks', '[File]VMs'
            IsSingleInstance          = 'Yes'
            EnableEnhancedSessionMode = $true
            VirtualHardDiskPath       = 'D:\Disks'
            VirtualMachinePath        = 'D:\VMs'
        }

        xCluster $Node.Cluster
        {
            Name                          = $Node.Cluster
            DomainAdministratorCredential = $ConfigurationData.Domain.DomainJoinCredential
            DependsOn                     = $itDepends, '[Computer]computer'
            StaticIPAddress               = '192.168.56.199'
        }
    }
}

# Compile the mof
TheCluster -ConfigurationData $confData

# Now for the LCM
[DscLocalConfigurationManager()]
configuration LcmSettings
{
    node @('PACKT-HV1', 'PACKT-HV2')
    {
        Settings
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode  = 'ApplyAndAutoCorrect'
        }
    }
}

LcmSettings

# Create sessions
$sessions = New-CimSession -ComputerName PACKT-HV1, PACKT-HV2 -Credential $confData.Domain.DomainJoinCredential

# Configure LCM
Set-DscLocalConfigurationManager -CimSession $sessions -Path .\LcmSettings -Verbose

# PUSH IT REAL GOOD!
Start-DscConfiguration -Force -Verbose -CimSession $sessions -Wait -Path .\TheCluster

# Both systems will restart twice. Give it some time.