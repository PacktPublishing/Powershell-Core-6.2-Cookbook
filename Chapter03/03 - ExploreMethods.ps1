throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Get-Member will help you as always
Get-ChildItem | Get-Member -MemberType Methods

# Accessing methods
$file = New-TemporaryFile
$parentPath = Split-Path -Path $file.FullName -Parent
$newPath = Join-Path -Path $parentPath -ChildPath newFileName

# With arguments
$file.MoveTo($newPath)
$file.FullName # The MoveTo method is a way of changing the FullName property, which is read-only.

# and without arguments
$file.Delete()

# Careful with empty objects or non-existing methods
# Method does not exist. Throws a terminating MethodNotFound error
$file.DoStuff()

# Object does not exist. Throws an InvokeMethodOnNull exception.
($null).Delete() # Will throw a terminating error

# Finding possible arguments
# CopyTo has two overloads
($file | Get-Member -Name CopyTo).Definition

# A handy shortcut is simply leaving the parentheses off
$file.CopyTo

# Performance of .NET calls versus cmdlets
Measure-Command -Expression {
    Get-ChildItem -Recurse -File -Path / -ErrorAction SilentlyContinue
} # Total seconds 93

Measure-Command -Expression {
    $root = Get-Item -Path /
    $options = [System.IO.EnumerationOptions]::new()
    $options.RecurseSubdirectories = $true
    $root.GetFiles('*', $options)
} # Total seconds 13

# Method calls may or may not return values
$process = Get-Process -Id $PID
$process | Get-Member -Name WaitForExit

# The WaitForExit method has two overloads
# When passing a timeout to WaitForExit, it returns a boolean value indicating if the process
# has exited in the allotted timeout.
$pingProcess = if ($IsWindows)
{
    Start-Process -FilePath ping -ArgumentList 'microsoft.com','-n 10' -PassThru
}
else
{
    Start-Process -FilePath ping -ArgumentList 'microsoft.com','-n 10' -PassThru
}

# Waiting 500ms should return false, since our 10 ICMP request will most likely not be done
if( -not $pingProcess.WaitForExit(500))
{
    Write-Host -ForegroundColor Yellow "Pinging not yet complete..."
}

# The other overload has no return type (void) and will wait indefinitely
$pingProcess.WaitForExit()

# Foreach-Object and members
# We create 10 notepads and use the WaitForExit method on all of them
$notepads = 1..10 | ForEach-Object {Start-Process -FilePath notepad -PassThru}

# We execute the WaitForExit method with one argument, the timeout
$notepads | ForEach-Object -MemberName WaitForExit -ArgumentList 500
$notepads | ForEach-Object -MemberName Kill
