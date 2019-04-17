throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# To work with Azure, you need to install the Azure PowerShell cmdlets
Install-Module -Name Az -Scope CurrentUser

# Starting with any cmdlet will result in an error
Get-AzVm

# To work with Azure, you need to log in once
Connect-AzAccount

# Which subscriptions can you use?
Get-AzSubscription

# If you have access to more than one subscription, you can set a default one
Set-AzContext -Subscription 'JHPaaS'

# Your subscription is now persistent by default. In a new session, try this
Get-AzComputeResourceSku | Select-Object -First 1