throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Starting off easy, we need to have a look at the syntax
# Every comparison is implemented not case-sensitive and case-sensitive
Get-Command Where-Object -Syntax

# We usually compare one single property to some value
# The syntax is very easy to comprehend if you just read it out loud
# from left to right:
# Get all processes where the property value of WorkingSet64 is greater than 100 megabyte
Get-Process | Where-Object -Property WorkingSet64 -gt 100mb

# Be careful with spelling mistakes: You will not notice them
# Length is misspelled, returning an empty result set
Get-ChildItem | Where-Object -Property Lenght -gt 1

# If you recall the syntax, only one property can compared at any given time
# To compare more properties or complex properties, you will need the FilterScript
Get-ChildItem -Path $home |
    Where-Object -FilterScript {
        # The filter script should return a boolean value
        $_.CreationTime.DayOfWeek -in 'Saturday','Sunday'
    }

# The Where method exclusively uses a scriptblock, but is a lot more
# flexible, and incidentally also faster
# The syntax is Where({ expression } [, mode [, numberToReturn]])
# where the mode can be First, Last, SkipUntil, Until, Split
(Get-Process).Where(
    {$_.WorkingSet64 -gt 150mb}
)

# Where + Select-Object
(Get-Process).Where(
    {$_.WorkingSet64 -gt 150mb}, 'First', 5
)

# The result can be returned in two variables if necessary
$matchingProcesses, $rest = (Get-Process).Where(
    {$_.WorkingSet64 -gt 150mb}, 'Split'
)
