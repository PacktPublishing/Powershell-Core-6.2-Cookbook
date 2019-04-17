throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# To get started, we need something to manipulate
$tempFile = Get-Item -Path $(New-TemporaryFile).FullName

# The ubiquitous Get-Member shows all relevant details - for now
$tempFile | Get-Member

# Using the force does not provide more useful output
$tempFile | Get-Member -Force

# With reflection, we can dive deep into our objects
$tempFile.GetType() | Get-Member -Name Get*

# Try retrieving all fields, or private properties
# The BindingFlags indicate which values we want to see.
# Here: All non-public members of the current object instance
$tempFile.GetType().GetFields([Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Instance) |
     Format-Table -Property FieldType, Name

# To see the value of a field, try using the GetField method
$field = $tempFile.GetType().GetField('_name', [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Instance)
$field.GetValue($tempFile)

# This even works when changing a field
$fullName = $tempFile.GetType().GetField('FullPath', [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Instance)
$fullName.GetValue($tempFile)
$fullName.SetValue($tempFile, 'C:\Users\japete.EUROPE\AppData\Local\Temp\WHATISHAPPENING')
$tempFile.FullName # Oh boy...
$tempFile # File still looks like before
$tempFile | Get-Member # Get-Member also looks normal
$tempFile.CopyTo('D:\test') # ...and now things fall apart. CopyTo internally uses the private field FullPath!

# Adding members is fortunately less disruptive
# Note properties are like yellow sticky notes - they are loosely attached to the object
$tempFile | Add-Member -NotePropertyName MyStickyNote -NotePropertyValue 'SomeValue'
$tempFile.MyStickyNote
# Note properties have a changeable data type
$tempFile.MyStickyNote = Get-Date

# ScriptProperties are dynamic properties that calculate themselves.
# By using this, we are referencing the current instance of the class
$tempFile | Add-Member -MemberType ScriptProperty -Name Hash -Value {Get-FileHash -Path $this.PSPath}
$tempfile.Hash

# ScriptMethods are similar to object methods and can accept parameters as well
$tempFile | Add-Member -MemberType ScriptMethod -Name GetFileHash -Value {Get-FileHash -Path $this.PSPath}
$tempFile.GetFileHash()

Remove-Item -Path $tempFile.PSPath # Luckily, PSPath has not been changed

# as one practical example, take the Windows event log
$oneEvent = Get-WinEvent -FilterHashtable @{
     LogName = 'Security'
     ID = 4624
} -MaxEvents 1

# Properties is a simple list that you could access by index
$oneEvent.Properties

# Using the event XML is more convenient, if available
([xml]$oneEvent.ToXml()).Event.EventData.Data

# So why not either store single data fields as new properties?
$oneEvent | Add-Member -NotePropertyName SubjectUserName -NotePropertyValue ($oneEvent.Properties[1].Value)
$oneEvent.SubjectUserName

# When collecting objects like events remotely, serialization will strip away object methods. By using a 
# ScriptProperty or a NoteProperty we can effectively eliminate that problem
$deserializedEvent = Start-Job { Get-WinEvent -FilterHashtable @{
     LogName = 'Security'
     ID = 4624
} -MaxEvents 1 | Add-Member -MemberType ScriptProperty -Name EventXml -Value {[xml]$this.ToXml()} -PassThru } | Wait-Job | Receive-Job
$deserializedEvent.EventXml # Useful
$deserializedEvent.EventXml.Event.EventData.Data # Everything is there to use
$deserializedEvent.ToXml() # Error - this method does not exist any longer
