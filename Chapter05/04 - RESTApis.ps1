throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# The Invoke-RestMethod cmdlets are useful for interacting with REST APIs
Get-Command -Name Invoke-RestMethod -Syntax

# Usually, REST APIs require authentication. This can be an API key to restrict access, or it can be credentials.
# Try accessing github's API without authentication
Invoke-RestMethod -Method Get -Uri 'https://api.github.com/user/repos' -ErrorVariable octoError

# Good thing we store our errors, right?
$errorResponse = $octoError.Message | ConvertFrom-Json

# Read up on that API ;)
start $errorResponse.documentation_url

# So, in order to use the API for more specific tasks we need to authenticate.
# Let's grab a credential first. This is where you use your PAT.
$credential = Get-Credential -Message 'GitHub UserName and Personal Access Token!'

# There is a Credential parameter...
Invoke-RestMethod -Method Get -Uri 'https://api.github.com/user/repos' -ErrorVariable octoError -Credential $credential

# What a shame. But the API doc hinted at that - we need to craft the authorization header!
$tokenString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $credential.UserName, $credential.GetNetworkCredential().Password)))

# The header is simply a hashtable with whatever headers you need
$header = @{
    Authorization = 'Basic {0}' -f $tokenString
}

$repositories = Invoke-RestMethod -Method Get -Uri 'https://api.github.com/user/repos' -Headers $header -ErrorVariable octoError

# If this is too much to ask, you could've used:
$repositories = Invoke-RestMethod -Method Get -Uri 'https://api.github.com/user/repos' -Authentication Basic -Credential $credential -ErrorVariable octoError

# Let's see what we have here
$repositories[0]

# Ever needed a quick way to see your forks?
$repositories | Where fork

# Create a new repository like a pro - no more UI ;)
# Let's start with the properties that https://developer.github.com/v3/repos/#create has outlined
$repoData = @{
    name             = 'NyanHP_Is_Awesome'
    description      = 'This is so much better than opening a browser'
    has_wiki         = $false
    license_template = 'mit'
}

# The $repodata hashtable can simply be converted to JSON and passed to the API
$jsonBody = $repoData | ConvertTo-Json

# With the proper body, this API call will create a new project
$newRepo = Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' -Authentication Basic -Credential $credential -Body $jsonBody -ContentType application/json

# Ready to get started?
New-Item -ItemType Directory -Path .\MyNewRepo
git clone $newRepo.clone_url MyNewRepo

# Want to see how it looks like?
start $newRepo.html_url

# Change the description with a simple update
$newRepoJson = @{
    name             = 'NyanHP_Is_Awesome'
    description      = 'This works like a charm :)'
    has_wiki         = $false
    license_template = 'mit'
} | ConvertTo-Json

Invoke-RestMethod -Method Patch -Uri "https://api.github.com/repos/$($newRepo.full_name)" -Authentication Basic -Credential $credential -Body $jsonBody -ContentType application/json
