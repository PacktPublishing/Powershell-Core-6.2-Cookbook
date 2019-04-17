throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Many functions support an out parameter like the conversion methods
# Do not be confused by the output - [ref] just indicates that a reference is passed
[bool] | Get-Member -Static -Name TryParse
$parsedValue = $null
$parseSuccess = [bool]::TryParse('False', [ref]$parsedValue)
Write-Host "Parsing 'False' to boolean was successful: $parsesuccess. The parsed boolean is $parsedValue"

# [ref] in PowerShell
function ByReference
{
    param(
        [ref]
        $ReferenceObject
    )

    $ReferenceObject.Value = 42
}

$valueType = 7
ByReference -ReferenceObject ([ref]$valueType)
$valueType.GetType() # Still a value type, but the value has been changed

# Delegates
# Delegate methods like Actions and Funcs are often used in C#, but you can also use them in PowerShell
# The LINQ Where method in C# looks like this:
# processes.Where(proc => proc.WorkingSet64 > 150*1024);

# The proper type cast is important. The output of Get-Process is normally an Object array!
[System.Diagnostics.Process[]]$procs = Get-Process

# The delegate type that LINQ expects is a Func. This type expects two
# parameters, a Type parameter indicating the source data type, e.g. Process as well as a predicate, the filter
[Func[System.Diagnostics.Process,bool]] $delegate = { param($proc); return $proc.WorkingSet64 -gt 150mb }
[Linq.Enumerable]::Where($procs, $delegate)

# The same delegate can be used with e.g. First, which filters like where and returns the first object
# matching the filter
[Linq.Enumerable]::First($procs, $delegate)
