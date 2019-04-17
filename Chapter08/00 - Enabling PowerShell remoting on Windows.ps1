throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# While PSRemoting on Windows is already enabled for Windows PowerShell
# it needs to enabled for PowerShell Core
Enable-PSRemoting -Force -Verbose

# Should you need to enable remoting on public networks, you can add
Enable-PSRemoting -Force -Verbose -SkipNetworkProfileCheck
Get-NetFirewallRule -Name WINRM-HTTP-In-TCP | Set-NetFirewallRule -Profile Public

# With that done, you can verify by looking at the session configurations
Get-PSSessionConfiguration

# Have a look at the default ACL
(Get-PSSessionConfiguration -Name PowerShell.6).Permission

# So by default, Administrators and Remote Mgmt Users can connect. Let's change that.
Get-PSSessionConfiguration -Name PowerShell.6 | Set-PSSessionConfiguration -ShowSecurityDescriptorUI

# You will see in a later recipe how JEA could be used as well