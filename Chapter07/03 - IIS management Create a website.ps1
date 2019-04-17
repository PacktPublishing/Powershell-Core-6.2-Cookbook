throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# In the previous recipe you configured IIS
# Now it is time for a web site

# First things first - remove the useless default web site
Import-WinModule WebAdministration
Get-WebSite | Remove-WebSite

# Next up: deploy your own web site, sourcing an SSL cert from your PKI
$webDirectory = New-Item -ItemType Directory -Path C:\CustomSite

# The ConvertTo-Html cmdlet is always useful to generate a short overview site
Get-Service | Select Name, Status | ConvertTo-Html | ForEach-Object {
    if ($_ -match 'Running')
    {
        $_ -replace '<tr>', '<tr color="Green">'
    }
    elseif ($_ -match 'Stopped')
    {
        $_ -replace '<tr>', '<tr color="Red">'
    }
    else
    {
        $_
    }
} | Set-Content -Path (Join-Path -Path $webDirectory.FullName -ChildPath 'index.html')

# You can of course combine multiple items
$svcFragment = Get-Service | Select Name, Status | ConvertTo-Html -Fragment -As Table | ForEach-Object {
    if ($_ -match 'Running')
    {
        $_ -replace '<tr>', '<tr color="Green">'
    }
    elseif ($_ -match 'Stopped')
    {
        $_ -replace '<tr>', '<tr color="Red">'
    }
    else
    {
        $_
    }
}
$prcFragment = Get-Process | Where WS -gt 150MB | Select ProcessName,@{Name='WS in MB';Expression={[math]::Round(($_.WS / 1MB),2)}} | ConvertTo-Html -Fragment
@"
<html>
<head><title>PowerShell is AWESOME</title></head>
<body>
<p>Service status on $($env:COMPUTERNAME)</p>
$($svcFragment)
<p>Running processes gt 150MB RAM<p>
$($prcFragment)
</html>
"@ | Set-Content -Path (Join-Path -Path $webDirectory.FullName -ChildPath 'overview.html')

# Try it
New-Website -Name 'HostOverview' -Port 443 -PhysicalPath $webDirectory.FullName -Ssl

# Add the certificate
$binding = Get-WebSite -Name HostOverview | Get-WebBinding
$certificate = Get-ChildItem Cert:\LocalMachine\my | Where-Object {$_.Subject -eq "CN=$env:COMPUTERNAME" -and $_.Issuer -like '*LabRootCA1*'}
$binding.AddSslCertificate($certificate.Thumbprint, 'My')

# Browse the site
start https://packt-wb1

