throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# All cmdlets on a system
Get-Command

# Most important parameter Syntax to display the cmdlet syntax
Get-Command New-Item -Syntax

# List all cmdlets with a specific verb from one or more modules
Get-Command -Verb Get -Module Microsoft.PowerShell.Utility

# List all external applications and libraries
Get-Command -CommandType Application

# Very interesting as well - searching for imported cmdlets by their parameters
# ComputerName,CimSession and PSSession indicate remoting capabilities
Get-Command -ParameterName ComputerName,CimSession,PSSession

# Performing a wildcard search through the cmdlet gallery
Get-Command *Process,*Item

# New-Alias will be used to create aliases. Aliases will overwrite existing
# cmdlets without hesitation. Have a look at Get-Help about_Command_precedence for more information
New-Alias -Name Start-Process -Value hostname
Get-Command Start-Process

# But Get-Command will help yet again and display all instances of a command
# listing everything with the same name
Get-Command Start-Process -All

# For the advanced user

# Discover more about a cmdlet with Get-Member
Get-Command New-Item | Get-Member

# Examine additional properties that might be helpful
$cmd = Get-Command New-Item

# Where does the cmdlet's help content come from?
$cmd.HelpUri

# Quickly jump to the location of a cmdlet's module
Set-Location -Path $cmd.Module.ModuleBase

# How many parameters does a cmdlet have including the common parameters?
$cmd.Parameters.Count

# Discovering the data of a parameter, in this case realising that
# New-Item allows empty strings or $null to be passed to the Name parameter
$cmd.Parameters.Name
