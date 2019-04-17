throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# PowerShell Core can run code as jobs. These can be used also for sort-of parallelization
# Keep in mind that this is not proper parallelization but merely gives the appearance of it
Get-Command -Noun Job

# To get started, try a simple job
Start-Job -Name MyJob -ScriptBlock { Get-Process }

# These jobs will be executed and can be collected at any time. The results
# are lost as soon as you exit your session
Get-Job -Name MyJob

# The job should indicate that is is Completed and that is has more data
# Retrieve data by using Receive-Job
Get-Job -Name myJob | Receive-Job -Keep

# The Keep parameter keeps your results stored for now. If you want to retrieve the
# results and remove the job, you can add the AutoRemove parameter
Get-Job -Name MyJob | Receive-Job -AutoRemoveJob -Wait
Get-Job -Name myJob # Error

# To achieve the illusion of parallel processing, you can build a simple job scheduler
$throttleLimit = 10
$collection    = 1..100

foreach ($item in $collection)
{
    $doneCount = (Get-Job -Name Queue* | Where-Object State -in @("Completed", "Failed")).Count
    $progress = ($doneCount / $collection.Count) * 100

    # careful with progress bars - on the VSCode console hosts, they will not work
    Write-Progress -Activity 'Doing things' -Status "Working" -CurrentOperation "($($DoneCount)/$($collection.Count))"  -Id 1 -PercentComplete $progress

    $running = @(Get-Job -Name Queue* | Where-Object { $_.State -eq 'Running' })
    if ($running.Count -ge $throttleLimit)
    {
        $running | Wait-Job -Any | Out-Null
    }
    $null = Start-Job -Name "Queue$item" -ScriptBlock {Start-Sleep -Seconds 1}
}

Get-Job -Name Queue* | Wait-Job # Wait for remaining jobs

# PowerShell Core actually defines another operator, the ampersand
$job = Start-Sleep -Seconds 30 &
$job | Wait-Job
