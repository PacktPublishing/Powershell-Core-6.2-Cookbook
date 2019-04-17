throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Like Azure Resource Groups, Google Cloud Projects collect resources
# and can be used for billing purposes
Get-GcpProject

# There are no other interactions possible with PowerShell Cmdlets. We can use REST though
$baseUri = 'https://cloudresourcemanager.googleapis.com/v1/projects'
$header = @{
    Authorization = "Bearer $(gcloud.cmd auth application-default print-access-token)"
}

# List all projects (Get-GcpProject)
$projects = (Invoke-RestMethod -Method Get -Uri $baseUri -Headers $header).Projects

# Grab a single project
Invoke-RestMethod -Method Get -Uri "$baseuri/$($projects[0].projectId)" -Headers $header

# Create a new project
$body = @{
    projectId = 'uid-of-project'
    name      = 'friendly-name'
    labels    = @{
        owner      = $env:USERNAME.ToLower()
        costcenter = '100100101'
    }
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri $baseUri -Body $body -ContentType application/json -Headers $header

# And delete
Invoke-RestMethod -Method Delete -Uri "$baseUri/uid-of-project" -Headers $header