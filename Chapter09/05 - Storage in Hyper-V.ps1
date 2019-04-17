throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Like networking, providing storage to a VM is not that hard
Get-Command -Noun VHD*

# Your storage is likely carved from a SAN, but can also come from S2D. Regardless:

# A dynamic disks will expand automatically, albeit with a slight performance penalty
New-VHD -Path D:\Other-VMs\Disks\VM1_DataDisk1.vhdx -Dynamic -SizeBytes 5GB
New-VHD -Path D:\Other-VMs\Disks\VM1_DataDisk2.vhdx -Dynamic -SizeBytes 5GB
New-VHD -Path D:\Other-VMs\Disks\VM1_DataDisk3.vhdx -Dynamic -SizeBytes 5GB

# Creating a fixed disk is just another parameter
New-VHD -Path D:\Other-VMs\Disks\VM1_DataDisk3.vhdx -Fixed -SizeBytes 5GB

# Often, you want to bill internal customers properly. So let's prepare metering
# do not confuse resource pools with the ones that VMWare uses.
New-VMResourcePool -Name InternalCustomer01_storage -ResourcePoolType storage -Paths D:\Other-VMs\Disks

# You can attach storage to a VM
foreach ($disk in (Get-ChildItem D:\Other-VMs\Disks\*.vhdx))
{
    Add-VMHardDiskDrive -VMName PACKT-WB1 -Path $disk.FullName -ResourcePoolName InternalCustomer01_storage
}

# Enable metering for your VM
Enable-VMResourceMetering -VMName PACKT-WB1

# A differencing disk is often a good choice
$param = @{
    Path         = 'D:\Other-VMs\OSDisks\VM1_OS.vhdx'
    ParentPath   = 'D:\AutomatedLab-VMs\BASE_WindowsServer2016Datacenter_10.0.14393.0.vhdx'
    Differencing = $true
}
New-VHD @param

# The new VHD sets introduced in Server 2016 are excellent for shared cluster storage or witness disks
# Just use a different extension
New-VHD -Path D:\Other-VMs\Disks\ClusterWitness.vhds -SizeBytes 1GB -Dynamic

# Attaching it is slightly different
$param = @{
    VMName             = 'PACKT-FS-A', 'PACKT-FS-B', 'PACKT-FS-C'
    Path               = 'D:\Other-VMs\Disks\ClusterWitness.vhds'
    ShareVirtualDisk   = $true
    ControllerNumber   = 0
    ControllerLocation = 4
}
Add-VMHardDiskDrive @param

# The great thing is that these volumes can simply be extended. Gone are the
# days that your cluster had to be powered down (talk about HA...) to do this.
Resize-VHD -Path D:\Other-VMs\Disks\ClusterWitness.vhds -SizeBytes 5Gb
