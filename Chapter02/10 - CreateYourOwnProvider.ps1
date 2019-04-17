if ((Split-Path $pwd.Path -Leaf) -ne 'ch02')
{
    Set-Location .\ch02
}

throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Install SHiPS
Install-Module -Name SHiPS -Force -Scope CurrentUser

# Create a new file with the following content to begin with.
# The using statement imports the namespace Microsoft.PowerShell.Ships from the module SHiPS
# This makes it easier for you to access classes in that namespace only by their name.
# The using statement is not required.
'using namespace Microsoft.PowerShell.SHiPS' | Set-Content .\MyShipsProvider.psm1

# SHiPS providers are based around PowerShell classes.
# To create a new directory, or container, your class needs to
# inherit from the class ShipsDirectory
class MyContainerType : Microsoft.PowerShell.SHiPS.SHiPSDirectory
{
    # Your new container should now implement the function GetChildItem() at the very least.
    # In order to actually return child items, your container needs content!
    MyContainerType([string]$name): base($name)
    {
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $obj += [MyFirstLeafType]::new();
        return $obj;
    }
}

# Leafs are the child items of your containers that cannot contain any more items themselves.
# Containers are still allowed to contain more containers though.
class MyFirstContainerType : Microsoft.PowerShell.SHiPS.SHiPSDirectory
{
    MyFirstContainerType([string]$name): base($name)
    {
    }
}

class MyFirstLeafType : Microsoft.PowerShell.SHiPS.SHiPSLeaf
{
    MyFirstLeafType () : base ("MyFirstLeafType")
    {
    }

    [string]$LeafProperty = 'Value'
    [int]$LeafLength = 42
    [datetime]$LeafDate = $(Get-Date)
}

# Take a look at the sample code
psedit .\ShipsProvider.psm1

# In order to mount your provider drive, you can simply use New-PSDrive
Import-Module -Name Ships, .\ShipsProvider -Force

New-PSDrive -Name MyOwnDrive -PSProvider SHiPS -Root "ShipsProvider#MyContainerType"

# Now you can use the item cmdlets at your leisure
Get-ChildItem -Path MyOwnDrive:\MyFirstContainerType
Get-ChildItem -Path MyOwnDrive: -Recurse

# Advanced: You can use Dynamic Parameters for Get-ChildItem as well
# Think of parameters like -File, -CodeSigningCertificate and others
class MyDynamicParameter
{
    [Parameter()]
    [switch]
    $DispenseCandy
}

# This parameter would enable the following
Import-Module -Name SHiPS,.\ShipsProviderAdvanced -Force
New-PSDrive -Name MyOwnDrive -PSProvider SHiPS -Root ShipsProviderAdvanced#MyContainerType
Get-ChildItem MyOwnDrive: -Recurse -DispenseCandy

# You can configure your parameter as necessary, e.g. adding a ValidateSet attribute
# or using different data types
class MySecondDynamicParameter
{
    [Parameter()]
    [ValidateSet('Red', 'Yellow', 'Green')]
    [string]
    $ProjectStatus
}

# Now, in your ShipsDirectory, you can use the second method implementation
# GetChildItemDynamicParameters()
class SpecialDirectory : Microsoft.PowerShell.Ships.SHiPSDirectory
{

    # Return your dynamic parameters
    [object] GetChildItemDynamicParameters()
    {
        return [MyDynamicParameter]::new()
    }

    # And test for them in your code
    [object[]] GetChildItem()
    {
        $dp = $this.ProviderContext.DynamicParameters -as [MyDynamicParameter]

        if ($dp.DispenseCandy)
        {
            Write-Host -ForegroundColor Magenta -BackgroundColor White -Object 'Candy time!'
            return 'Sweet.'
        }

        return 'No candy selected.'
    }
}
