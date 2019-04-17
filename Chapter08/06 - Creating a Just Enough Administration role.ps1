throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Just Enough Administration has debuted with Windows PowerShell 5
# as a Role Based Access Control for remote sessions

# Beyond the built-in configurations, you can use JEA to add your own
Get-PSSessionConfiguration

# One necessary component for Role Based Access Control is at least one Role
# First identify the necessary cmdlets for your administrators without restrictions
$cmdlets = @(
    'Storage\Get-*'
    'Microsoft.PowerShell.Management\Get-Item*'
)

# Next, there might be some restricted cmdlets
$cmdlets += @{ Name = 'Stop-Process'; Parameters = @{ Name = 'Name'; ValidateSet = 'msiexec', 'CoreServicesShell' }, @{Name = 'Force'; ValidateSet = $true, $false}}
$cmdlets += @{ Name = 'Restart-Service'; Parameters = @{Name = 'Name'; ValidatePattern = 'Spoo\w+'}}

# Maybe your users need file system and registry access
$providers = 'FileSystem', 'Registry'

# It might be that you want to run an unrestricted script before the user starts
Set-Content .\somescript.ps1 -Value 'Write-Host "Hello $env:USERNAME!`r`nWith great power comes great responsibility ಠ_ಠ"' -Encoding utf8
$scriptsToProcess = (Resolve-Path .\somescript.ps1).Path

# Your role capabilities should be placed in e.g. a module, out of the users reach
# Due to a bug, you cannot use versioned directories at the moment
$modulePath = New-Item -ItemType Directory -Path "$PSHOME\Modules\MyJeaModule\RoleCapabilities" -Force
$null = New-Item -Path $modulePath.Parent -Name MyJeaModule.psm1
$null = New-ModuleManifest -Path "$($modulePath.Parent)\MyJeaModule.psd1" -CompatiblePSEditions Core -ModuleVersion 1.0.0

# Bring it all together with New-PSRoleCapabilityFile
New-PSRoleCapabilityFile -Path (Join-Path $modulePath -ChildPath LocalServiceAdmin.psrc) -VisibleCmdlets $cmdlets -VisibleProviders $providers -ScriptsToProcess $scriptsToProcess

# Review the contents
psedit (Join-Path $modulePath -ChildPath LocalServiceAdmin.psrc)
