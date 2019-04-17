if ((Split-Path $pwd.Path -Leaf) -ne 'ch06')
{
    Set-Location .\ch06
}

throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return



# Build the dummy service template
dotnet build .\project1

# This simple service just reacts to requests and does nothing
.\project1\bin\debug\project1.exe

# The New-Service cmdlet registers anything as a service, so be careful here
New-Service -Name NaaS -BinaryPathName C:\windows\notepad.exe -DisplayName 'Notepad As A Service'

# With our dummy the service even reacts to the other service cmdlets
# Resolve path is necessary since New-Service does not resolve the relative path
New-Service -Name Dummy1 -BinaryPathName (Resolve-Path -Path .\project1\bin\debug\project1.exe).Path
Start-Service Dummy1
Stop-Service Dummy1

# Now we can of course also set credentials for our service
$credential = [pscredential]::new('LocalUserJohn', ('Somepass1!' | ConvertTo-SecureString -AsPlainText -Force))
New-LocalUser -Name $credential.UserName -Password $credential.Password
Set-Service -Name Dummy1 -Credential $credential -StartupType AutomaticDelayedStart

# One cmdlet that is still missing even today from Windows PowerShell
Remove-Service -Name dummy1 -Verbose
