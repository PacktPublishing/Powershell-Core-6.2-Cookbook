throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Providers extend PowerShell

<#
 Depending on your OS, there may be those providers:
   Alias - Allowing access to Aliases
   Environment - Allowing access to environmental variables
   Function - Allowing access to function script blocks
   Variable - Allowing access to variables
   FileSystem - Allowing access to the file system, mounting of CIFS shares, ...
   Certificate - Currently Windows-only, allowing access to certificate stores
   Registry - Windows-only, allowing access to the Windows registry
   WSMan - Currently Windows-only, allowing access to WinRM configuration via WSMan
#>
Get-PSProvider

# cmdlets that work with providers
Get-Command -Noun Location, Item, ItemProperty, ChildItem, Content, Path

# Providers usually automatically mount their drives
Get-PSDrive

# Navigate the file system
Set-Location -Path $home

# The File and FollowSymlink parameters are only available when the file system provider is used
Get-ChildItem -Recurse -File -FollowSymlink
Get-ChildItem -Path env: # Only default parameters here

# Globbing is supported regardless of the operating system and provider
Get-ChildItem -Path /etc/*ssh*/*config
Get-ChildItem -Path C:\Windows\*.dll
Get-ChildItem -Path env:\*module*

# Take a look at the syntax for easier operations
# e.g. Creating multiple items from an array
$folders = @(
    "$home/test1"
    "$home/test2/sub1/sub2"
    "$home/test3"
)
New-Item -Path $folders -ItemType Directory -Force

# or creating a file in multiple locations
New-Item -Path $folders -Name 'someconfig.ini' -ItemType File -Value 'key = value'

# Wondering about the output when comparing to your OS management tools?
New-Item $home\hidden\testfile,$home\hidden\.hiddentestfile -ItemType File -Force
$(Get-Item $home\hidden\.hiddentestfile -Force).Attributes = [System.IO.FileAttributes]::Hidden
Get-ChildItem -Path $home\hidden # .hiddentestfile will not appear
Get-ChildItem -Path $home\hidden -Hidden # Only shows the hidden file
Get-ChildItem -Path $home\hidden -Force # Retrieves all files

# The Include and Exclude parameters can be useful filters
# / on Windows defaults to system drive
# Enables more complex filters than the Filter parameter
Get-ChildItem -Path $pshome -Recurse -Include *.dll,*.json -Exclude deps.ps1

# This works for other Provider cmdlets as well
Get-Content -Path $pshome/Modules/PackageManagement/* -Include *.psm1
Set-Content -Path $home\testfile -Value "File content`nMultiple lines"
Add-Content -Path $home\testfile -Value 'Another new line'
Get-Content -Path $home\testfile

# The file system provider is one that allows mounting more provider drives
New-PSDrive -Name onlyInShell -Root \\PACKT-DC1\NETLOGON -PSProvider FileSystem -Credential ([pscredential]::new('contoso\Install', ('Somepass1' |ConvertTo-SecureString -AsPlaintext -Force)))
Get-ChildItem -Path onlyInShell:
Remove-PSDrive -Name onlyInShell
