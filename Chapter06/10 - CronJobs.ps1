throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Again - no native cmdlets
Get-Command *ScheduledTask*

# Download the CronTab module from GitHub
$null = New-Item -ItemType Directory -Path /usr/local/share/powershell/Modules/CronTab -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri https://raw.githubusercontent.com/PowerShell/PowerShell/master/demos/crontab/CronTab/CronTab.psm1 -OutFile /usr/local/share/powershell/Modules/CronTab/CronTab.psm1

# The module can be imported directly. Let's have a look at the contents first
cat /usr/local/share/powershell/Modules/CronTab/CronTab.psm1

# Discover the contents
Get-Command -Module CronTab

# Let's see if there are existing jobs
Get-CronTab

# Get-Crontab displays the contents, Get-CronJob is a bit friendlier:
Get-CronJob

# Creating a new job is very easy
New-CronJob -Minute 5 -Hour * -DayOfMonth * -Command "$((Get-Process -Id $pid).Path) -Command '& {Add-Content -Value awesome -Path ~/taskfile}'"

# Since cron jobs don't have names like scheduled tasks, finding them might be a bit tricky
Get-CronJob | Where-Object -Property Command -like '*awesome*'
Get-CronJob | Where-Object -Property Minute -eq 5

# This is especially important when trying to remove a job
Get-CronJob | Where-Object -Property Command -like '*awesome*' | Remove-CronJob -WhatIf
Get-CronJob | Where-Object -Property Command -like '*awesome*' | Remove-CronJob -Confirm:$false