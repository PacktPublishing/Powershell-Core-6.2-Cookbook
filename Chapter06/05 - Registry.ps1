throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

Get-PSProvider -PSProvider Registry
Get-PSDrive -PSProvider Registry

Get-ChildItem -Path HKCU:\Software
Set-Location -path HKCU:\Software
Get-ItemProperty -Path HKCU:\Software\Classes -name EditFlags

# Modifying the local registry is easy enough
# e.g. to disable the Server manager UI at logon
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -name "DoNotOpenServerManagerAtLogon" -Value 1

# Working with a remote registry is not possible with the built-in cmdlets
# However, with .NET, anything is possible
$remoteHive = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', 'DSCCASQL01')

# To open a key with write access, use the boolean value
$key = $remotehive.OpenSubKey('SoFTWarE\microsoft\servermanager', $true)

# Now the remote key can be used as well
$key.GetValue('DoNotopenServerManagerAtLogon')

# And with write access, we can write to it as well
$key.SetValue('DoNotopenServerManagerAtLogon', 0)