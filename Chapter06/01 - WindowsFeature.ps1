throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Now, this comes up empty
Get-Module -ListAvailable -SkipEditionCheck -Name ServerManager

# However, dedicated people like Bruce Payette, Steve Lee and Mark Kraus made this possible
Install-Module -Name WindowsCompatibility -Scope CurrentUser -Force -AllowClobber

# With this module, implicit remoting is used for incompatible modules
# One of those being ServerManager
Import-WinModule -Name ServerManager

# Now, the discovery cmdlets work as well
Get-Command -Module ServerManager

# Suddenly, it all works out just fine
Get-WindowsFeature
Get-WindowsFeature -Name powershell-v2

# of course, with implicit remoting, pipelining is hit and miss
# In this case however, it works beautifully
Get-WindowsFeature -Name powershell-v2 | Remove-WindowsFeature

# of course, adding features is also a breeze
Get-WindowsFeature -Name RSAT-AD-Tools | Install-WindowsFeature