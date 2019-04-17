throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# First of all, log in to your Stack
Add-AzureRMEnvironment -Name "Hochstapler" -ArmEndpoint "https://management.local.azurestack.external"

# Set your tenant name
$AuthEndpoint = (Get-AzureRmEnvironment -Name "Hochstapler").ActiveDirectoryAuthority.TrimEnd('/')
$AADTenantName = "M365x027443.onmicrosoft.com"
$TenantId = (Invoke-RestMethod "$($AuthEndpoint)/$($AADTenantName)/.well-known/openid-configuration").issuer.TrimEnd('/').Split('/')[-1]

# After signing in to your environment the Azure cmdlets can target Azure Stack
Add-AzureRmAccount -EnvironmentName "Hochstapler" -TenantId $TenantId

# You can use all available AzureRM cmdlets with Azure Stack
Get-Command -Noun AzureRmVirtualNetwork*

# Resource group first
$rg = New-AzureRmResourceGroup -Name DEWESTNetworking -Location local

# create your desired subnets
$sn1 = New-AzureRmVirtualNetworkSubnetConfig -Name management -AddressPrefix 10.0.0.0/24
$sn2 = New-AzureRmVirtualNetworkSubnetConfig -Name frontend -AddressPrefix 10.0.1.0/24
$sn3 = New-AzureRmVirtualNetworkSubnetConfig -Name management -AddressPrefix 10.1.0.0/24
$sn4 = New-AzureRmVirtualNetworkSubnetConfig -Name frontend -AddressPrefix 10.1.1.0/24

# and VNets
$param = @{
    Name              = 'DEDUEVN01'
    Subnet            = $sn1, $sn2
    ResourceGroupName = 'DEWESTNetworking'
    AddressPrefix     = '10.0.0.0/23'
    Location          = 'local'
}
$param2 = $param.Clone()
$param2.Subet = $sn3, $sn4
$param2.AddressPrefix = '10.1.0.0/23'
$param2.Name = 'DEFRAVN01'
$vNet = New-AzureRmVirtualNetwork @param
$vNet2 = New-AzureRmVirtualNetwork @param2

# Unfortunately, peering is not yet available: https://docs.microsoft.com/en-us/azure/azure-stack/user/azure-stack-network-differences
$vnet = Get-AzureRmVirtualNetwork -Name deduevn01 -ResourceGroupName dewestnetworking
$remoteVNet = Get-AzureRmVirtualNetwork -Name defravn01 -ResourceGroupName dewestnetworking
Add-AzureRmVirtualNetworkPeering -Name DEWESTPeer01 -VirtualNetwork $vnet -RemoteVirtualNetworkId $remoteVNet.Id

# Instead, you could configure a local and a vnet gateway

# Modify a subnet
$vnet = Get-AzureRmVirtualNetwork -Name deduevn01 -ResourceGroupName dewestnetworking
$null = Set-AzureRmVirtualNetworkSubnetConfig -Name management -VirtualNetwork $vnet -AddressPrefix 10.0.0.0/25
$null = Set-AzureRmVirtualNetworkSubnetConfig -Name frontend -VirtualNetwork $vnet -AddressPrefix 10.0.1.0/25

# The *COnfig cmdlets only change the reference ($vnet). Write the config back with the Set cmdlet
$vnet | Set-AzureRmVirtualNetwork

# Removing a network is simple as well
$vnet | Remove-AzureRmVirtualNetwork