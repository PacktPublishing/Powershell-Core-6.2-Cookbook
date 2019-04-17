throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Runbooks are great to execute PowerShell code in your automation account
# Runbooks can be called with Web Hooks and even accept parameters

# To get started, create a new automation account
New-AzResourceGroup -Name PowerShellCookBook -Location westeurope
New-AzAutomationAccount -ResourceGroupName PowerShellCookBook -Name psautomate -Location westeurope -Plan Basic

# Create your runbook code, e.g.
$code = {
    param
    (
        [object]
        $WebHookData # This parameter will later be used...
    )

    # Verbose output can be grabbed individually
    Write-Verbose $($WebhookData.RequestBody | ConvertFrom-Json | Out-String)

    # You can return data from within the runbook as well
    # CAUTION: At the time of writing, the output had to be converted to JSON! By the time this book
    # is published, this issue is hopefully closed.
    Get-Process -Id $pid
}

$code.ToSTring() | Set-Content .\runbook.ps1

# Lastly, import the runbook
Import-AzAutomationRunbook -Path .\runbook.ps1 -Description 'Outputs request body' -Name RunLolaRun -AutomationAccountName psautomate -ResourceGroupName PowerShellCookBook -Type PowerShell

# It still needs to be published, otherwise it will not be available in its current state
Publish-AzAutomationRunbook -Name RunLolaRun -AutomationAccountName psautomate -ResourceGroupName PowerShellCookBook

# Now for the good part, the web hook
$parameters = @{
    Name                  = 'thehook'
    RunbookName           = 'RunLolaRun'
    IsEnabled             = $true
    ExpiryTime            = [System.DateTimeOffset]::new((Get-Date).AddMonths(1)) # Careful here! ExpiryTime is not a sane DateTime, but a very rare DateTimeOffset
    AutomationAccountName = 'psautomate'
    ResourceGroupName     = 'PowerShellCookBook'    
}
$captainHook = New-AzAutomationWebhook @parameters

# The Web Hook URI is only accessible once, during creation!
$captainHook.WebhookURI

# To run the runbook now, you can Invoke-RestMethod
$body = @{
    RunbookParam1 = 'Hello!'
    RunbookParam2 = 'All parameters will be there...'
} | ConvertTo-Json

# This will give you a job id back
$result = Invoke-RestMethod -Uri $captainHook.WebhookURI -Method Post -Body $body -ContentType application/json

# Wait until it is completed
Get-AzAutomationJob -id $result.JobIds[0] -AutomationAccountName psautomate -ResourceGroupName PowerShellCookBook

# Once completed, get the result
$jobOutput = Get-AzAutomationJobOutput -Id $result.JobIds[0] -AutomationAccountName psautomate -ResourceGroupName PowerShellCookBook -Stream Output |
    Get-AzAutomationJobOutputRecord

$jobVerbose = Get-AzAutomationJobOutput -Id $result.JobIds[0] -AutomationAccountName psautomate -ResourceGroupName PowerShellCookBook -Stream Verbose |
Get-AzAutomationJobOutputRecord

# Everything that was returned
$jobOutput.Value.value

# And the verbose output
$jobVerbose
