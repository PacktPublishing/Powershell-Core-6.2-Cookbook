throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Linux can create software RAID devices with mdadm.
# First of all, let's see if there is an existing configuration
mdadm --detail --scan

# Alternatively, you can have a look at /proc/mdstat
# We are looking for lines like e.g. md0 : active raid10
# We will revisit that pattern in a moment
(Get-Content -Raw -Path /proc/mdstat) -match '(?<RaidDevice>[\w\d]+)\s+:\s+active\s+raid(?<RaidType>[\d])\s+'

# Listing all available disks
lsblk -ibo KNAME,TYPE,SIZE,MODEL

# We can improve the output with a custom class
class BlockDevice
{
    [string] $Name
    [string] $Type
    [int64]  $Size
}

function Get-Disk
{
    lsblk -ibo KNAME,TYPE,SIZE,MODEL | Select-Object -Skip 1 | ForEach-Object {
        if ($_ -match '(?<Name>\w+)\s+(?<Type>\w+)\s+(?<Size>[\w\d.]+)\s')
        {
            $tmp = $Matches.Clone()
            $tmp.Remove(0)
            [BlockDevice]$tmp
        }
    }
}

# Assuming that you have two spare volumes, let's create a new RAID!
Get-Disk | Where-object -Property Type -ne 'part'

# Again, there is no cmdlet to do the task. We will start with a simple stripe set (RAID0)
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/sdc /dev/sdd
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/sdc /dev/sdd

# but it would not be PowerShell if we couldn't make our life easier.
enum RaidLevel
{
    RAID0 = 0
    RAID1 = 1
    RAID4 = 4
    RAID5 = 5
    RAID6 = 6
    RAID10 = 10
}

class RaidDevice
{
    [string] $DeviceName
    [string[]] $MemberDevice
    [RaidLevel] $Level
}

function Get-SoftwareRaid
{
    [CmdletBinding()]
    param
    (
        $DeviceName
    )

    $devices = foreach ($line in (Get-Content -Path /proc/mdstat))
    {
        if ($line -match '(?<DeviceName>[\w\d]+)\s+:\s+active\s+raid(?<Level>[\d])\s+')
        {
            $tmp = $Matches.Clone()
            $tmp.Remove(0)
            $device = [RaidDevice]$tmp

            $deviceString = $line -replace ".*raid\d{1,2}\s+"
            $device.MemberDevice += $deviceString -split "\s" -replace "\[\d+\]"
            $device
        }
    }

    if ($DeviceName)
    {
        $devices = $devices | Where-Object -Property DeviceName -eq $DeviceName
    }

    $devices
}

function New-SoftwareRaid
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [RaidLevel]
        $Level,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $DeviceName,

        [Parameter(ValueFromPipeline)]
        [System.IO.FileInfo[]]
        $MemberDevice
    )

    begin
    {
        if (Get-SoftwareRaid -DeviceName $DeviceName.BaseName)
        {
            Write-Warning -Message "$DeviceName already exists. Skipping."
            return
        }

        $arguments = @(        
            '--create'
            if ($PSBoundParameters.ContainsKey('Verbose')) { '--verbose'}
            $DeviceName.FullName
            "--level=$([int]$Level)"
        )

        $deviceCount = 0
        $devices = @()
    }

    process
    {
        if (($MemberDevice | Test-Path) -contains $false)
        {
            Write-Error -Message "One or more member devices not found."
            return
        }

        $devices += $MemberDevice.FullName
        $deviceCount += $MemberDevice.Count
    }    
    
    end
    {        
        $arguments += "--raid-devices=$deviceCount"
        $arguments += $devices -join ' '
        Write-Verbose -Message "Starting mdadm $($arguments)"
        Start-Process -FilePath (Get-Command mdadm).Path -ArgumentList $arguments -Wait -NoNewWindow
    }
}

# This now makes this beautiful expression possible:
Get-ChildItem -Path /dev/sd[cd] | New-SoftwareRaid -DeviceName md0 -Level Raid0 -Verbose

# You can figure out the other functions on your own. mdadm has different parameters
# To get you started, try the following to remove your RAID and reset the member disks
function Remove-SoftwareRaid
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.IO.FileInfo]
        $DeviceName
    )

    begin
    {
        $memberDisks = @()
    }

    process
    {
        if (-not (Get-SoftwareRaid -DeviceName $DeviceName.BaseName))
        {
            Write-Verbose -Message "No RAID found."
            return
        }

        $raid = Get-SoftwareRaid -DeviceName $DeviceName.BaseName

        if ($PSCmdlet.ShouldProcess($DeviceName.FullName, "Stopping RAID and removing member device superblock"))
        {
            umount $DeviceName.FullName
            mdadm --stop $DeviceName.FullName

            foreach ($memberDisk in $raid.MemberDevice)
            {
                mdadm --zero-superblock /dev/$memberDisk
            }
        }
    }
}

Get-Item -Path /dev/md0 | Remove-SoftwareRaid -WhatIf
Get-Item -Path /dev/md0 | Remove-SoftwareRaid -Confirm:$false
