throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Usually you would connect to Azure through AzCli or Az PowerShell
# In the background though, API calls are being made

# Take the following sample code from https://gallery.technet.microsoft.com/scriptcenter/Easily-obtain-AccessToken-3ba6e593
# to easily get a bearer token for requests without delving into OAuth2
function Get-AzCachedAccessToken()
{
    $ErrorActionPreference = 'Stop'
  
    if (-not (Get-Module Az.Accounts))
    {
        Import-Module Az.Accounts
    }
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    if (-not $azProfile.Accounts.Count)
    {
        Write-Error "Ensure you have logged in before calling this function."    
    }
  
    $currentAzureContext = Get-AzContext
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    Write-Debug ("Getting access token for tenant" + $currentAzureContext.Tenant.TenantId)
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
    $token.AccessToken
}

function Get-AzBearerToken()
{
    $ErrorActionPreference = 'Stop'
    ('Bearer {0}' -f (Get-AzCachedAccessToken))
}

# To list all resource groups, use the Get method for your subscription
$subscriptionId = (Get-AzContext).Subscription.Id
$baseUrl = "https://management.azure.com/subscriptions"
$headers = @{
    Authorization = Get-AzBearerToken
}

(Invoke-RestMethod -Method Get -Uri "$baseurl/$subscriptionId/resourcegroups?api-version=2018-05-01" -Headers $headers).value

# Now you can create a new one with the PUT method
$rgJson = @{
    location = 'westeurope'
    tags     = @{
        PowerShell = 'IsAwesome'
    }
} | ConvertTo-Json

$resourceGroupName = 'PowerShellCookBook'

Invoke-RestMethod -Method Put -Uri "$baseurl/$subscriptionId/resourcegroups/$($resourceGroupName)?api-version=2018-05-01" -Headers $headers -Body $rgJson -ContentType application/json

# Test your new Resource Group
Invoke-RestMethod -Method Get -Uri "$baseurl/$subscriptionId/resourcegroups/$($resourceGroupName)?api-version=2018-05-01" -Headers $headers

# And delete it
Invoke-RestMethod -Method Delete -Uri "$baseurl/$subscriptionId/resourcegroups/$($resourceGroupName)?api-version=2018-05-01" -Headers $headers