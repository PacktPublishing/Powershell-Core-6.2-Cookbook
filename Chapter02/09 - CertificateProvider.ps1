throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Another Windows-only provider, allowing access to local cert stores
Get-PSProvider -PSProvider Certificate

# Again, the default cmdlets apply

# List all certificate stores
Get-ChildItem -Path Cert:\CurrentUser

# List all certificates of the user's personal store
Get-ChildItem -Path Cert:\CurrentUser\my

# The parameters offered by the Certificate provider are very interesting
# on Windows PowerShell, additional parameters like -EKU and -SslServerAuthentication will be available
Get-ChildItem -Path Cert:\CurrentUser\my -CodeSigningCert
$certificate = Get-ChildItem -Path Cert:\CurrentUser\my | Select-Object -First 1

# Filter on the OIDs. If OID cannot be resolved, use the numeric object ID instead of the friendly name!
# The OID is more reliable and not subject to localization
$certificate.EnhancedKeyUsageList

# for example searching for all client authentication certificates
Get-ChildItem -Path cert:\currentuser\my | Where-Object -FilterScript {$_.EnhancedKeyUsageList.ObjectId -eq '1.3.6.1.5.5.7.3.2'}

# Not unimportant; Filter on certificates where the private key is accessible, i.e. to digitally sign documents
Get-ChildItem -path Cert:\CurrentUser\my | 
    Where-Object -Property HasPrivateKey | 
    Format-table -Property Subject,Thumbprint,@{Label='EKU'; Expression = {$_.EnhancedKeyUsageList.FriendlyName -join ','}}

$certificate.HasPrivateKey

# While New and Set cmdlets are not implemented for certificates, Remove can be used for some spring cleaning
Get-ChildItem -Path Cert:\CurrentUser\my |
    Where-Object -Property NotAfter -lt $([datetime]::Today) |
    Remove-Item -WhatIf

# New-item can be used for new stores - but this is rarely done
New-Item -Path Cert:\LocalMachine\NewStore
Remove-Item -Path Cert:\LocalMachine\NewStore
