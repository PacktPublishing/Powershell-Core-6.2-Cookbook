throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

#Working with cmdlets like Group-Object as well as hashtables and dictionaries
#the reader will learn when to use those structures to their advantage

# Hashtables are an important concept in PowerShell
# one reason for this is SPEED

# The index of a hashtable is the Key
$hashtable = @{ }
Get-ADUser -Filter * | ForEach-Object {$hashtable.Add($_.SamAccountName, $_)}

# Accessing an element via the index is very fast
# Execute this line by line
$foundYou = $hashtable.elbarto # Total milliseconds: 0.4 !
(Get-History -Count 1).Duration

# While looking for a value is mega-slow
# Execute this line by line
$hashtable.ContainsValue($foundYou) # Total milliseconds: 21.6 !
(Get-History -Count 1).Duration

# You already saw Group-Object with the AsHashtable parameter.
$allTheEvents = Get-WinEvent -LogName System | Group-Object -Property LevelDisplayName -AsHashTable -AsString

# Again, access is easier and more predictable
# Filtering is not necessary
$allTheEvents.Warning

# You could also group by ID, which might also be pretty useful
$allTheEvents = Get-WinEvent -LogName Security | Group-Object -Property EventID

# Despite appearances, the key is of course still not like a 0-based array index
$allTheEvents.4624

# By the way: You can also create proper Dictionaries!
# That way you can ensure that keys and values are always of the correct type
$dictionary = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,System.Diagnostics.Process]'

# This dictionary uses a string key and a Process value
Get-Process | foreach {$dictionary[$_.ProcessName] = $_} # never mind the duplicates...
$dictionary.pwsh # Super fast access again

# What happens now when wrong key-value pairs are used?
$dictionary[(Get-Date)] = Get-Process -Id $pid # No problem so far. (Get-Date) is converted to a string
$dictionary.SomeProcess = Get-Item .           # Terminates.