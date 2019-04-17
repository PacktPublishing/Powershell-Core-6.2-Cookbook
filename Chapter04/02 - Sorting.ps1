throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Starting with something that is easily sortable
# Sort-Object will apply an ascending, alphanumeric sorting
'POSHDC1', 'POSHWEB1', 'POSHFS1', 'POSHDC2' | Sort-Object

# The sort order for all columns can be reversed as well
'POSHDC1', 'POSHWEB1', 'POSHFS1', 'POSHDC2' | Sort-Object -Descending

# When sorting objects, you can (and should) specify your sort criteria
# Since property accepts an object[], you can pass comma-separated values
Get-Process | Sort-Object -Property Name, WorkingSet64

# One improved over Windows PowerShell was the inclusion of Top and Bottom
# That way you can get to your information even faster
Get-Process | Sort-Object -Property WorkingSet64 -Bottom 5

# Some object types cannot be sorted that easily
# The status Running should not be output after the status Stopped - so what gives?
Get-Service | Sort-Object -Property Status, Name

# The property type is not a simple string, but an enumeration
Get-Service | Get-Member -Name Status
(Get-Service -Name spooler).Status.GetType().BaseType.FullName # System.Enum

# If we examine all values, we can see their string content
[enum]::GetNames([System.ServiceProcess.ServiceControllerStatus])

# Converting Running and Stopped to integers shows the root of the problem
# demonstrating that Sort-Object actually worked well, just not as we intended
[int][System.ServiceProcess.ServiceControllerStatus]::Stopped # 1
[int][System.ServiceProcess.ServiceControllerStatus]::Running # 4

# For these cases, the Property parameter accepts ScriptBlocks and Hashtables
# The first one often being a little easier for beginners
# The variable $_ or $PSItem point to each individual element in the pipeline
Get-Service | Sort-Object -Property {$_.Status.ToString()}, Name

# With a hashtable, you can specify a sort order for individual properties, which
# would also solve our conundrum.
# Valid keys of this hashtable are Expression, Descending and Ascending
Get-Service | Sort-Object -Property @{
    Expression = 'Status'
    Descending = $true
}

# Certain data types like lists support sorting as well, often being more efficient than Sort-Object
[int[]]$randomNumbers = 1..10000 | Foreach-Object {Get-Random}
Measure-Command -Expression {
    $intList = New-Object -TypeName System.Collections.Generic.List[int]
    $intList.AddRange($randomNumbers)
    $intList.Sort()
} # 8ms, including assembly import

Measure-Command -Expression {
    $randomNumbers | Sort-Object
} # 172ms, over 20 times slower, but less cumbersome to use
