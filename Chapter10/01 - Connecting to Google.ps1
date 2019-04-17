throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# In order to connect to Google, you need to install the GoogleCloud module and the SDK
Install-ChocolateyPackage -Name gcloudsdk # Or download the installer from https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe
Install-Module -Name GoogleCloud -Scope CurrentUser

# Like with Azure, you need to authenticate before trying anything
Get-GcpProject

# You can authenticate with the Google Cloud SDK
gcloud init

# Now it is possible to retrieve data, for example your project's buckets
Get-GcsBucket

# To store your access token more permanently, use the following command.
# It will point you to a browser where you allow the client libs to authenticate you
gcloud auth application-default login

# This enables us to get the access token for API requests
gcloud auth application-default print-access-token
