# Pipeline input can be achieved quite simply with the Input variable
# As an alternative, you can use $_ and $PSItem

# Without a process block, pipeline input is not what you would expect (it fails)
function Test-PipelineInput
{
    Get-Item $Input
}

'/', $home, $PSHOME | Test-PipelineInput

# To really make use of the pipeline, at least a process block is mandatory
function Test-PipelineInput
{
    process
    {
        # The process block is mandatory for pipeline input.
        # The variable input enumerates all objects in the pipeline
        Write-Host "
        `$_ is $_
        `$PSItem is $PSItem
        `$Input is $Input
        "        
    }
}

'/' | Test-PipelineInput

# With Begin and End blocks
function Test-PipelineInput
{
    begin
    {
        # The optional begin block at this point only sees an empty $Input variable
        Write-Host "Starting with processing"
    }

    process
    {
        Get-Item $Input
    }

    end
    {
        # The optional end block also cannot use $Input
        Write-Host "Processing finished"
    }
}

'/', $Home, $PSHOME | Test-PipelineInput

# In order to enable pipeline input, you have to decide if you are using
# ByValue (entire objects) or ByPropertyName for parameters
function Test-PipelineByValue
{
    # While the cmdlet binding attribute is not necessary, it is one component
    # that lets functions behave like cmdlets
    [CmdletBinding()]
    param
    (
        # Each parameter taking values from the pipeline needs to be decorated
        # with a parameter attribute
        [Parameter(ValueFromPipeline)]
        [string[]]
        $Path
    )

    begin
    {
        # The begin block is entirely optional and like ForEach-Object
        # is executed before the pipeline is being processed
        # It can for example be used to initialise something
        $resultCollection = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process
    {
        $resultCollection.Add((Get-Item @PSBoundParameters))
    }

    end
    {
        # Anything not consumed in either script block is placed on the output
        $resultCollection
    }
}

# Both ways work fine
'/', $Home, $PSHOME | Test-PipelineByValue
Test-PipelineByValue -Path '/', $Home, $PSHOME

# Enabling input by property name is just another parameter for the parameter attribute
function Test-PipelineByPropertyName
{
    # While the cmdlet binding attribute is not necessary, it is one component
    # that lets functions behave like cmdlets
    [CmdletBinding()]
    param
    (
        # Each parameter taking values from the pipeline needs to be decorated
        # with a parameter attribute
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path
    )

    begin
    {
        # The begin block is entirely optional and like ForEach-Object
        # is executed before the pipeline is being processed
        # It can for example be used to initialise something
        $resultCollection = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process
    {
        $resultCollection.Add((Get-Item @PSBoundParameters))
    }

    end
    {
        # Anything not consumed in either script block is placed on the output
        $resultCollection
    }
}

Get-Process -Id $pid | Test-PipelineByPropertyName
Test-PipelineByPropertyName -Path '/', $Home, $PSHOME
