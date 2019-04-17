throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Deploying new VM workloads works more or less like on Azure, with a few differences
# Create a resource group
New-AzureRmResourceGroup -Name VM -Location local

# In the resource group, you can either quick-create a VM
$adminCredential = [pscredential]::new('VmAdmin', ('M3g4Secure!' | ConvertTo-SecureString -AsPlainText -Force))
New-AzureRmVM -ResourceGroupName VM -Location local -Name myVM01 -ImageName Win2016Datacenter -Credential $adminCredential

# To quickly connect to a standard VM, you can download the RDP file
Get-AzureRmVm -Name myVM01 -ResourceGroupName VM | Get-AzureRmRemoteDesktopFile -LocalPath .\myvm.rdp -Launch

# Connecting via WinRm is of course also possible
# The VM Security Group enabled both port 3389 as well as 5985
$ip = Get-AzureRmVm -Name myvm01 -ResourceGroupName vm | Get-AzureRmPublicIpAddress
Enter-PSSession -ComputerName 192.168.102.32 -Credential $adminCredential

# Or exercise slighty more control with a VM config
# prepare your input
$resourceGroupName = 'VM'
$storageAccountName = "contoso$((1..8 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
$location = 'local'
$vmName = 'MyFirstVm'
$roleSize = 'Standard_DS2'
$cred = Get-Credential

# Create a storage account to store your unmanaged disks
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -SkuName Standard_LRS -Location $location
$storageContext = (Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName).Context

# Create the firewall aka Network Security Group
$paramRule1 = @{
    Name                     = 'rdp-in'
    Description              = 'Allow Remote Desktop'
    Access                   = 'Allow'
    Protocol                 = 'Tcp'
    Direction                = 'Inbound'
    Priority                 = 100
    SourceAddressPrefix      = 'Internet'
    SourcePortRange          = '*'
    DestinationAddressPrefix = '*'
    DestinationPortRange     = 3389
}
$rule1 = New-AzureRmNetworkSecurityRuleConfig @paramRule1

$paramRule2 = $paramRule1.Clone()
$paramRule2.Name = 'WinRM TCP in'
$paramRule2.Description = 'Allow WinRM'
$paramRule2.Priority = 101
$paramRule2.DestinationPortRange = 5985
$rule2 = New-AzureRmNetworkSecurityRuleConfig @paramRule2

$nsgParam = @{
    ResourceGroupName = $resourceGroupName
    Location          = $location
    Name              = "NSG-FrontEnd"
    SecurityRules     = $rule1, $rule2
}
$nsg = New-AzureRmNetworkSecurityGroup @nsgParam

# Create a proper virtual network or reuse an existing one
New-AzureRmVirtualNetwork -Name $resourceGroupName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0 / 16"    
Get-AzureRmVirtualNetwork -Name $resourceGroupName -ResourceGroupName $resourceGroupName |
Add-AzureRmVirtualNetworkSubnetConfig -Name someSubnet -AddressPrefix '10.0.0.0/24' -NetworkSecurityGroup $nsg |
Set-AzureRmVirtualNetwork

$subnet = Get-AzureRmVirtualNetwork -Name $resourceGroupName -ResourceGroupName $resourceGroupName | Get-AzureRmVirtualNetworkSubnetConfig

# The VM can be configured individually as well
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $RoleSize
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -WinRMHttp
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName 'MicrosoftWindowsServer' -Offer WindowsServer -Skus 2016-Datacenter -Version "latest"

# Add a NIC to the VM
$networkInterface = New-AzureRmNetworkInterface -Name VmNic -ResourceGroupName $resourceGroupName -Location $location -Subnet $subnet
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $networkInterface.Id -ErrorAction Stop -WarningAction SilentlyContinue

# Add an OS disk - this is not a managed disk
$DiskName = "$($vmName)_os"
$OSDiskUri = "$($StorageContext.BlobEndpoint)disks/$DiskName.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $DiskName -VhdUri $OSDiskUri -CreateOption fromImage -ErrorAction Stop -WarningAction SilentlyContinue
    
# All that fluff, just to use the New-AzureRmVm cmdlet
$vmParameters = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $Location
    VM                = $vm
    ErrorAction       = 'Stop'
    WarningAction     = 'SilentlyContinue'
}
New-AzureRmVM @vmParameters
