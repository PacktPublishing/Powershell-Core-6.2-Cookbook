throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Where Azure has JSON templates Google uses YAML
# PowerShell knows both and we work with a hashtable anyway ;)

# Try to list all templates first
Get-GceInstanceTemplate

# You can register your templates with PowerShell
Get-GcpProject


$image = Get-GceImage -Family "windows-2016"
$disks = @(
    New-GceAttachedDiskConfig -SourceImage $image -Name os -AutoDelete -Boot
    New-GceAttachedDiskConfig -SourceImage $image -Name d1 -AutoDelete
    New-GceAttachedDiskConfig -SourceImage $image -Name d2 -AutoDelete
)

$templateParameter = @{
    Name        = 'vm-conf1' 
    Project     = 'jhptestproject' 
    MachineType = 'n1-standard-1' 
    Description = 'Single VM template' 
    Region      = 'europe-west3' 
    Disk        = $disks
    Network     = 'default'
}
Add-GceInstanceTemplate @templateParameter

# Retrieve the template
Get-GceInstanceTemplate -Name vm-conf1

# Deploy the template
$tmpl = Get-GceInstanceTemplate -Name vm-conf1
Add-GceManagedInstanceGroup -InstanceTemplate $tmpl -Name manni -TargetSize 4 -Zone europe-west3-a

# This should deploy an instance group with 4 vms
Get-GceManagedInstanceGroup

# Clean up again
Remove-GceManagedInstanceGroup -Name manni -Zone europe-west3-a

$project = Get-GcpProject -Name testproject
$template = @{
    "name"        = "vm-conf2"
    "description" = ""
    "properties"  = @{
        "machineType"       = "n1-standard-1"
        "metadata"          = @{
            
            "items" = @()
        }
        "tags"              = @{
            "items" = @(
                "https-server"
            )
        }
        "disks"             = @(
            @{
                
                "type"             = "PERSISTENT"
                "boot"             = $true
                "mode"             = "READ_WRITE"
                "autoDelete"       = $true
                "deviceName"       = "vm-conf2"
                "initializeParams" = @{
                    "sourceImage" = "projects/centos-cloud/global/images/centos-7-v20190326"
                    "diskType"    = "pd-standard"
                    "diskSizeGb"  = 10
                }
            }
            @{
                
                "mode"             = "READ_WRITE"
                "autoDelete"       = $false
                "type"             = "PERSISTENT"
                "initializeParams" = @{
                    "diskType"   = "pd-standard"
                    "diskSizeGb" = 500
                }
            }
        )
        "canIpForward"      = $false
        "networkInterfaces" = @(
            @{
                
                "network"       = "projects/$($project.ProjectId)/global/networks/default"
                "accessConfigs" = @(
                    @{
                        
                        "name"        = "External NAT"
                        "type"        = "ONE_TO_ONE_NAT"
                        "networkTier" = "PREMIUM"
                    }
                )
                "aliasIpRanges" = @()
            }
        )
        "labels"            = @{ }
        "scheduling"        = @{
            "preemptible"       = $false
            "onHostMaintenance" = "MIGRATE"
            "automaticRestart"  = $true
            "nodeAffinities"    = @()
        }
        "serviceAccounts"   = @(
            @{
                "email"  = "113741130683-compute@developer.gserviceaccount.com"
                "scopes" = @(
                    "https://www.googleapis.com/auth/devstorage.read_only"
                    "https://www.googleapis.com/auth/logging.write"
                    "https://www.googleapis.com/auth/monitoring.write"
                    "https://www.googleapis.com/auth/servicecontrol"
                    "https://www.googleapis.com/auth/service.management.readonly"
                    "https://www.googleapis.com/auth/trace.append"
                )
            }
        )
    }
} | ConvertTo-Json -Depth 42
$head = @{Authorization = "Bearer $(gcloud.cmd auth application-default print-access-token)" }

$tmp = Invoke-RestMethod -Method post -uri https://www.googleapis.com/compute/v1/projects/jhptestproject/global/instanceTemplates -Headers $head -body $template -contenttype application/json