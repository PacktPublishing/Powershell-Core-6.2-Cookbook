throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# One of the most common use cases is remote data retrieval
# This mostly starts with an Invoke-Command
$remoteProcess = Invoke-Command -ComputerName PACKT-DC1 -Credential contoso\Install -ScriptBlock {
    Get-Process -Id $pid
}

# On the output stream, everything looks fine
$remoteProcess

# In case you did not notice it - the remote host process is the WSMan provider host, wsmprovhost.exe
$remoteProcess | Format-Table Name, Id, PSComputerName

# So what can we do with it?
$remoteProcess.Kill()

# That was not great. Deserialization means we lose some information
$remoteProcess | Get-Member

# When retrieving data for multiple machines, PSComputerName is a great helper.
# With persistent sessions we can retrieve data at a later time
$sessions = New-PSSession -ComputerName PACKT-FS-A,PACKT-FS-B,PACKT-FS-C -Credential contoso\Install

# Invoke-Command uses up to 32 parallel connections, unless specified with a ThrottleLimit
# With existing sessions, the command returns quickly
Invoke-Command -Session $sessions -ScriptBlock {
    $eventEntries = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 6005,6006
    }
}

# If you connect later on, the result is still there
Invoke-Command -Session $sessions -ScriptBlock { $eventEntries }

# With PSComputerName, filtering and grouping is a breeze
Invoke-Command -Session $sessions -ScriptBlock { $eventEntries } | Where-Object PSCOmputerName -eq 'PACKT-FS-B'

$groupedResult = Invoke-Command -Session $sessions -ScriptBlock { $eventEntries } | Group-Object PSCOmputerName -AsHashTable -AsString
$groupedResult.'PACKT-FS-B' # Events on PACKT-FS-B

# You can not only collect the result of variables, you can import entire sessions
$module = Import-PSSession -Session $sessions[0]
Get-Command -Module $module

# To persist this session, store it with Export-PSSession to use it again later
Export-PSSession -Session $sessions[0] -OutputModule .\MyReusableSession -Module Storage
