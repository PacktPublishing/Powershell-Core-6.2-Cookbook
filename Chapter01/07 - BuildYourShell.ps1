throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Clone the repository
git clone https://github.com/powershell/powershell

Set-Location -Path .\powershell
Import-Module ./build.psm1

# Ensure you have the latest version of .NET Core and other necessary components
Start-PSBootStrap

# Start the build process
Start-PSBuild

# Either run PowerShell directly...
& $(Get-PSOutput)

# ...or copy it to your favorite location (here: Program Files on Windows, necessary access rights required)
$source = Split-Path -Path $(Get-PSOutput) -Parent
$target = "$env:ProgramFiles\PowerShell\$(Get-PSVersion)"
Copy-Item -Path $source -Recurse -Destination $target