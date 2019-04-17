throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# First cmdlets

# Returns well-structured data, follows a structured naming convention
Get-Process

# External commands return just text
# Filtering depends on the command, parameters are not obvious
if ($IsLinux)
{
    ps
}
else
{
    tasklist
}

# Working with dates is extremely easy in PowerShell
Get-Date

# Again, text is returned. The usability of the data
# depends very much on the command's parameters and
# formatting capabilities
if ($IsLinux)
{
    date
}
else
{
    cmd /c 'date /t'    
}

# Filtering in PowerShell is extremely easy
Get-Process | Where-Object -Property WorkingSet -gt 100MB

# It is not that easy on the command line!
# Filtering depends on the command again.
if ($IsLinux)
{
    # Linux does not really do much to help you with that
    # awk uses the field separator (-F) " ", meaning the string is split
    # at whitespaces
    # Comparing the fifth element returned (note here that the list does not start with 0)
    # to the actual value.
    ps -aux | awk -F" " '$5 > 102400'
}
else
{
    # Windows is nearly as bad.
    # The filter parameter FI requires a value in kb
    # This requires you to look at the help
    tasklist /FI "MEMUSAGE gt 102400"
}

# Things you can do only in PowerShell: Run a simulation

# Even with the force parameter set, WhatIf ensures that the
# shutdown is only simulated
Stop-Computer -Force -WhatIf