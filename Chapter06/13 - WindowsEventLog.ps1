throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Let's get familiar with the cmdlet first - brace for impact!
Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Format-Wide -Property LogName -Column 4

# These logs are known as event channels - for more than your standard Application and System log!
# We are interested in the security logs
Get-WinEvent -ListProvider *Security* | Format-Wide -Property Name -Column 4

# First of all, we can access the Security log quite simply
Get-WinEvent -LogName Security -MaxEvents 1

# We would like to look in the XML composition of the event. Sounds complicated?
# It is easier than you think. We can start by generating a sample 4625 (login failed) event...
# Be sure to use the wrong password for it to work ;)
runas /user:$($env:COMPUTERNAME)\$($env:USERNAME) pwsh

# We can get to this event rather inefficiently. Doing so prompts Get-WinEvent to comb through the
# ENTIRE security log - and you know how big those get.
Get-WinEvent -LogName Security | Where-Object -Property ID -eq 4625

# There is a better way
Get-Command Get-WinEvent -Syntax

# Let's start with FilterHashtable because of its simplicity - blazingly fast
$failedLogin = Get-WinEvent -FilterHashtable @{LogName = 'Security'; ID = 4625} -MaxEvents 1

# NOw we can examine it - a lot of information
$failedLogin | Get-Member -MemberType Properties

# One piece of information is particularly useful - the properties. But alas, they have no names
# But we'll see about that
$failedLogin.Properties

# As we know, every event in its natural form is an XML structure
$failedLogin.ToXml()

# We can use XML
$xmlEvent = [xml]$failedLogin.ToXml()

# There we go :)
$xmlEvent.Event.EventData.Data

# More importantly, we can now filter out exactly what we need
($xmlEvent.Event.EventData.Data | Where Name -eq TargetUserName).InnerText

# It would be great though to find that user without combing through all 4625 events, right?
# Enter the XPATH filter. 
$filter = '*[System[EventID=4625]] and *[EventData[Data[@Name = "TargetUserName"] = "japete"]]'
Get-WinEvent -FilterXPath $filter -LogName Security

# If you don't fancy XPATH, the FilterHashtable can work as well ;)
Get-Help Get-WinEvent -Parameter FilterHashtable
Get-WinEvent -FilterHashtable @{LogName = 'Security'; ID = 4625; TargetUserName = 'japete'}

# Of course, everything we did here, we can do remotely to dozens of machines.
$filterTable = @{LogName = 'Security'; ID = 4625; TargetUserName = 'japete'}

Invoke-Command -ComputerName (Get-Content .\thousandsOfMachines.txt) -ScriptBlock {
    Get-WinEvent -FilterHashtable $using:filterTable
}
