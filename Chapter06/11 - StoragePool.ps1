throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# There will always be one storage pool, called Primordial
Get-StoragePool

# To be able to create a storage pool, there need to be suitable empty disks
Get-StoragePool -IsPrimordial $true | Get-PhysicalDisk | Where-Object -Property CanPool

# Try adding the first half of the disks to one pool:
$disks = Get-StoragePool -IsPrimordial $true | Get-PhysicalDisk | Where-Object -Property CanPool | Select -First 5

# Now we can create a new virtual disk and ultimately a new volume
Get-StorageSubSystem
New-StoragePool -PhysicalDisks $disks -FriendlyName 'Splish splash' -StorageSubSystemFriendlyName 'Windows Storage*'
Get-StoragePool -FriendlyName 'Splish Splash' | 
    New-VirtualDisk -FriendlyName Accounting -UseMaximumSize

$volume = Get-VirtualDisk –FriendlyName Accounting | Get-Disk | Initialize-Disk –Passthru | New-Partition –AssignDriveLetter –UseMaximumSize | Format-Volume
$largefile = [System.IO.File]::Create("$($Volume.DriveLetter):\largefile")
$largefile.SetLength($volume.SizeRemaining - 1kB)
$largefile.Close()

# You notice that the available storage is getting less and less. To expand a storage pool you can simply add another set of poolable disks to it:
Get-StoragePool -FriendlyName 'Splish Splash' | 
    Add-PhysicalDisk -PhysicalDisks (Get-StoragePool -IsPrimordial $true | Get-PhysicalDisk | Where-Object -Property CanPool)

# Now that the pool has grown, the virtual disk and volume can grow as well:
Get-VirtualDisk -FriendlyName Accounting | Resize-VirtualDisk -Size 16GB
$volume | Get-Partition | Resize-Partition -Size 15GB
