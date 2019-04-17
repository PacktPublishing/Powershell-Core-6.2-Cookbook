throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Try this
$true = $false
$pid = 0
$Error = "I don't make mistakes!"

# And this is why it did not work
Get-Variable | Where-Object -Property Options -like *Constant*

# Creating read-only and constants requires the variable cmdlets
$logPath = 'D:\Logs'
Set-Variable -Name logPath -Option ReadOnly

# Changing read-only variables still works though
Set-Variable -Name logPath -Value '/var/log' -Force

# The parameter Option is not only useful for read-only variables
# We will see variable scoping in the following recipe.
Get-Help -Name New-Variable -Parameter Option
New-Variable -Name UbiquitousOne -Option AllScope
