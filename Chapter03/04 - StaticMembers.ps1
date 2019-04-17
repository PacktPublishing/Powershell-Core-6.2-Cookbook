throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Using a static method
[Console]::Beep(440, 1000)

# Accessing a static property
[System.IO.Path]::PathSeparator

# Using Get-Member to find static properties of .NET types
# of objects
Get-Process | Get-Member -Static
[System.Diagnostics.Process]::GetCurrentProcess()

# and of types
[datetime] | Get-Member -Static
[datetime]::Parse('31.12.2018',[cultureinfo]::new('de-de'))
[datetime]::IsLeapYear(2020) # Finally, February 29th is back!

# The path class is very helpful
$somePath = '/some/where/over/the.rainbow'
[IO.Path]::GetExtension($somePath)
[IO.Path]::GetFileNameWithoutExtension($somePath)
[IO.Path]::GetTempFileName() # Which is where your New-TemporaryFile is coming from
[IO.Path]::IsPathRooted($somePath)

# And so are the other classes in the IO namespace.
# Ever wanted to test your monitoring?
$file = [IO.File]::Create('.\superlarge')
$file.SetLength(1gb)
$file.Close() # Close the open handle
Get-Item $file.Name # The length on disk is now 1gb
Remove-Item $file.Name

# In order to lock a file for your script, the file class offers methods as well
$tempfile = New-TemporaryFile
$fileHandle = [IO.File]::OpenWrite($tempfile.FullName)
# Try to add content now - the file is locked
'test' | Add-Content $tempfile.FullName
# The method Write can be used now as long as you keep the handle
# Using another static method to get the bytes in a given string
$bytes = [Text.Encoding]::utf8.GetBytes('Hello :)')
$fileHandle.Write($bytes)
$fileHandle.Close() # Release the lock again
Get-Content -Path $tempfile.FullName

# Ever needed to validate drives?
[IO.DriveInfo]::GetDrives()

if ($IsLinux)
{
    [IO.DriveInfo]'/'
    [IO.DriveInfo]'/sausage' # A valid, but non existant drive will show IsReady = $false
}
else
{
    [IO.DriveInfo]'C'
    [IO.DriveInfo]'Y' # A valid, but non existant drive will show IsReady = $false
}

# Sometimes, .NET classes can control the bevavior of PowerShell cmdlets
# Setting the allowed security protocols for the .NET web client classes
# that are used with Invoke-WebRequest, Invoke-RestMethod, ...
$originalProtocol = [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::SecurityProtocol = $originalProtocol
