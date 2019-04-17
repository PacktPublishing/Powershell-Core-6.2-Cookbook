throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Performance is key with most cmdlets

# With Where-Object, all objects have to be retrieved from the Get-ChildItem cmdlet first
$files = Get-ChildItem -File -Recurse -Path $PSHOME | Where-Object -Property Extension -eq '.dll'
(Get-History)[-1].Duration

# The file system provider can use a filter parameter for file names which improves performance a lot
$files = Get-ChildItem -File -Recurse -Path $PSHOME -Filter *.dll
(Get-History)[-1].Duration

# The Windows event log can be accessed with PowerShell Core and the Get-WinEvent cmdlet
# However, there are no immediately available filter parameters like -Id or -Source
Get-WinEvent -LogName System | Where-Object -Property Id -in 6005,6006

# With the different parameter sets, we have some additional filter options
Get-Command -Syntax Get-WinEvent

<# The parameter FilterHashtable is quite useful. The filter may contain the following key value pairs:
LogName=<String[]>    
ProviderName=<String[]>    
Path=<String[]>    
Keywords=<Long[]>    
ID=<Int32[]>    
Level=<Int32[]>    
StartTime=<DateTime>
EndTime=<DataTime>
UserID=<SID>
Data=<String[]> - Refers to unnamed EventData entries from old event log formats
*=<String[]> - Refers to named event data entries

Our simple filter with Where-Object becomes the following hashtable:
#>
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ID = 6005, 6006
}

# Lastly, we can use FilterXml and FilterXpath. All event entries consist of their XML structure
# from which the formatted event message is generated. This XML structure can be queried with XPATH
# Here, the filter means: Look into the System node of an event, and select nodes with EventID 6005 or 6006
# Note here that XPATH is case-sensitive!
Get-WinEvent -LogName System -FilterXPath '*[System[EventID=6005 or EventID=6006]]'

# Comparing the runtime of our cmdlets speaks for itself
$eventsWhere = Get-WinEvent -LogName System | Where-Object -Property Id -in 6005,6006
$eventsXpath = Get-WinEvent -LogName System -FilterXPath '*[System[EventID=6005 or EventID=6006]]'
$eventsHash = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ID = 6005, 6006
}

$historyEntries = (Get-History)[-3..-1]

Write-Host ("
Where-Object: {0}
FilterXpath: {1}
FilterHashtable: {2}
" -f $historyEntries[-3].Duration,$historyEntries[-2].Duration,$historyEntries[-1].Duration)


# Even when not using Where-Object, pipeline processing can be improved drastically quite often.
# The following scenario generates file hashes for a bunch of temporary files.
$manyFiles = 1..1000 | foreach {$tmp = New-TemporaryFile | Get-Item; $tmp | Set-Content -Value (1..50 | foreach {Get-Random}); $tmp}

# Method 1 uses the beginners approach: Pipe to foreach and process each item individually
$manyHashes = $manyFiles | ForEach-Object -Process {$_ | Get-FileHash}
(Get-History)[-1].Duration # 320ms

# Method 2 uses Get-FileHash in the pipeline for all objects - very efficient when compared to Foreach-Object
$manyHashes = $manyFiles | Get-FileHash
(Get-History)[-1].Duration # 140ms

# Method 3 uses the Split-Pipeline module to split processing of long-running operations
Install-Module -Name SplitPipeline -Scope CurrentUser -Force
$manyHashes = $manyFiles | Split-Pipeline {process{ Get-FileHash $_.FullName }}
(Get-History)[-1].Duration
