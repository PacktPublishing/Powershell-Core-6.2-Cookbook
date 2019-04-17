throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

$folder = Get-Item -Path .

# Either pipe a collection of objects to get member
$folder | Get-Member

# or pass a single object to the parameter InputObject
Get-Member -InputObject $folder

# Filter the output a bit with the MemberType parameter
$folder | Get-Member -MemberType Properties

# Select only a subset of member with the Name parameter
$folder | Get-Member -Name FullName,Parent,*Time, Exists

# As long as an object exists on the output, you can deploy Get-Member
$folder.Parent | Get-Member

# Our $folder is apparently of the same datatype as its parent.
# This should not come as a surprise, since the parent is also a directory.
# You can see the type of any object with GetType()
$folder.GetType().FullName # System.IO.DirectoryInfo
$folder.Parent.GetType().FullName # System.IO.DirectoryInfo

# Everything is an object, really.
42 | Get-Member

# External applications will always return string arrays
# Whether it is Linux
mount | Get-Member
$(mount).GetType().FullName # System.Object[] - a list of strings, one for each line

# or Windows
ipconfig | Get-Member
$(ipconfig).GetType().FullName # System.Object[] - a list of strings, one for each line

# Are you missing the exit code of your external application? It is recorded automatically
$LASTEXITCODE

# The most basic classes that we use have so-called type accelerators
[bool] # System.Boolean, the boolean values 0,1,$false,$true
[int16] # Also referred to as short: 16bit integers
[int] # 32bit integers
[int64] # Also referred to as long: 64bit integers
[string] # A series of UTF16 code units or characters
[char] # A single UTF16 code unit or character
[datetime] # A timestamp
[timespan] # A timespan
[array] # A list of objects
[hashtable] # A collection of key-value-pairs

# Value types and reference types
# Vale types like integers are stored in the stack
$intA = 4
$intB = $intA
$intB = 42
$intA -eq 4 # still true

# Reference types like arrays are pointing to the heap
$arrayA = 1,2,3,4
$arrayB = $arrayA
$arrayB[0] = 'Value'
$arrayA[0] -eq 1 # This is now false! arrayA has been changed as well as arrayB
