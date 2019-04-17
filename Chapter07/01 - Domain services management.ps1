throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# The lab that you deployed already contains a functioning forest
# So let's create new forest and a bidirectional trust
# All cmdlets are assumed to be executed on PACKT-DC2

# Ensure that Domain Services are installed
powershell -Command "& {Install-WindowsFeature -Name AD-Domain-Services,DNS,RSAT-AD-PowerShell}"

# Discover the necessary cmdlets
Get-Command -Module ADDSDeployment

# The setup is very straightforward
$parameters = @{
    DomainName                    = 'partsunlimited.com'
    SafeModeAdministratorPassword = Read-Host -AsSecureString -Prompt 'Safemode admin password'
    InstallDNS                    = $true
    DomainMode                    = 'WinThreshold'
    Force                         = $true
    ForestMode                    = 'WinThreshold'
    DomainNetbiosName             = 'partsunlimited'
    Verbose                       = $true
}

Install-ADDSForest @parameters

# After the machine has fully rebooted, we can continue the configuration

# In a situation where e.g. a merger occurs, establishing trust might make sense
Get-Command -Noun ADTrust

# Unfortunately, there is no dedicated cmdlet available. But we can still use .NET
# We need: A directory context type, the forest name, an administrator and the *drumroll* plaintext password
[System.DirectoryServices.ActiveDirectory.DirectoryContext]::new
[enum]::GetValues([System.DirectoryServices.ActiveDirectory.DirectoryContextType])

# First of all, we create a context to retrieve the remote forest
$targetForestCtx = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Forest', 'contoso.com', 'contoso\Install', 'Somepass1')

# Using that context, we can instanciate it
$targetForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($targetForestCtx)

# The second ingredient will be our current forest
$currentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

$Forest.CreateTrustRelationship($TargetForest, "Bidirectional")

# Verify
Get-ADTrust -Filter *

# Verify again
Get-ADTrust -Filter * -Server contoso.com -Credential contoso\install