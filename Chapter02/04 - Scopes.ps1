throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# We always use scopes, even if we don't realize it
$outerScope = 'Variable outside function'

function Foo
{
    Write-Host $outerScope
    $outerScope = 'Variable inside function'
    Write-Host $outerScope
}

Foo
Write-Host $outerScope

<#
  By explicitly using scopes, you can alter the state of virtually any variable
  The following scopes are available. Inner scopes can access variables from outer scopes
  global: The outermost scope, i.e. your current session
  script: The scope of a script or module
  local: The scope inside a script block
  private: In any scope, hidden from child scopes
  using: This one is special.
#>
$outerScope = 'Variable outside function'
$private:invisible = 'Not visible in child scopes'

function Foo
{
    Write-Host $outerScope
    $script:outerScope = 'Variable inside function'
    $local:outerScope = 'Both can exist'
    Write-Host "Private variable content cannot be retrieved: $invisible"
    Write-Host $outerScope
}

Foo
Write-Host $outerScope

# The using scope has been introduced with Windows PowerShell 4 and can be used
# for read-access from within jobs or remote sessions
$processName = 'pwsh'
$credential = New-Object -TypeName pscredential -ArgumentList 'user',$('password' | ConvertTo-SecureString -AsPlainText -Force)
Start-Job -ScriptBlock { Get-Process -Name $processName} | Wait-Job | Receive-Job # Error
Start-Job -ScriptBlock { Get-Process -Name $using:processName} | Wait-Job | Receive-Job # Works
Start-Job -ScriptBlock { $($using:credential).GetNetworkCredential().Password } | Wait-Job | Receive-Job # Works as well
