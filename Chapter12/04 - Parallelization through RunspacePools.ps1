throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# There are many modules using runspaces. We will use AutomatedLab.Common
Install-Module AutomatedLab.Common -Scope CurrentUser

# Runspace pools can be used for throttling
$pool = New-RunspacePool -ThrottleLimit 10

# The .NET type RunspacePool will queue new jobs automatically.
# The jobs are potentially CPU-intensive or time-consuming tasks
$jobs = Get-ChildItem -Recurse -File -Path $PSHOME | Foreach-Object {
    Start-RunspaceJob -ScriptBlock {
        param ( $Path )
        Get-FileHash @PSBoundParameters
    } -Argument $_.FullName -RunspacePool $pool
}

# The hash calculation could take longer
$jobs | Wait-RunspaceJob

# By default, Wait-RunspaceJob has no output. With PassThru you will get the
# jobs back
$jobs | Wait-RunspaceJob -PassThru

# To receive the job results, use Receive-RunspaceJob. The results will be kept
$jobs | Receive-RunspaceJob

# When you are done, remove them
$pool | Remove-RunspacePool

# Compare the time it takes
$start = Get-Date
$pool = New-RunspacePool -ThrottleLimit 12
Get-ChildItem -Recurse -File -Path $PSHOME | Foreach-Object {
    Start-RunspaceJob -ScriptBlock {
        param ( $Path )
        Get-FileHash @PSBoundParameters
    } -Argument $_.FullName -RunspacePool $pool
} | Wait-RunspaceJob
$pool | Remove-RunspacePool
(Get-Date) - $start

$start = Get-Date
Get-ChildItem -Recurse -File -Path $PSHOME | Get-FileHash
(Get-Date) - $start