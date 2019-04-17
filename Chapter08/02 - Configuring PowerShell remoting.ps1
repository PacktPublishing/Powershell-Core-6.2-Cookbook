throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Remoting configuration is usually not necessary, but nevertheless possible
# Start with the WSMan drive
Get-ChildItem -Path WSMan:\localhost

# This drive contains WSMan-specific settings - for example for the client
Get-ChildItem -Path WSMan:\localhost\Client

# Notice that unencrypted traffic is denied by default and that the list
# of trusted hosts that are not authenticated is empty
Get-Item -Path WSMan:\localhost\Client\AllowUnencrypted,WSMan:\localhost\Client\TrustedHosts

# The client can also specify authentication settings. Note that the server needs to
# support those settings as well
Get-ChildItem -Path WSMan:\localhost\Client\Auth

# To modify settings, the Set-Item cmdlet can be used. Let's set some limits!
# The IdleTimeout specifies the default timeout for a remote session and is 2 hours
$newTimeout = New-TimeSpan -Hours 8
Set-Item WSMan:\localhost\Shell\IdleTimeout -Value $newTimeout.TotalMilliseconds

# MaxConcurrentUsers specifies how many users may connect at the same time
# and MaxShellsPerUser the number of shells they may start.
Set-Item WSMan:\localhost\Shell\MaxConcurrentUsers -Value 10
Set-Item WSMan:\localhost\Shell\MaxShellsPerUser -Value 2
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 50
