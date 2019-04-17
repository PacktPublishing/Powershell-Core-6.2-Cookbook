if ((Split-Path $pwd.Path -Leaf) -ne 'ch04')
{
    Set-Location .\ch04
}

throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Grouping data by certain properties is very useful
Get-Service | Group-Object -Property Status
Get-WinEvent -LogName System -MaxEvents 100 | Group-Object -Property LevelDisplayName

# Especially when working remotely on multiple systems, grouping can help
# each background job and each remote execution will add a property called PSComputerName
# which contains the machine the data originated on.
$computers = Get-Content -Path .\MassiveComputerList.txt
$cred = [pscredential]::new('Install',('Somepass1' | ConvertTo-SecureString -AsPlainText -Force))
Invoke-Command -ComputerName $computers -Credential $cred -ScriptBlock {
    Get-WinEvent -LogName System -MaxEvents 100
} |
    # Grouping on PSComputerName, or as seen here a combination of Hostname and Level
Group-Object -Property PSComputerName, LevelDisplayName

# The parameter AsHashtable will create a hashtable, with the keys being the grouped property values
Get-Process | Group-Object Name -AsHashTable
$groupedProcs = Get-Process | Group-Object Name -AsHashTable
$groupedProcs.svchost # on Windows
$groupedProcs.systemd # on Linux with Systemd

# Depending on the data type of your property, adding the parameter AsString is helpful.
# This parameter indicates that the property values will be converted to strings
$withoutAsString = Get-Service | Group-Object -Property Status -AsHashTable
# This is not possible
$withoutAsString.Running
# This would work - but do you really want this?
$withoutAsString[([System.ServiceProcess.ServiceControllerStatus]::Running)]

# AsString helps
$withAsString = Get-Service | Group-Object -Property Status -AsHashTable -AsString
$withAsString.Running

# With constructed properties, you can again group on anything
$files = 1..100 | % {$f = New-TemporaryFile; Set-Content -Value (Get-Random -min 1 -max 100) -Path $f.FulLName; $f}

# Grouping files by hash is a quick and easy way to identify duplicates in the file system
$files | Group-Object -Property {(Get-FileHash $_.FullName).Hash}

# Combined with cmdlets like where object, the results can be narrowed down further
$files |
    Group-Object -Property {(Get-FileHash $_.FullName).Hash} |
    Where-Object -Property Count -gt 1

# Constructed properties are also very useful for things like this
# an object DN in the Active Directory can be used to quickly group user
# by parent OU, with the format being CN=someuser,OU=someOu,DC=contoso,DC=com
# The RegEx pattern replaces "CN=...," , leaving only the OU string intact.
Get-ADUser -Filter * |
    Group-Object -Property @{
    Expression = {
        $_.distinguishedName -replace 'CN=\w+,'
    }
}