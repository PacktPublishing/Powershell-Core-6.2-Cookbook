throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# After having sorted and filtered, objects are often selected
Get-Process |
    Sort-Object -Property WorkingSet64 |
    Select-Object -Last 5

# A handy way to display object property values for beginners is Select -First 1
# This only displays the properties of one object instead of hundreds
Get-Process | Select-Object -First 1 | Format-List *

# Using the Index parameter, you can also extract indices from collections
1..100 | Select-Object -Index 1,5,10
'1.10.122.27' -split '\.' | Select-Object -Index 3

# With the Skip parameter, you can skip elements in the output
# Combined with First or Last, Skip will skip elements from the start or end of a collection
1..10 | Select-Object -Skip 5

# Skip 5 from the bottom, select last remaining
1..10 | Select-Object -Skip 5 -Last 1
# Skip 5 from top, select first remaining
1..10 | Select-Object -Skip 5 -First 1

# The parameter SkipLast simply cuts off the last couple of elements off a list
# This behavior can also be achieved with -Skip n -Last n
1..10 | Select-Object -SkipLast 7
1..10 | Select-Object -Skip 7 -Last 100

# Select (like Sort) has a Unique parameter. Unlike other cmdlets, this is case-sensitive
'apple','Apple' | Select-Object -Unique