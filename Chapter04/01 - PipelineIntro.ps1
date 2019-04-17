throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Pipelines connect input and output
# Often Get and Set cmdlets are connected
Get-Service -Name spooler | Set-Service -Status Stopped -WhatIf

# The pipeline also works with empty collections. In this case, Stop-Process does not need to be called
Get-Process -Name *Idonotexist* | Stop-Process -WhatIf

# Regardless of how many objects Get-Process returns,
# Stop-Process processes each individual one
Get-Process -Id $pid | Stop-Process -WhatIf
Get-Process | Stop-Process -WhatIf

# How do cmdlets take pipeline input?
# Either by value - entire objects progress down the pipeline
Get-Help Get-Process -Parameter InputObject

# Or by property name - only the individual object properties are being used
Get-Help Get-Process -Parameter Id
Get-Help Get-Process -Parameter Name

# One example of ByValue and ByPropertyName is Get-Item
# The parameter Path accepts input by value as well as by property name
Get-Help Get-Item -Parameter Path
'/' | Get-Item

# ByPropertyName enables scenarios like this
Get-Process -Id $Pid | Get-Item

# Any object with the correct property will do
[pscustomobject]@{
    Id = 0
} | Get-Process

# Sometimes, a cmdlet might even have parameter aliases that allow you to pipe more object types
Get-Help Stop-Computer -Parameter ComputerName
(Get-Command Stop-Computer).Parameters.ComputerName.Aliases

# With this in mind and with access to the AD cmdlets, you can use Get-ADComputer
# to retrieve objects that have the property CN which binds to ComputerName
Get-ADComputer -SearchBase 'OU=RebootOU,DC=contoso,DC=com' -Properties CN -Filter * | Stop-Computer -WhatIf

# Have a look at all cmdlets and their parameter aliases
$ignoredParameters = 'WhatIf','Confirm','ErrorAction','ErrorVariable','WarningAction','InformationAction','OutBuffer','WarningVariable','OutVariable','PipelineVariable','InformationVariable','Verbose','Debug'

$FormatEnumerationLimit = -1 # To enable formatted lists of more than 4 elements for the current session
Get-Command | 
Where-Object { try{$_.Parameters.GetEnumerator() | ForEach-Object {$_.Value.Aliases.Count -gt 0 -and $_.Key -notin $ignoredParameters}}catch{}} |
Format-Table Name,@{
    Label = 'Aliases'
    Expression = {
        $_.Parameters.GetEnumerator() | ForEach-Object {
            if ($_.Value.Aliases.Count -gt 0 -and $_.Key -notin $ignoredParameters)
            {
                '{0}: {1}' -f $_.Key,($_.Value.Aliases -join ',')
            }
        }
    }
} -Wrap