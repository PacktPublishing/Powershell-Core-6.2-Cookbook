throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# It all starts here
Get-ChildItem -Path /etc -File

# To control the limits of pamd, have a look at limits.conf
Get-Content -Path /etc/security/limits.conf

# Try filtering for the important parts
Get-Content -Path /etc/security/limits.conf | Where-Object {-not $_.StartsWith('#')}

# With these bits, a certain pattern emerges... Values, separated by whitespace
man limits.conf

# And sure enough, looking at the man page reveals <domain>        <type>  <item>  <value>
$limits = Get-Content -Path /etc/security/limits.conf | Where-Object {-not $_.StartsWith('#')} |
    ForEach-Object {
    $null = $_ -match "(?<Domain>[\w@]+)\s+(?<Type>hard|soft|-)\s+(?<Item>\w+)\s+(?<Value>\d+)"

    # Remove the entire match - we don't really need this
    $Matches.Remove(0)

    # Matches is a dictionary. Incidentally what PSCustomObject can use
    [pscustomobject]$Matches
}

# Normal variables that can be modified and stored again
$limits[0].Type = 'Soft'
$limits[0].Item = 'nproc'
$limits[0].Value = 10

# Add a new limit like this, e.g. to limit the user MyUser to 20 processes
Add-Content -Value 'MyUser hard nproc 20' -Path /etc/security/limits.conf

# PowerShell is also excellent to quickly change a value in a configuration
# Linux admins can still use illegible Regular Expressions - with PowerShell's
# verbose language, beginners tend to understand at least the purpose better
$newPort = 4729
(Get-Content -Path /etc/ssh/sshd_config) -replace "^Port\s+\d+" | Set-Content -Path /etc/ssh/sshd_config -Whatif
