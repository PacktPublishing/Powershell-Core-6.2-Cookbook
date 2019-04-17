throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Converting back and forth with ConvertTo and ConvertFrom-Json
$customObj = [PSCustomObject]@{
    StringProperty = 'StringValue'
    IntProperty = 42
    ArrayProperty = 1,2,3
}

$jsonString = $customObj | ConvertTo-Json
$jsonString

# The imported object looks the same
$jsonString | ConvertFrom-Json

# Observe the difference between Invoke-WebRequest and Invoke-RestMethod
# With Invoke-WebRequest, the response needs to be parsed
Invoke-WebRequest -uri https://jsonplaceholder.typicode.com/todos/1

# Invoke-RestMethod does the parsing for you as a custom object
$response = Invoke-RestMethod -Method Get -Uri https://jsonplaceholder.typicode.com/todos/1
$response | Get-Member

# JSON is also used to transfer data to a REST API
$jsonBody = @{
    SomeData = 'Some Content :)'
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri https://jsonplaceholder.typicode.com/posts -Body $jsonBody -ContentType application/json

# The built-in JSON cmdlets are lacking when compared to non-standard cmdlets
Install-Module -Name newtonsoft.json -Scope CurrentUser
Get-Date | ConvertTo-Json | ConvertFrom-Json
Get-Date | ConvertTo-JsonNewtonsoft | ConvertFrom-JsonNewtonsoft

# YAML suppport is not included with PowerShell
Install-Module PowerShell-yaml -Scope CurrentUser
Get-Command -Module powershell-yaml

# The amount of data produced looks pretty similar. YAML defines its structure by indentation
$customObj = [PSCustomObject]@{
    StringProperty = 'StringValue'
    IntProperty = 42
    ArrayProperty = 1,2,3
}

$yamlString = $customObj | ConvertTo-Yaml
$yamlString

# Converting the object back from YAML generates a dictionary instead of a custom object
$yamlString | ConvertFrom-Yaml