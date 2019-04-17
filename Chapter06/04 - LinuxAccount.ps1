throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Search for appropriate commands - all of them are external
Get-Command -Name *user*

# With useradd we can pass a password - but it has to be hashed
man useradd

# To generate hash, we can use PowerShell
# But of course, only with a more or less secure credential
$credential = Get-Credential -UserName notImportant
$credential.GetNetworkCredential().Password # This is what we would like to hash

# In Linux, instead of the .NET cryptography namespace it might be easier to use perl or python
# The output of the crypt function used to create password hashes looks like Base64, but is
# probably B64. Part of automation is to know when you need to resort
# to old and archaic methods of generating data
$hashedPassword = python -c ('import crypt; print(crypt.crypt(\"{0}\", crypt.mksalt(crypt.METHOD_SHA512)))' -f $credential.GetNetworkCredential().Password)

# Notice the format of your hashed password.
# $<Numeric ID of the Algorithm>$<Salt>$<Hashedpassword>
useradd -G wheel -p $hashedPassword john

# This would have been the ugly alternative
useradd jim
$credential.GetNetworkCredential().Password | passwd --stdin jim