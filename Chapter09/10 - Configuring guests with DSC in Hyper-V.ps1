throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Configuring Hyper-V guests with DSC is also often a good idea

# Since CIM is not suitable for PowerShell Direct, we have to think
# outside the box.
configuration BaseLine
{
    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 6.2.0.0
    Import-DscResource -moduleName PSDesiredStateConfiguration

    node $AllNodes.NodeName
    {
        Computer computer
        {
            Name       = $Node.NodeName
            DomainName = $ConfigurationData.Domain.DomainName
            Credential = $ConfigurationData.Domain.DomainJoinCredential
        }

        WindowsFeature SMB1Disable
        {
            Ensure = 'Absent'
            Name   = 'FS-SMB1'
        }

        TimeZone tzSettings
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $Node.TimeZone
        }

        VirtualMemory pageFile
        {
            Drive       = 'C'
            Type        = 'CustomSize'
            InitialSize = 5GB
            MaximumSize = 5GB
        }
    }
}

$confData = @{
    # Reserved Key first
    AllNodes = @(
        @{
            NodeName                    = '*'
            PSDSCAllowPlaintextPassword = $true
            PSDSCAllowDomainUser        = $true
        }
        @{
            NodeName = 'NEWVM01'
            TimeZone = 'Samoa Standard Time'
        }
        @{
            NodeName = 'NEWVM02'
            TimeZone = 'Hawaiian Standard Time'
        }
    )

    Domain   = @{
        DomainName           = 'contoso.com'
        DomainJoinCredential = [pscredential]::new('contoso\Install', ('Somepass1' | ConvertTo-SecureString -AsPlaintext -force))
    }
}

# Build the MOF
BaseLine -ConfigurationData $confData

# Now things are a tiny bit different
$sessions = New-PSSession -VMName NEWVM01,NEWVM02 -Credential Install

# Copy module and mof
foreach ($session in $sessions)
{
    $mod = [System.IO.DirectoryInfo]$(Get-Module ComputerManagementDsc -ListAvailable)[0].ModuleBase
    Copy-Item -ToSession $session -Path ".\BaseLine\$($session.ComputerName).mof" -Destination "C:\Windows\System32\configuration\pending.mof"
    Copy-Item -ToSession $session -Path $mod.Parent.FullName -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse
}

# Lastly: Wait!
Invoke-Command -Session $session -ScriptBlock {
    Test-DscConfiguration -Verbose -Detailed -ErrorAction SilentlyContinue
}
