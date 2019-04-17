throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# On Linux, Remoting is not enabled by default with PS Core.
# To enable it, you have two choices

# SSH Remoting can be enabled by adding PS Core as a subsystem
if (-not (Get-Content -Path /etc/ssh/sshd_config | Select-String -Pattern"Subsystem.*/usr/bin/pwsh"))
{
    Add-Content -Path /etc/ssh/sshd_config -Value 'Subsystem powershell /usr/bin/pwsh -sshs -NoLogo -NoProfile'
}

# OMI-PSRP-Server
yum install omi-psrp-server

# There should not be configuration settings pending. Carefully review the configuration
# By default, SSL on port 5986 is enabled and http is disabled
# In a domain environment where krb5-client is used, you can enable http with SPNEGO
# Pay special attention to AuthorizedGroups and UnauthorizedGroups - if left blank, no authorization checks are performed.
Get-Content -Path /etc/opt/omi/conf/omiserver.conf

# Add the necessary incoming firewall rules for either OMI or SSH remoting
firewall-cmd --zone=public --permanent --add-port=5985/tcp

# And probably more importantly configure SELinux properly
semanage port -a -t ssh_port_t -p tcp 5985
