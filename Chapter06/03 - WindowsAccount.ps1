throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# The module in question is a Windows PowerShell module again
Add-WindowsPSModulePath
Import-Module Microsoft.PowerShell.LocalAccounts -SkipEditionCheck

# Now, creating a local user is as simple as it gets
New-LocalUser -AccountExpires (Get-Date -Year 2020 -Month 1) -Description 'A test user' -Name JHP -Password (Read-Host -AsSecureString)

# Adding the user to a group as well
Add-LocalGroupMember -Group Administrators -Member JHP

# Did you know that beyond Active Directory accounts you can also use Microsoft accounts?
Add-LocalGroupMember -Group users -Member "MicrosoftAccount\username@Outlook.com"

# Removing users again is very easy
Get-LocalUser -Name *JHP* | Remove-LocalUser