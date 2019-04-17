throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# To do anything with the CMS, you will need some certificates. Create the certificates for two nodes first:
Import-WinModule -Name Pki
New-SelfSignedCertificate -Subject 'CN=Node01' -FriendlyName 'DSC MOF Encryption Cert for machine Node01' -Type DocumentEncryptionCert -CertStoreLocation Cert:\CurrentUser\my

# Let's explore the certificate a bit:
$certificate = Get-ChildItem -Path Cert:\CurrentUser\my | Where-Object -Property Subject -eq 'CN=Node01'
$certificate | Get-Member -MemberType Methods

# One important method will be Verify. You can execute this method to verify the certificate chain
$certificate.Verify()

# Other useful methods
$certificate.GetPublicKeyString()
$certificate.GetCertHashString()

# You can always check if you are in posession of the private key
$certificate.HasPrivateKey

# To use CMS, we can make use of the CMS cmdlets
Get-Command -Noun *CmsMessage

# Encrypting something is simple - as long as you have the public key of the recipient
# In order to encrypt, document encryption certificates are needed
$protectedMessage = Read-Host -Prompt 'Enter your connection string' | Protect-CmsMessage -To "CN=Node01"
$protectedMessage

# Have a look at the details of the message - there is much you can read
$protectedMessage | Get-CmsMessage
($protectedMessage | Get-CmsMessage).ContentEncryptionAlgorithm.Oid.FriendlyName # e.g. AES256

# To decrypt the message, you need to be in possession of the private key
$protectedMessage | Unprotect-CmsMessage
