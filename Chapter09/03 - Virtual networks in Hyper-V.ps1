throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Networking on Hyper-V is pretty straightforward
Get-Command -Noun VMSwitch*

# Private networks are used for communcation between the VMs on the host
New-VMSwitch -Name ClusterHearbeat -SwitchType Private

# Internal networks are used for inter-VM communication and communication with the host
New-VMSwitch -Name Management -SwitchType Internal

# External networks are bound to a network adapter and are used for communication with the outside world
New-VMSwitch -Name Domain -NetAdapterName Wi-Fi

# You enable and disable extensions like packet capturing on VSwitches
Get-VMSwitch -Name Management | Get-VMSwitchExtension
Get-VMSwitch -Name Management | Disable-VMSwitchExtension -Name 'Microsoft NDIS Capture'

# To remove an existing switch:
Get-VMSwitch -Name ClusterHearbeat | Remove-VMSwitch -Force

# New with Server 2016 are teamed switches that can team multiple NICs
Get-NetAdapter | ? Status -eq Up
New-VMSwitch -Name DoubleTeam -NetAdapterName 'eth0','eth1'

# Change the members, e.g. remove eth1 and add eth4
Set-VMSwitchTeam -Name DoubleTeam -NetAdapterName 'eth0','eth4'
