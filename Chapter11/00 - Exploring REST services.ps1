throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

<# RESTful services have been explored in more detail in chapter 6
This recipe uses the wonderful https://jsonplaceholder.typicode.com/

The following routes are supported
GET	/posts
GET	/posts/1
GET	/posts/1/comments
GET	/comments?postId=1
GET	/posts?userId=1
POST	/posts
PUT	/posts/1
PATCH	/posts/1
DELETE	/posts/1
#>

# The Invoke-RestMethod cmdlet should be your standard cmdlet to interact with web services
$baseuri = 'https://jsonplaceholder.typicode.com'
# To read data from an API endpoint, use the GET method
Invoke-RestMethod -Method Get -Uri "$baseuri/posts"

# There might be additional routes, like requesting a specific item
Invoke-RestMethod -Method Get -Uri "$baseuri/posts/42"

# Here, a resource has other resources linked to it. A post has comments, for example
Invoke-RestMethod -Method Get -Uri "$baseuri/posts/42/comments"

# With query parameters separated by a ?, e.g. all posts by user with userId 3
Invoke-RestMethod -Method Get -Uri "$baseuri/users"
Invoke-RestMethod -Method Get -Uri "$baseuri/posts?userId=3"

# To create new items, the POST method is used. These methods usually require a body
$jsonBody = @{
    title  = 'PowerShell rocks'
    body   = 'It really does.'
    userId = 7
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "$baseuri/posts" -Body $jsonBody -ContentType application/json

# The PUT and PATCH methods are used to update entries, again often requiring a body
$jsonBody = @{
    id     = 1
    title  = 'PowerShell rocks'
    body   = 'It really does.'
    userId = 7
} | ConvertTo-Json

Invoke-RestMethod -Method Put -Uri "$baseuri/posts/1" -Body $jsonBody -ContentType application/json

Invoke-RestMethod -Method Patch -Uri "$baseuri/posts/1" -Body $jsonBody -ContentType application/json

# Finally the DELETE method is used to delete objects
Invoke-RestMethod -Method Delete -Uri "$baseuri/posts/42"