throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Chapter 04 showed you the where method. Let's examine it futher

# The arrays help topic contains valuable information
# ForEach and Where are methods for lists
# See also: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_arrays?view=powershell-6#where
Get-Help about_arrays

<#
The syntax for Where looks like this:
Where(scriptblock expression[, WhereOperatorSelectionMode mode
                            [, int numberToReturn]])
#>
$filterScript = {$_.WorkingSet -gt 150MB}

# The filter script is a mandatory parameter
(Get-Process).Where($filterScript)

# What about the selection mode?
[enum]::GetNames([System.Management.Automation.WhereOperatorSelectionMode])
<# Pretty extensive list:
Default:   Standard filterscript application
First:     Get the first n matching elements, where n is specified in numberToReturn
Last:      Get the last n matching elements, where n is specified in numberToReturn
SkipUntil: Skip all elements until a match is found, then begin output
Until:     Output all elements until a match is found, the inversion of SkipUntil
Split:     Split the list in all matching elements and the rest
#>

# First
(Get-Process).Where($filterScript, 'First', 2)

# Last
(Get-Process).Where($filterScript, 'Last', 2)

# SkipUntil
# Notice here that after the first match is found, the filter script is not applied any more!
(Get-Process).Where($filterScript, 'SkipUntil')

# Until
# Notice here that after the first match is found, the filter script is not applied any more!
(Get-Process).Where($filterScript, 'Until')

# Split
# My personal favorite :)
Import-Module -PSSession (New-PSSession -ComputerName PACKT-DC1 -Credential contoso\Install) -Name ActiveDirectory
$online, $offline = (Get-ADComputer -Filter *).Where({Test-Connection $_.DnsHostName -Count 1 -Quiet}, 'Split')

Invoke-Command -ComputerName $online.DnsHostName -Credential contoso\Install -ScriptBlock { 'We love the Where() method!'}