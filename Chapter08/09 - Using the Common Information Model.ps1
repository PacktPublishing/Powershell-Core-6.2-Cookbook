throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# The common information model (CIM) allows you to retrieve data remotely
Get-Help about_CimSession

# CIM sessions do not require PowerShell nor do they require Windows
$cimSessions = New-CimSession -ComputerName PACKT-HV1, PACKT-DC1 -Credential Contoso\Install

# CIM sessions use Port 5985 by default, and the protocol WSMAN
# However, they cannot be used like PSSessions
Enter-PSSession -Session $cimSessions[0]
Invoke-Command -Session $cimSessions -ScriptBlock {Get-CimInstance Win32_Process}

# Normally, you would use them with the CIM cmdlets
Get-CimClass -ClassName Win32*System -CimSession $cimSessions

# CIM Classes can be discovered easily
# By property
Get-CimClass -PropertyName LastBootUpTime -CimSession $cimSessions[0]

# By method
Get-CimClass -MethodName Change -CimSession $cimSessions[0]

# On Windows, WMI implements the common information model
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cimSessions | Format-Table PSComputerName, LastBootUpTime

# With the Query parameter you can create some efficient filters
Get-CimInstance -Query 'SELECT * FROM Win32_Process WHERE CommandLine like "%ExecutionPolicy%"' | Select-Object -Property Name,ProcessId,CommandLine

# Desired State Configuration exclusively uses CIM (Windows PowerShell!)
Get-DscLocalConfigurationManager -CimSession $cimSessions[0]

# You can also call CIM methods
$result = Get-CimInstance -Query 'SELECT * FROM Win32_Service WHERE Name = "Spooler"' |
    Invoke-CimMethod -MethodName ChangeStartMode -Arguments @{StartMode = 'Automatic'}

$result.ReturnValue # can be used to test if the result was not a success

# Of course, CDXML (cmdlet data XML) cmdlets can also use CIM sessions
Get-NetAdapter -CimSession $cimSessions # Brilliant.
