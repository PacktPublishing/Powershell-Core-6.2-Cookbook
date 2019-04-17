throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Connecting to remote endpoints is great, but what about security?

# The following cmdlet call should fail.
# By default, PowerShell tries to authenticate via Kerberos in a Domain environment
# and Negotiate in a Workgroup
Enter-PSSession -ComputerName PACKT-DC1

# Specifying credentials prompts PowerShell to use Negotiate
# This means, PowerShell will use Kerberos for Domain-joined machines
# and NTLM for Workgroup machines
Enter-PSSession -ComputerName PACKT-DC1 -Credential contoso\Install

# You can now work on the remote machine. Notice the prompt
$env:COMPUTERNAME

# Leave the session for now
Exit-PSSession

# Without retrieving data, you can always test first
Test-WSMan -ComputerName PACKT-DC1 -Credential contoso\Install -Authentication Negotiate

# Using stored credentials is also possible, for example to review remote configurations
# Use the account contoso\Install with the password Somepass1
$credential = Get-Credential
Connect-WSMan -ComputerName PACKT-DC1 -Credential $credential -Authentication Negotiate

# Connecting to a Linux system that is configured to use SSH is a bit different
# The parameter HostName indicates that SSH should be attempted.
# By default, the subsystem powershell will be used, unless otherwise specified
Enter-PSSession -HostName PACKT-CN1 -UserName root

# For additional security, you can use public key authentication with a key file
# The server needs to know your public key in order to authenticate you
Enter-PSSession -HostName PACKT-CN1 -UserName root -KeyFilePath $home/.ssh/myPubKey
