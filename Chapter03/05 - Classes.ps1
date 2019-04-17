if ((Split-Path $pwd.Path -Leaf) -ne 'ch03')
{
    Set-Location .\ch03
}

throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Compile and import C# code on the fly
Add-Type -Path '.\05 - ClassesDotNet.cs'

# Or save the compiled result for posterity
Add-Type -Path '.\05 - ClassesDotNet.cs' -OutputAssembly Device.dll
Add-Type -Path .\Device.dll

# Using PowerShell classes is easier and does not require formal .NET developer experience
enum DeviceType
{
    Mobile;
    Desktop;
    Server
}

class Device
{
    [string] $AssetTag;
    [DeviceType] $DeviceType;

    Device ([string] $assetTag, [DeviceType] $deviceType)
    {
        $this.AssetTag = $assetTag;
        $this.DeviceType = $deviceType;
    }

    [void] UpdateFromCmdb()
    {
    }

    static [Device] ImportFromCmdb()
    {
        return new Device("aabbcc");
    }
}

class Desktop : Device
{
    [string] $MainUser
    [System.Collections.Generic.List[string]] $AdditionalUsers

    Desktop([string] $assetTag, [string] $mainUser, [DeviceType] $deviceType) : base($assetTag, $deviceType)
    {
        $this.AdditionalUsers = New-Object -TypeName List[string]
        $this.MainUser = $mainUser;
    }

    [void] AddUser([string] $userName)
    {
        $this.AdditionalUsers.Add($userName);
    }
}

class Server : Device
{
    [ValidatePattern('(EMEA|APAC)_\w{2}_\w{3,5}')]
    [string] $Location
    [ValidateSet('dev.contoso.com','qa.contoso.com','contoso.com')]
    [string] $DomainName
    [bool] $IsDomainJoined # This property cannot be implemented like we intended it to. At the moment, PowerShell does not differenciate between fields and properties

    Server ([string] $assetTag, [string] $location, [string] $domainName, [DeviceType] $deviceType) : base($assetTag, $deviceType)
    {
        $this.Location = $location;
        $this.DomainName = $domainName;
    }

    hidden [bool] GetDomainJoinStatus()
    {
        if ([string]::IsNullOrEmpty($this.DomainName)) {return $false; }

        try
        {
            # With the ActiveDirectory libraries present, you can check for the domain 
            $currentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain();
            return $currentDomain.Name.Equals($this.DomainName);
        }
        catch [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException]
        {
            return $false;
        }

        return $true;
    }
}

# Instantiate classes with New-Object or the new() method
$desktop = New-Object -TypeName com.contoso.Desktop -ArgumentList 'AssetTag1234','Desktop'
$serverDotNet = New-Object -TypeName com.contoso.Server -ArgumentList 'AssetTag5678','EMEA_DE_DUE', 'contoso.com','Server'
$serverPsClass = [Server]::new('AssetTag5678','EMEA_DE_DUE', 'contoso.com','Server')

# Notice that our members look a bit different
# IsDomainJoined cannot be marked private for our PowerShell Class
$serverDotNet, $serverPsClass | Get-Member -Name IsDomainJoined

# While our .NET class does not show its private methods
# our PowerShell class cannot hide its hidden method any longer
$serverDotNet, $serverPsClass | Get-Member -Force -MemberType Methods