throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Again, some cmdlets to help you get going
Get-Command -Noun Clixml,Xml

# XML can contain a lot of information
Get-Date | Export-Clixml -Path .\date.xml
(Get-Content .\date.xml).Count # 17 lines for a simple date

# Compared to CSV, XML can store a lot of information
Get-Date | Export-Csv -Path .\date.csv

# This will look like a list format due to its many properties
Import-Csv .\date.csv

# This still looks like a friendly date
Import-Clixml -Path .\date.xml

# Certain things still change during deserialization (import)
# Most notably, object methods will be gone and there will be
# some deserialized properties

# While a DateTime object can be reconstructed entirely
Import-Clixml -Path .\date.xml | Get-Member

# A Process object will lose information
Get-Process -Id $Pid | Export-Clixml -Path .\process.xml
# Only two methods
Import-Clixml -Path .\process.xml | Get-Member -MemberType Methods

# Some property types prefixed with Deserialized, like Threads
Import-Clixml -Path .\process.xml | Get-Member -Name ProcessName,Threads

# You can also convert to CliXml directly
# This yields an XML document
$xmlDate = Get-Date | ConvertTo-Xml
$xmlDate.Objects.Object.'#text'

# Invoking the serializer will return an often more useful string
$serializedDate = [System.Management.Automation.PSSerializer]::Serialize((Get-Date))

# When deserializing, you can decide if you want a single object or a list back
[System.Management.Automation.PSSerializer]::Deserialize($serializedDate)
[System.Management.Automation.PSSerializer]::DeserializeAsList($serializedDate)

# The same process happens when working remotely or with jobs
$proc = Start-Job -ScriptBlock {Get-Process -Id $pid} | Wait-Job | Receive-Job -Keep
$proc | Get-Member -MemberType Methods

# Some members will be added automatically for convenience
# Notice the PSComputername, which is also present for e.g. Invoke-Command!
$proc | Get-Member -Name PSShowComputerName,PSComputerName,RunspaceId