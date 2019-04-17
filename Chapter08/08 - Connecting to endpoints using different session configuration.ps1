throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Connecting to different endpoints is beyond easy
$configurationName = 'SupportSession'

# If your user can be matched to any role, you will be admitted
# You can test this before
# Run this command directly on e.g. PACKT-DC1
Get-PSSessionCapability -ConfigurationName SupportSession -Username contoso\Install

# Now that you know that the user can do what you need, connect to it
$session = New-PSSession -ComputerName PACKT-DC1 -ConfigurationName SupportSession -Credential contoso\Install

# Pretty easy, right? Connect to it
Enter-PSSession $session

# Try to find out what you can do
Get-Command

# Not much, right...
Restart-Computer -Force # Nope
Enable-Privileges # Nope
Get-Item HKLM:\SOFTWARE # No we are getting somewhere
Get-Item cert:\localmachine # :(

# You will only be able to execute the cmdlets that your admin allowed
Restart-Service -Name Spooler

# Exit the session
Exit-PSSession

# The same permissions apply when scripting against the session
Invoke-Command -Session $session -ScriptBlock {
    Get-Item C:\Windows # Yes!
}

Invoke-Command -Session $session -ScriptBlock {
    Restart-Computer -Force # Nope.
}

# even this works
Import-PSSession -Session $session -Prefix Restricted
Get-RestrictedItem -Path C:\Windows # How cool is that...

# Even greater comfort can be achieved with the PSSessionConfigurationName variable
# this variable sets the default configuration name for new sessions
$PSSessionConfigurationName = 'SupportSession'

# Ideal: Add this to a profile
Add-Content -Path $profile.AllUsersAllHosts -Value '$PSSessionConfigurationName = "SupportSession"'
