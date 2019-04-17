class MyContainerType : Microsoft.PowerShell.Ships.SHiPSDirectory
{
    # Your new container should now implement the function GetChildItem() at the very least.
    # In order to actually return child items, your container needs content!
    MyContainerType([string]$name): base($name)
    {
    }

    [object[]] GetChildItem()
    {
        $obj =  @()
        $obj += [MyFirstLeafType]::new();
        $obj += [MyFirstContainerType]::new();
        return $obj;
    }
}

class MyFirstContainerType : Microsoft.PowerShell.Ships.SHiPSDirectory
{
    MyFirstContainerType () : base ("MyFirstContainerType")
    {
    }

    [object[]] GetChildItem()
    {
        $obj =  @()
        $obj += [MyFirstLeafType]::new();
        return $obj;
    }
}

# Leafs are the child items of your containers that cannot contain any more items themselves.
# Containers are still allowed to contain more containers though.
class MyFirstLeafType : Microsoft.PowerShell.Ships.SHiPSLeaf
{
    MyFirstLeafType () : base ("MyFirstLeafType")
    {
    }

    [string]$LeafProperty = 'Value'
    [int]$LeafLength = 42
    [datetime]$LeafDate = $(Get-Date)
}