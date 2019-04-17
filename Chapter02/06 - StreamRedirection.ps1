throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# All streams can be redirected by their numbers
Get-Item -Path $home,'nonexistant' 2> error.txt 1> success.txt
Get-Content -Path error.txt, success.txt

# Appending can be done with >>
# Observe that the output is entirely suppressed
Get-Item -Path $home,'nonexistant' 2>> error.txt 1>> success.txt
Get-Content -Path error.txt, success.txt

# You can also redirect streams into other streams
# This helps e.g. with misbehaving external applications
Get-Module -Verbose -List -Name 'PackageManagement','nonexistant' 2>&1 4>&1

# Be aware that combining streams will pollute the output
$modules = Get-Module -Verbose -List -Name 'PackageManagement','nonexistant' 2>&1 4>&1
$modules.Count # This should contain only one...
$modules[0] # This definitely does not look like a module
