throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# To get started, download any file to an NTFS-formatted volume.
# This lab assumes that you are storing downloads in $home\Downloads
$downloadRoot = "~\Downloads"

# Download any file, for example a release of the popular lab automation framework AutomatedLab
start https://github.com/AutomatedLab/AutomatedLab/releases/download/v5.1.0.153/AutomatedLab.msi

# At first glance, this file appears normal
Get-Item $downloadRoot\AutomatedLab.msi

# But if we have a look at the ominous stream parameter, something appears
# Every valid NTFS file possesses a data stream - the actual file content.
# In case of a download, a stream is attached called the Zone Identifier
Get-Item $downloadRoot\AutomatedLab.msi -Stream *

# Streams can be processed with the Content-cmdlets
# The data stream is of course returned by default
Get-Content -Path C:\windows\logs\cbs\cbs.log -Stream ':$DATA'

# The zone identifier specifies if the file was downloaded from the Internet or another zone
# You can find out all kinds of information from this, like the content URL in this example.
# At the time of writing, the HostUrl resided on the S3 storage by Amazon and used an
# access signature to set the link expiration date
Get-Content -Path $downloadRoot\AutomatedLab.msi -Stream Zone.Identifier

# Let's try the other content cmdlets now...
Set-Content -Path .\TestFile -Value 'A simple file'
$bytes = [Text.Encoding]::Unicode.GetBytes('Write-Host "Virus deployed..." -Fore Red')
$base64script = [Convert]::ToBase64String($bytes)

# We have now hidden a script inside an inconspicuous file
Set-Content -Path .\TestFile -Stream Payload -Value $base64script

# And of course we can execute it in this beautiful one-liner
[scriptblock]::Create($([Text.Encoding]::Unicode.GetString($([Convert]::FromBase64String($(Get-Content .\TestFile -Stream Payload)))))).Invoke()

# You can clear the stream manually as well
Clear-Content -Path .\TestFile -Stream Payload

# And you can remove the entire stream
Remove-Item -Stream Payload -Path .\TestFile

# The Unblock-File cmdlet does exactly the same with the stream Zone.Identifier
Unblock-File -Path $downloadRoot\AutomatedLab.msi
Get-Item -Path $downloadRoot\AutomatedLab.msi -Stream *

# Advanced example: Find files with odd streams
Get-ChildItem -Path ~ -Recurse -File | Where-Object -FilterScript {
    $($_ | Get-Item -Stream *).Stream -notmatch ':\$DATA|Zone\.Identifier'
}
