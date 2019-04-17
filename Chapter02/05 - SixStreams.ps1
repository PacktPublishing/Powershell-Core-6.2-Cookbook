throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

<#
PowerShell does not work with traditional integer exit codes.
Instead, we are using different streams to convey success and errors.
1 Output
2 Error
3 Warning
4 Verbose
5 Debug
6 Information
#>

# This command will return both an error and one output object
Get-Item -Path $home,'doesnotexist'

# This command usually returns nothing. The Verbose parameter however enables another stream.
Remove-Item -Path $(New-TemporaryFile) -Verbose

<#
  The Verbose parameter is part of the so-called Common Parameters. To learn more, have a look
  at Get-Help about_CommonParameters.
  *Action - How will the cmdlet behave, when an object is written to the stream, e.g. ErrorAction
  *Variable - In which variable will the objects of the given stream be stored?
  Verbose,Debug - Additional streams that can be activated
#>

# The ErrorAction determines that the cmdlet will suppress its errors, while still logging them.
# OutVariable stores the output and ErrorVariable the errors, while still allowing both streams
# to exist longer.
Get-Item -Path $home,'doesnotexist' -ErrorAction SilentlyContinue -OutVariable file -ErrorVariable itemError
$file.FullName # Yes, it's your file
$itemError.Exception.GetType().FullName # This sure looks like your error

# The new Information stream is pretty useful, although it is still rarely used in scripts
function Get-AllTheInfo
{
    [CmdletBinding()]param()

    Write-Information -MessageData $(Get-Date) -Tags Dev,CIPipelineBuild
    if ($(Get-Date).DayOfWeek -notin 'Saturday','Sunday')
    {
        Write-Information -MessageData "Get to work, you slacker!" -Tags Encouragement,Automation
    }
}

# Like the Verbose and Debug streams, Information is not visible by default
# Working with the information is much improved by cmdlets that actually process the tags
Get-AllTheInfo -InformationVariable infos
Get-AllTheInfo -InformationAction Continue

# Information can be filtered and processed, allowing more sophisticated messages in your scripts
$infos | Where-Object -Property Tags -contains 'CIPipelineBuild'

# The preference variables control cmdlet behavior for an entire session
$ErrorActionPreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'
Import-Module -Name Microsoft.PowerShell.Management -Force
Get-Item -Path '/somewhere/over/the/rainbow'

<#
  While not formally common parameters, there are additional
  Risk Mitigation parameters: WhatIf and Confirm
#>
Remove-Item -Path (New-TemporaryFile) -Confirm
Remove-Item -Path (New-TemporaryFile) -WhatIf

# WhatIf and Confirm are governed by automatic variables as well
$WhatIfPreference = $true
New-TemporaryFile

$WhatIfPreference = $false
$ConfirmPreference = 'Low' # None,Low,Medium,High
New-TemporaryFile

# Use the streams to your advantage
Write-Warning -Message 'A warning looks like this'
Write-Error -Message 'While an error looks like this'
Write-Verbose -Message 'Verbose, Debug and Information are hidden by default'

# Advanced: Add WhatIf and Confirm to your cmdlet
function Test-RiskMitigation
{
    [CmdletBinding(SupportsShouldProcess)]
    param ( )

    if ($PSCmdlet.ShouldProcess('Target object, here: The evidence','Action, here: Shred'))
    {
        Write-Host -ForegroundColor Red -Object 'Shredding evidence...'
    }
}

Test-RiskMitigation -WhatIf
Test-RiskMitigation