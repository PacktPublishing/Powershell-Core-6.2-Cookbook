throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Let's get a lay of the land first
yum groups list

# Since OS commands always return text, we can use PowerShell to get to
# the information we want
yum groups list | Select-String 'Web Server'
(yum groups list) -match 'Web Server'

# Suppress the error stream
(yum groups list 2>$null) -match 'Web Server'

# Install the package by just executing the binary
$groupname = ((yum groups list 2>$null) -match 'Web Server').Trim()
yum groups install $groupname -y

# Without using Start-Process, all we have is the last exit code
if ($LASTEXITCODE -ne 0)
{
    Write-Warning "Installing $groupname failed"
}

# Try it again with a process - be careful to use double qutation marks
$process = Start-Process -FilePath yum -ArgumentList groups,install, "`"$groupname`"", '-y' -Wait -PassThru

if ($process.ExitCode -ne 0)
{
    Write-Warning "Installation with the following command line failed: $($process.StartInfo.FileName) $($process.StartInfo.Arguments)"
}

# Now our tools shows up properly
# With the awesome features of PowerShell, grabbing the correct string in a text is easy
(yum groups list 2>$null | Out-String) -match "Installed Environment Groups:\s+(?<PackageName>[\w\s]+)`n"
$Matches.PackageName