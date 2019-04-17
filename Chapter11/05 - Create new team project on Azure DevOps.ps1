throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# With an access token, you can get started
$accessTokenString = ''

# We are crafting an authorization header that bears your token
$tokenString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f '', $accessTokenString)))
$authHeader = ("Basic {0}" -f $tokenString)

# Azure DevOps works with team projects. Try listing some
$baseuri = 'https://dev.azure.com/<YOURUSERNAME!>'
$headers = @{ Authorization = $authHeader }

# To create a new project, POST is used.
# First of all, we need to retrieve the possible process templates
$templates = (Invoke-RestMethod -Method Get -Uri "$baseuri/_apis/process/processes?api-version=5.0" -UseBasicParsing -Headers $headers).value
$templates | Format-Table Name, ID

# Again, a hashtable contains the arguments
$jsonBody = @{    
    name         = "PowerShellCookBook"
    description  = "The cook book repository!"
    capabilities = @{
        versioncontrol = @{
            sourceControlType = "Git"
        }
        processTemplate = @{
            templateTypeId  = $templates | Where Name -eq Agile | Select -Expand id
        }
    }          
} | ConvertTo-Json

# To use a specific API version, the version can be included in the URI
$response = Invoke-RestMethod -Method Post -Uri "$baseuri/_apis/projects?api-version=5.0" -UseBasicParsing -Headers $headers -Body $jsonBody -ContentType application/json
$projectIsCreating = (Invoke-RestMethod -Uri $response.Url -Headers $headers -UseBasicParsing -Method Get).Status -ne 'succeeded'

# Wait a little for the project to get created
while ($projectIsCreating)
{
    Start-Sleep -Milliseconds 250
    $projectIsCreating = (Invoke-RestMethod -Uri $response.Url -Headers $headers -UseBasicParsing -Method Get).Status -ne 'succeeded'
}

# Now you can retrieve it, too
Invoke-RestMethod -Method Get -Uri "$baseuri/_apis/projects/PowerShellCookBook?api-version=5.0" -UseBasicParsing -Headers $headers

# To push code, you need to set up git with a remote URL. So, where is it?
$repo = (Invoke-RestMethod -Method Get -Uri "$baseuri/PowerShellCookBook/_apis/git/repositories?api-version=5.0" -UseBasicParsing -Headers $headers).value

# Test it ;)
New-Item -ItemType File -Path .\newrepo\README.md -Value 'Here be dragons.' -Force
Set-Location -Path .\newrepo
git init
git remote add origin $repo.remoteurl
git add .
git commit -m 'initial commit'
git push -u origin --all
