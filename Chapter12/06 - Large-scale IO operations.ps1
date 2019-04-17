throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Text processing can still be necessary even in a world of APIs

# On Windows and Windows Server, the CBS (component based servicing) logs
# can get quite big
$biggestLog = Get-ChildItem -Path /Windows/Logs/CBS/*.log -File | Sort-Object Length -Bottom 1

# Even reading in the content can take long
# execute the next commands line by line, not en-bloc
$content = $biggestLog | Get-Content
(Get-History -Count 1).Duration # 2.5s

$contentReadCount = $biggestLog | Get-Content -ReadCount 1000
(Get-History -Count 1).Duration # 0.2s

$content2 = $biggestLog | Get-Content -Raw
(Get-History -Count 1).Duration # 0.2s

# So why don't we always use -Raw or -ReadCount?
$content.Count          # 166000 individual objects
$contentReadCount.Count # 166 objects each containing 1000 lines
$content2.Count         # 1 Object

# -Raw can be a good alternative if you are looking for text
# spanning multiple lines
$result = $content | Select-String -Pattern "ServerStandardEvalCorEdition" # Slow
$result = $content -match "ServerStandardEvalCorEdition" # Medium
$result = $content2 -match "ServerStandardEvalCorEdition" # Fast

# What about writing large amounts of texts, e.g. logging something for ALL users in the ActiveDirectory?
$users = Get-ADUser -Filter * -Properties PasswordLastSet
$userString = "{0}: {1:yyyy-MM-dd}"

$start = Get-Date
foreach ($user in $users)
{
	$text += [string]::Format($userString, $user.SamAccountName,$user.PasswordLastSet)
}
$end = Get-Date
"+= Operator: $($end - $start)" # Nope...

$start = Get-Date
$text = -join $users.SamAccountName
$end = Get-Date
"join Operator: $($end - $start)" # not as flexible, but blazing fast

$start = Get-Date
$sb = [System.Text.StringBuilder]::new()

foreach ($user in $users)
{
	[Void]$sb.Append([string]::Format($userString, $user.SamAccountName,$user.PasswordLastSet))
}
$text = $sb.ToString()
$end = Get-Date
"StringBuilder: $($end - $start)" # Ohhhh yeeahh! The sweet spot between speed and versatility.
