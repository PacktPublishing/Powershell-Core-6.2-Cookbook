throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Resource groups are containers for multiple different resources
Get-AzResourceGroup

# You can create them easily in PowerShell to collect different resources
New-AzResourceGroup -Name JHP_Networking -Location 'West Europe'

# Additionally, you can assign tags, for example for billing purposes
New-AzResourceGroup -Name JHP_VMDisks -Location 'West Europe' -Tag @{CostCenter = 48652; PrimaryOwner = 'JHP'}

# You can modify your resource group later on
Set-AzResourceGroup -Name JHP_Networking -Tag @{CostCenter = 4711; PrimaryOwner = 'SomeoneElse'}

# To add new or overwrite existing tags, you can do the following
$tags = (Get-AzResourceGroup -Name JHP_VMDisks).Tags
$tags.PrimaryOwner = 'Mr. Big Boss'
$tags.Purpose = 'Storage accounts'
Set-AzResourceGroup -Name JHP_VMDisks -Tag $tags

# To export a template you can use for a resource group deployment, use:
Export-AzResourceGroup -ResourceGroupName JHP_VMDisks -Path .

# And of course to remove one
Remove-AzResourceGroup -ResourceGroupName JHP_VMDisks -Force