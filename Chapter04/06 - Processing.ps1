throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# PowerShell's processing cmdlet is Foreach-Object
# Taken very literal, we do things for each object
Get-ChildItem -File | ForEach-Object -Process { Get-FileHash -Path $_.FullName }

# With the range operator, you have a very simple collection to iterate over
# The output of Foreach-Object will be whatever is returned in the script blocks
$files = 1..10 | ForEach-Object -Process { New-TemporaryFile }

# Foreach-Object can also be used, albeit a bit too complicated, to expand property values
# or execute methods by specifying the name of the member
Get-ChildItem | ForEach-Object -MemberName BaseName
Get-Process | ForEach-Object -MemberName ToString
(Get-ChildItem).LastWriteTime | ForEach-Object -MemberName ToString -ArgumentList 'F', ([cultureinfo]'de-de')

# Foreach-Object can accept multiple script block arguments
# Begin and End are only executed once
$files | ForEach-Object -Begin {
    Write-Host -ForegroundColor Yellow "Starting pipeline processing"
} -Process {
    Get-FileHash -Path $_.FullName
} -End {
    Write-Host -ForegroundColor Yellow "Finished pipeline processing"
}

# Like the Where method, the Foreach method can be used instead of Foreach-Object
# Arguments are script blocks, member names or data types to convert to
$files.ForEach( { Get-FileHash -Path $_.FullName })
# Method calls
$files.ForEach('ToString')
# Type conversions for collections
$files.LastWriteTime.ForEach([string])

# You can include progress in Foreach-Object with Write-Progress for example
# Do not use this example in VSCode, at the time of writing, progress bars would not display
$counter = 0
$collection = Get-Process
$collection | ForEach-Object -Begin {
    Write-Progress -Id 1 -Activity 'Starting things' -Status 'Really doing it' -PercentComplete 0
    Start-Sleep -Milliseconds 100
} -Process {
    $counter++
    Write-Progress -Id 1 -Activity 'Working on things' -Status "Processing $($_.Name)" -PercentComplete ($counter / $collection.Count * 100)
    Start-Sleep -Milliseconds 100
}

# In addition to Foreach-Object and Foreach(), there is also the foreach statement
# It often looks a lot cleaner, and it will not add the overhead that a cmdlet does
$events = foreach ( $domain in (Get-ADForest).Domains)
{
    # Caution: Do not use a filter * when accessing the AD unless you have to.
    # Think of a select * from a large table - you wouldn't do that...
    $computers = Get-ADComputer -Server $domain -Filter * | ForEach-Object -MemberName DnsHostName
    Invoke-Command -ComputerName $computers -ScriptBlock {
        # Collecting data on all machines
        Get-WinEvent -LogName Security -MaxEvents 10
    }
}

# Some types of collections like Dictionaries and Hashtables cannot directly be used with the Object cmdlets
$hashtable = @{
    Key1 = 'Value'
    Key2 = 'Another key, another value'
    Key3 = 'Yet another key'
}

# While there is output, it looks wrong - the entire hashtable is used as a single object
# This is because hashtables do not use a traditional zero-based index
$hashtable | ForEach-Object { Write-Host "Key: $($_.Key), Value $($_.Value)" }

# With an Enumerator, we can start the iteration for real
$hashtable.GetEnumerator() | ForEach-Object { Write-Host "Key: $($_.Key), Value $($_.Value)" }

# Performance comparison
Measure-Command { 1..1000 | ForEach-Object { $_ } } | Select-Object TotalMilliSeconds # 43ms
Measure-Command { (1..1000).Foreach( { $_ }) } | Select-Object TotalMilliSeconds # 33ms
Measure-Command { # 12ms
    foreach ($i in 1..1000)
    {
        $i
    } } | Select-Object TotalMilliSeconds
