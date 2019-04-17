throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Interacting with SQL can easily be done with PowerShell
# While there are stellar modules like the DBATools out there,
# .NET is also always an option.

# Natively, you would use the SqlServer module
Install-Module -Name SqlServer -Scope CurrentUser

# This module is the official module to manage SQL
Get-Command -Module SqlServer

# You can use the module from simple queries
# Note: To actually use Invoke-SqlCmd, you need to use implicit remoting at the moment.
Export-PSSession -Session (New-PSSession DSCCASQL01) -OutputModule ImplicitSql -Module SqlServer
$projects = Invoke-Sqlcmd -ServerInstance DSCCASQL1\NamedInstance -Database Tfs_AutomatedLab -Credential contoso\install -Query 'SELECT project_name,state from dbo.tbl_projects'

# Your query will contain an array of DataRow objects containing column names as properties
$projects.Where(
    {
        $_.state -ne 'WellFormed'
    }
).ForEach(
    {
        Write-Host "Your project $($_.project_name) is not well formed! It reports status $($_.state)"
    }
)

# If you do not want to install additional modules, .NET has got you covered as well
# Start with a connection to the server
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection

# Using a connection string to connect
$connection.ConnectionString = 'Data Source=DSCCASQL01;Initial Catalog=Tfs_AutomatedLab;Trusted_Connection=yes'

# You command can use the connection - but you need to open it first
$command = New-Object -TypeName System.Data.SqlClient.SqlCommand
$command.Connection = $connection

# The command text should be your Query or the name of your Stored Procedure
$command.CommandText = 'SELECT project_name,state from dbo.tbl_projects'
$command.CommandType = 'Text'

# Once you have opened the connection you can begin querying
# A reader can be used to advance row by row through your results
$connection.Open()
$reader = $command.ExecuteReader()

while ($reader.Read())
{
    Write-Host ("Project {0} is {1}" -f $reader['project_name'], $reader['state'])
}

# If you are done querying, close the connection to the server.
$connection.Close()

# Using Modules like the DbaTools you can be a lot more efficient in your day to day work.
# Are you missing Invoke-SqlCommand from PowerShell Core? Invoke-DbaQuery has you covered.
$result = Invoke-DbaQuery -SqlInstance dsccasql01 -Query 'SELECT project_name,state from dbo.tbl_projects' -Database tfs_automatedlab

# Luckily, the result is an array of DataRows, just like Invoke-SqlCmd
$result.Where(
    {
        $_.state -eq 'WellFormed'
    }
).ForEach(
    {
        Write-Host "Congratulations. Your project $($_.project_name) is well formed."
    }
)

# Another good example is migrating entries from one table to another
# Here, projects from TFS are migrated to Azure DevOps Server.
Get-DbaDbTable -SqlInstance DSCCASQL01 -SqlCredential contoso\Install -Database Tfs_AutomatedLab -Table dbo.tbl_projects |
Copy-DbaDbTableData -Destination DSCCASQL02 -DestinationDatabase AzDevOps_AutomatedLab -DestinationSqlCredential contoso\install -Table az.tbl_projects

# Even an entire migration is beautifully easy
Start-DbaMigration -Source dsccasql01 -Destination dsccasql02 -BackupRestore
