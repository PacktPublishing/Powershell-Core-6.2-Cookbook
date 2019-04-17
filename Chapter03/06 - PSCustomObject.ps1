throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Use the typecasting operator to create one
[PSCustomObject]@{
    DeviceType     = 'Server'
    DomainName     = 'dev.contoso.com'
    IsDomainJoined = $true
}

# Alternatively, New-Object might be used
New-Object -TypeName pscustomobject -Property @{
    DeviceType     = 'Server'
    DomainName     = 'dev.contoso.com'
    IsDomainJoined = $true
}

# Using Get-Member with the output again shows more
# Notice the methods that exist, even though they have not been implemented by you?
# PSCustomObject, like many classes, inherits from the class Object
[PSCustomObject]@{
    DeviceType     = 'Server'
    DomainName     = 'dev.contoso.com'
    IsDomainJoined = $true
} | Get-Member

# Provided you supply the correct property names, you can use these custom
# objects in the pipeline as well.
Get-Help Get-Item -Parameter Path
[pscustomobject]@{ Path = '/'} | Get-Item

# Especially when being exported, the custom object really shines
$someLogMessages = 1..10 | ForEach-Object {
    [pscustomobject]@{
        ComputerName = 'HostA', 'HostB', 'HostC' | Get-Random
        EntryType    = 'Error', 'Warning', 'Info' | Get-Random
        Message      = "$_ things happened today"
    }
}
$someLogMessages | Export-Csv -Path .\NiceExport.csv
psedit .\NiceExport.csv

# When importing any csv, examine the datatype
Get-Date | Export-Csv .\date.csv
Import-Csv .\date.csv | Get-Member
Remove-Item .\date.csv

# You can even apply your own type name to your custom object
$jhp = [PSCustomObject]@{
    PSTypeName = 'de.janhendrikpeters.awesomeclass'
    TwitterHandle = 'NyanHP'
    Born = [datetime]'1987-01-24'
}
$jhp | Get-Member
$jhp.GetType().FullName # This method still knows the gory details

# You can even add your own type to anything
$item = Get-Item -Path /
$item.PSTypeNames.Insert(0,'JHP')
$item | Get-Member
