throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Azure DevOps (and Azure DevOps Server) can be automated beautifully
# There are some steps you need to take though

# With an access token, you can get started
$accessTokenString = ''

# We are crafting an authorization header that bears your token
$tokenString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f '', $accessTokenString)))
$authHeader = ("Basic {0}" -f $tokenString)

# Azure DevOps works with team projects. Try listing some
$baseuri = 'https://dev.azure.com/<YOURUSERNAME!>'
$headers = @{ Authorization = $authHeader }

$projects = Invoke-RestMethod -Method Get -Uri "$baseuri/_apis/projects" -UseBasicParsing -Headers $headers
$projects.value # Contains your projects, if any

# You can play around with that easily
$projects.value | Format-Table Name, Visibility, State

# To get a specific project, you can supply the project name in the request URI
Invoke-RestMethod -Method Get -Uri "$baseuri/_apis/projects/PowerShellCookBook?api-version=5.0" -UseBasicParsing -Headers $headers

# To push code, you need to set up git with a remote URL. So, where is it?
# You can use he git/repositories route to retrieve the repos for a project
$repo = (Invoke-RestMethod -Method Get -Uri "$baseuri/PowerShellCookBook/_apis/git/repositories?api-version=5.0" -UseBasicParsing -Headers $headers).value

# Test it ;)
New-Item -ItemType File -Path .\newrepo\README.md -Value 'Here be dragons.' -Force
Set-Location -Path .\newrepo
git init
git remote add origin $repo.remoteurl
git add .
git commit -m 'initial commit'
git push -u origin --all
