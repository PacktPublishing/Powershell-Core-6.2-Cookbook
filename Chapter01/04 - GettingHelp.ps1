throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Help about the help system
Get-Help

# The built-in parameter -? for all cmdlets
Start-Process -?

# Discovering options for single parameters
Get-Help Start-Process -Parameter FilePath

# Viewing the full help content
Get-Help Start-Process -Full

# Download updated help content from the internet
Update-Help -Scope CurrentUser

# ...or from a file share
Update-Help -Scope CurrentUser -SourcePath \\contoso.com\PSHelp

# You can also download localized help if available
Update-Help -Module CimCmdlets -UICulture ja-jp,sv-se

# Looking at the full help again, more content is visible now
Get-Help Start-Process -Full
