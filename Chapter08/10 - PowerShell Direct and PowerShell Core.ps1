throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Another Windows-only thing that has been introduced in Windows Server 2016
# is PowerShell Direct. Fortunately, it works in PSCore as well!

# First of all, disconnect the network adapters from one VM
Get-Vm -Name PACKT-FS-A | Get-VMNetworkAdapter | Disconnect-VMNetworkAdapter

# Hmm... Now what about remoting?
Enter-PSSession -ComputerName PACKT-FS-A -Credential Contoso\Install # Damn.

# Without network access, you can usually not remote into a machine.
# PowerShell Direct sheds these limitations
$directSession = New-PSSession -VMName PACKT-FS-A -Credential Contoso\Install # No errors this time

# Hmmm... That's odd. What happened to wsmprovhost
Invoke-Command -Session $directSession -ScriptBlock {
    Get-Process -id $pid
}

# Does that mean we don't even *need* remoting?
Invoke-Command -Session $directSession -ScriptBlock {
    Disable-PSRemoting -Force
}

# Let's try
Invoke-Command -Session $directSession -ScriptBlock {
    Write-Host "Remoting on $env:COMPUTERNAME is still working like a charm"
}

# PowerShell Direct might be your last resort some day, but only when remoting into Windows Server 2016+