throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# To query the Windows event log, there is only one cmdlet in PowerShell Core
Get-WinEvent -LogName System -MaxEvents 10

# However, there are two ways of querying data. Slow and fast. Efficient and inefficient.
# This chapter will not show you more inefficient queries, and instead give your performance.

# The Performance recipe in Chapter 04 already got into detail, so let's take apart
# the three filters

<# FilterHashtable

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
#>

# If you have generated a logon event of a malicious user (It was El Barto!)
# you can filter for it
$logOnEvents = Get-WinEvent -FilterHashtable @{
    # Use the security log
    LogName = 'Security'

    # The Logon Event is just a single ID: 4624
    ID = 4624

    # In the best case we know at least a start time, i.e. somewhere in the last 24h
    StartTime = (Get-Date).AddDays(-1)

    # Now for the beautiful part
    TargetUserName = 'elbarto'
    TargetDomainName = 'contoso.com'
}

# Let's see where that guy logged on to
[xml]$xmlEvent = $logOnEvents[0].ToXml()
$ip = ($xmlEvent.Event.EventData.Data | Where-Object Name -eq IpAddress).InnerText
$hostName = [Net.Dns]::GetHostByAddress($ip).HostName

Write-Host "The infamous El Barto tagged $hostname!"

# FilterXml
# The XML filter is a bit more complex. It is easiest to export it from the Event Viewer.
# Looking at the structure though it is really easy to cobble together
# This filter contains two queries and will yield three different Event IDs
$xmlFilter = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[EventID=4624] and EventData[Data[@Name = "TargetUserName"] = "elbarto"]]</Select>    
  </Query>
  <Query Id="1" Path="System">
    <Select Path="System">*[System[(EventID=6005 or EventID=6006) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
  </Query>
</QueryList>
"@

Get-WinEvent -FilterXml $xmlFilter


# FilterXPath
# The XPath filter is simply an extract from the previous XML filter. The XML filter
# just combines multiple XPath queries in a query list
$xpathFilter = '*[System[EventID=4624] and EventData[Data[@Name = "TargetUserName"] = "elbarto"]]'
Get-WinEvent -FilterXPath $xpathFilter -LogName Security

# Or to do it programatically
foreach ($query in ([xml]$xmlFilter).QueryList.ChildNodes)
{
    Write-Host -ForegroundColor Yellow "Querying $($query.Path)" -NoNewline
    Get-WinEvent -FilterXPath $query.Select.InnerText -LogName $query.Path
}
