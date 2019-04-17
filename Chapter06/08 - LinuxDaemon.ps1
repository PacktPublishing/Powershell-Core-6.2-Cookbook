throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

if ((Split-Path $pwd.Path -Leaf) -ne 'ch06')
{
    Set-Location ./ch06
}

# No service cmdlets yet
Get-Command -Noun Service

# The main reason is that there are different systems like systemd
man systemctl

# Systemd is an init system that is of course used for more than just services (daemons)
systemctl status sshd
service sshd status # deprecated with systemd

# We can still use PowerShell though
systemctl list-units --type service --no-pager

function Get-Service
{
    [CmdletBinding()]
    param
    (
        [string[]]
        $Name,

        [string]
        $ComputerName
    )

    $results = if ($ComputerName)
    {
        systemctl list-units --type service --no-pager -H $ComputerName
    }
    else
    {
        systemctl list-units --all --type service --no-pager
    }

    $services = foreach ($result in $results)
    {
        #UNIT LOAD ACTIVE SUB DESCRIPTION
        if ($result -match '(?<Name>\w+)\.service\s+(?<LoadedState>\w+)\s+(?<UnitStatus>\w+)\s+(?<Status>\w+)\s+(?<Description>\w[\w\s]*)')
        {
            $tmp = $Matches.Clone()
            $tmp.Remove(0)
            [pscustomobject]$tmp
        }
    }

    if ($Name)
    {
        Write-Verbose -Message "Applying like-filter for $Name"
        return $services | Where-Object -Property Name -like $Name
    }

    $services
}

# For example for formatting purposes
Get-Service | Format-Table -Property Status, Name, Description
Get-Service | Where-Object -Property Status -eq 'Running'

# Or sorting
Get-Service | Sort-Object -Property Name

# Or Grouping
Get-Service | Group-Object -Property Status

# Creating a new daemon requires the same basic components as a Windows service:
# Something to execute.
# Let's take the Polaris script from "Learn PowerShell Core"!
Get-Content ./LinuxDaemon/polaris.ps1

# We can create the service definition in PowerShell as well
# A here-string is perfect for that.
@"
[Unit]
Description=File storage web service

[Service]
ExecStart=$((Get-Process -Id $pid).Path) -File $((Resolve-Path -Path ./startpolaris.ps1).Path)

[Install]
WantedBy=multi-user.target
"@ | Set-Content /etc/systemd/system/polaris.service -Force

systemctl daemon-reload
systemctl start polaris

# This can as well be placed in a cmdlet like New-Service which generates and registers unit files
function New-Service
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $BinaryPathName,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [string]
        $Description,

        [string]
        $User = 'root',

        # one of systemctl list-units --type target --no-pager
        [string]
        $Target = 'multi-user'
    )

    @"
[Unit]
Description=$Description

[Service]
ExecStart=$BinaryPathName
User=$User

[Install]
WantedBy=$Target.target
"@ | Set-Content "/etc/systemd/system/$Name.service" -Force

# Execute daemon-reload to pick up new service file
systemctl daemon-reload

Get-Service -Name $Name
}
