throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Let's get familiar with variables
Get-Help about_Variables

# With that in mind, let's grab the current date
$timestamp = Get-Date
$processes = Get-Process
$nothing = $null

# Explore your new variables
# Executing your variable will simply place it on the output again
$timestamp

# With tab completion and a technique called dot-notation
# you can explore your variable further

# Objects in the output can contain properties
$timestamp.DayOfWeek

# and methods.
$timestamp.IsDaylightSavingTime()

# Properties and methods are also available for lists of objects
$processes.Name
$processes.Refresh()

# Be careful with empty variables
# Properties will be $null as well
$nothing.SomeProperty

# Method calls will throw an error
$nothing.SomeMethod()

# Be extra careful with cmdlets like Get-ChildItem!
# The default path is the current working directory
Get-ChildItem -Path $nothing -File | Remove-Item -WhatIf

# Accessing properties and methods while discarding the
# original object requires expressions, $( )
$(Get-TimeZone).BaseUtcOffset
$(Get-Process).ToString()
