throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Linux does not work with event logs like Windows does
Get-ChildItem /var/log

# To make matters worse, the default log files are all in a different format
Get-ChildItem -Path /var/log -File | foreach {$_ | Get-Content | Select -First 1 -Skip 5 }

# However, many logs at least share a format:
# TimeStamp Hostname Source: message
Get-Content /var/log/messages

# We can create a nice RegEx and custom class again
class LogEntry
{
    [string] $Message
    [datetime] $TimeWritten
    [string] $ComputerName
    [string] $Source
    [uint32] $ProcessId
}

# The pattern we have identified can be expressed with RegEx
# \d matches decimals, \w alphanumeric characters
# THe quantifiers + and {n,m} are used to specify the amount of characters
$logpattern  = "(?<TimeWritten>\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})\s+"

# The quantifier ? means 0 or 1 occurence. This should match our ProcessID just fine
$logpattern += "(?<ComputerName>\w+)\s+(?<Source>\w+)(\[(?<ProcessId>)\d+\])?:.*"

# So, what to do about the useless date format? For example: Mar 6 20:30:01
# We can easily convert that as well with a DateTime static method ParseExact
[datetime]::ParseExact('Mar 6 20:30:01', 'MMM d HH:mm:ss', [cultureinfo]::InvariantCulture)

# Bringing it all together
function Import-SystemLog
{
    param
    (
        [string]
        $Path
    )
    $logpattern  = "(?<TimeWritten>\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})\s+(?<ComputerName>\w+)\s+(?<Source>\w+)(\[(?<ProcessId>)\d+\])?:(?<Message>.*)"
    Get-Content -Path $PAth | ForEach-Object {
        if ($_ -match $logpattern)
        {
            $logEntry = [LogEntry]::new()
            $logEntry.TimeWritten = [datetime]::ParseExact(($Matches.TimeWritten -replace '\s+',' '), 'MMM d HH:mm:ss', [cultureinfo]::InvariantCulture)
            $logEntry.Message = $Matches.Message
            $logEntry.Source= $Matches.Source
            $logEntry.ComputerName = $Matches.ComputerName
            $logEntry
        }
    }
}

Import-SystemLog -Path /var/log/messages
Import-SystemLog -Path /var/log/cron

# Now, to log, there is no need for a cmdlet. We should use logger instead.
# The configuration of e.g. rsyslogd will govern how the SYSLOG messages are written
# when logger logs them
logger -p local0.emergency "Oh god, it buuuurns"

# With the adoption of proper SYSLOG style messages that consist
# of Facility, Severity and so on, life could be a lot easier
# take a look at the module Posh-SYSLOG
Install-Module Posh-SYSLOG

# While this cmdlet is meant to be used with a SYSLOG sink, using
# it with the Verbose switch shows you which message is being sent
Send-SyslogMessage -Server localhost -Message hello -Severity Emergency -Hostname localhost -Facility local0 -Verbose
