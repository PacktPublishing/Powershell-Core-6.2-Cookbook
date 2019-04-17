throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# The Hyper-V cmdlets are part of the Hyper-V role
# but can be installed separately
Import-WinModule Dism
Import-WinModule ServerManager

# To deploy Hyper-V, either enable the server feature or the client optional feature
if ($PSVersionTable.OS -like '*Windows 10*')
{
    Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
}
else
{
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -IncludeAllSubFeature
}

# After the host reboots, Hyper-V is enabled

# Discover the Hyper-V Cmdlets
Get-Command -Module Hyper-V

# To "properly" set up, have a look at the VM Host
Get-VMHost

# We would like to modify a few settings
$parameters = @{
    EnableEnhancedSessionMode = $true
    NumaSpanningEnabled       = $true
    VirtualHardDiskPath       = 'D:\Other-VMs'
    VirtualMachinePath        = 'D:\Other-VMs'
    
}

Set-VMHost @parameters

# That's it - there is not more to set up ;)
