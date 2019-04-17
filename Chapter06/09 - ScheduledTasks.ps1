throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# List all registered tasks
Get-ScheduledTask

# Filter by name or path
Get-ScheduledTask -TaskName *Cache*
Get-ScheduledTask -TaskPath \Microsoft\Windows\Wininet\

# Remoting is achieved with CIM
Get-ScheduledTask -TaskName *Cache* -CimSession (New-CimSession -ComputerName host1)

# A task is comprised of multiple components
# The action to execute
$action = New-ScheduledTaskAction -Execute pwsh -Argument '-Command " & {"It is now $(Get-Date) in task land"}'

# A trigger, e.g. a date
$trigger = New-ScheduledTaskTrigger -At (Get-Date).AddMinutes(5) -Once

# Maybe some settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -RunOnlyIfNetworkAvailable

# and of course the task
$task = New-ScheduledTask -Action $action -Description "Says hello" -Trigger $trigger -Settings $settings

# All components can be registered
$registeredTask = $task | Register-ScheduledTask -TaskName MyTask -TaskPath \MyTasks\

# The task cmdlets can be used to interact with the task
$registeredTask | Start-ScheduledTask
$registeredTask | Stop-ScheduledTask

# Finally, to unregister a task
$registeredTask | Unregister-ScheduledTask