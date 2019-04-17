throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Let's review Get-Command
Get-Command -Noun Csv

# Converting data to CSV is not the best way to represent complex data types
# The thread collection is formatted using the ToString() method.
Get-Process -Id $PID |
    Select-Object -Property Name, Id, Threads |
    ConvertTo-Csv

# Using the default delimiter, a comma
Get-Item / | Export-Csv -Path .\Default.csv
Get-Content -Path .\Default.csv

# Using the system delimiter is just one parameter
Get-Item / | Export-Csv -UseCulture -Path .\WithSytemDelim.csv
Get-Content -path .\WithSytemDelim.csv

# With a user-defined single character delimiter
# Here: A Tabulator
Get-Item / | Export-Csv -Delimiter "`t" -Path .\WithCustomDelim.csv

# With the append parameter, you can add objects to a csv
$objectA = [PSCustomObject]@{
    Column1 = 42
    Column2 = 'Value'
}
$objectB = [PSCustomObject]@{
    Column1 = 1337
    Column2 = 'Another value'
}
$objectC = [PSCustomObject]@{
    Column1 = 666
}
$objectA | Export-Csv -Path sequentialexport.csv
$objectB | Export-Csv -Append -Path .\sequentialexport.csv
# Missing properties will generate errors, unless -Force is used
$objectC | Export-Csv -Append -Path .\sequentialexport.csv
$objectC | Export-Csv -Append -Path .\sequentialexport.csv -Force

Import-Csv -Path .\sequentialexport.csv

# The data type of the import is a custom object with all-string properties
Import-Csv -Path .\sequentialexport.csv | Get-Member

# To prepare data on the fly, for example to pass it to other tools
# the conversion cmdlets can be used
$objectA | ConvertTo-Csv

# If you receive comma-separated values from applications, try using the Header parameter
'Value1, Value2, Value3' | ConvertFrom-Csv -Header Col1, Col2, Col3

# Through non-standard modules, you can easily extend or modify the objects that you want to export
Install-Module -Name PSFramework -Force -Scope CurrentUser
Get-ChildItem -File -Path / -Recurse -Depth 2 |
    Select-PSFObject Name, 'CreationTime.DayOfWeek as CreatedOn to string' |
    Export-Csv -Path ./exportedfiles.csv
