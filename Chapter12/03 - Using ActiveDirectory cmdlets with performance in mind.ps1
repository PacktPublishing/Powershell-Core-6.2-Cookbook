throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# This recipe requires the lab environment. It will not work otherwise.
# You may execute the steps directly on PACKT-DC1

# Retrieving objects from Active Directory happens often
Get-ADUser -Identity install

# While retrieving a user with an identity is of course fast, searching for it
# is not. You can notice the difference directly
Get-ADUser -Filter * | Where-Object -Property SamAccountName -eq install

# Often though you already know where you are searching - so why not narrow it down?
$orgUnit = 'OU=Canada,OU=Lab Accounts,DC=contoso,DC=com'
Get-ADUser -Filter * -SearchBase $orgUnit -SearchScope Subtree

# The Filter parameter is the obvious choice, but the LDAP filter can also be used
# However, LDAPFilter requires you to use the correct attributes whereas Filter
# can use the property names

# LDAP filter can get ugly
# 1.2.840.113556.1.4.803 is the LDAP matching rule (bitwise AND) checking if the decimal 2 is set as the value of 
# the useraccountcontrol flag. This value simply means "Disabled"
# https://support.microsoft.com/en-gb/help/305144/how-to-use-useraccountcontrol-to-manipulate-user-account-properties
Get-ADUser -LDAPFilter '(&(objectclass=user)(useraccountcontrol:1.2.840.113556.1.4.803:=2))'

# Filter is a bit nicer
Get-ADUser -Filter 'Enabled -eq $false'

# But there are often better tools for a job.
# You wouldn't use a hammer for a screw ;)
Search-ADAccount -AccountDisabled -UsersOnly

# By filtering as early as possible, you relieve the ADWS of some of the load