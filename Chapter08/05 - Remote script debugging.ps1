throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Debugging remote scripts can be extremely important, depending on your work ethics
$remotescript = {
    # The typical Friday afternoon scripter kicks off a "quick script" on "some servers"
    # at 4:55 pm and then leaves like the Road Runner
    $unsuspectingHosts = Get-ADComputer -Filter * | Select -Expand DnsHostName

    Write-Host -Fore Red "Doing some 'quick' tasks on $($unsuspectingHosts.Count) hosts - generating nooo tickets ♥"

    # Why, I need a loop
    $someCondition = $true
    while ($someCondition)
    {
        Start-Sleep -Seconds 1

        if ((Get-Date).DayOfWeek -eq 'Sunday')
        {
            $someCondition = $false
        }

        # not Sunday yet? Time for scripting
        $someData = Get-CimInstance Win32_OperatingSystem

        # Whoops... We are now looping for a very long time - unless you are reading this on Sundays
    }
}

# The script is started, and your best friend leaves
Invoke-Command -ComputerName PACKT-HV1 -Credential contoso\Install -ScriptBlock $remotescript -InDisconnectedSession

# What to do, what to do... The first users have called because their machine behaves wonky
# Since PowerShell 5, we can debug other users' processes

# First, open a new session that you will be debugging in
Enter-PSSession -ComputerName PACKT-HV1 -Credential contoso\Install

# Next, list all remote processes
Get-PSHostProcessInfo -Name wsmprovhost

# We need to debug a process that is not our own, so
$foreignProcess = Get-PSHostProcessInfo -Name wsmprovhost | Where-Object ProcessId -ne $pid

# Next, we can go further down the rabbit hole
Enter-PSHostProcess -Id $foreignProcess.ProcessId

# Notice how the prompt has changed. Next, we need to see the runspaces
Get-Runspace

# The runspace that is busy is yours - it was executing Get-Runspace
$foreignRunspace = Get-Runspace | Where-Object -Property RunspaceAvailability -ne 'Busy'
Get-RunspaceDebug -RunspaceId $foreignRunspace.Id

# The final step
Debug-Runspace -Runspace $foreignRunspace

# When finished with debugging, either Detach (script continues to run) or quit (Script exits)
quit

Exit-PSHostProcess
Exit-PSSession