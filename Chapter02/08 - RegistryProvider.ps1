throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Like the file system, the local registry hives can be browsed.
# ACLs apply, so AccessDenied errors are not uncommon
Get-ChildItem HKLM:\SOFTWARE

# There are no additional filters like -Key or -Value to only return subsets.
# Get-ChildItem returns Keys and their values by default
Get-ChildItem -Recurse -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'

# To retrieve only properties, Get-ItemProperty is used instead
# Without a name, Get-ItemProperty returns all values in a given path
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

# If only the property value is used
Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName

# While this is used predominantly for Registry access, it can be used for the file
# system as well. However, this approach is very cumbersome
Get-ItemProperty -Path $(Get-Command -Name pwsh).Source -Name LastWriteTime

# In order to create new keys, you can use New-Item
New-Item -Path HKCU:\Software -Name MyProduct

<#
To create new values, use New-ItemProperty. Values for PropertyType include:
String (REG_SZ): Standard string
ExpandString (REG_EXPAND_SZ): String with automatic environment variable expansion
Binary (REG_BINARY): Binary data
DWord (REG_DWORD): 32bit binary number
MultiString (REG_MULTI_SZ): String array
QWord (REG_QWORD): 64bit binary number
#>
New-ItemProperty -Path HKCU:\Software\MyProduct -Name Version -Value '0.9.9-rc1' -PropertyType String
New-ItemProperty -Path HKCU:\Software\MyProduct -Name SourceCode -Value $([Text.Encoding]::Unicode.GetBytes('Write-Host "Cool, isnt it?"')) -PropertyType Binary

# Test it ;)
[scriptblock]::Create($([Text.Encoding]::Unicode.GetString($(Get-ItemPropertyValue -Path HKCU:\Software\MyProduct -Name SourceCode)))).Invoke()

# Change an item
Set-ItemProperty -Path HKCU:\Software\MyProduct -Name SourceCode -Value $([Text.Encoding]::Unicode.GetBytes('Stop-Computer -WhatIf'))
[Text.Encoding]::Unicode.GetString($(Get-ItemPropertyValue -Path HKCU:\Software\MyProduct -Name SourceCode))

# The default removal cmdlet works just as well
Remove-Item -Path HKCU:\Software\MyProduct -Verbose

# Provider capabilities
# Not capable of using credentials
Get-PSProvider -PSProvider Registry

# Mapping local hives is fine
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
Get-ChildItem -Path HKCR:
Remove-PSDrive -Name HKCR

# Remotely mapping hives with .NET
# Your preferred method should be Invoke-Command!
# Your security context must match, DCOM and RPC will be used
# Try this on any server in the lab environment
$remoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', 'PACKT-FS-A', 'Registry64')
$remoteUserKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('CurrentUser', 'PACKT-FS-A', 'Registry64')

# Open a subkey in the hive. An optional boolean value indicates if write access is requested
$remoteKey.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion').GetValueNames()
$remoteKey.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion').GetValue('ProductName')

$remoteUserKey.OpenSubKey('SOFTWARE',$true).CreateSubKey('MyProduct').SetValue('Version','1.2.3.4', 'String')
$remoteUserKey.OpenSubKey('SOFTWARE\MyProduct').GetValue('Version')
$remoteUserKey.DeleteSubKeyTree('Software\MyProduct') # Or DeleteSubkey for non-recursive access

# When done, free up any remaining resources and references
$remoteKey.Dispose()
$remoteUserKey.Dispose()
