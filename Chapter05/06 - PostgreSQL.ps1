throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Connecting to other data sources can be quite easy

# First of all, we can use NuGet to pull the required libraries for us
# at the time of writing, Save-Package npgsql -path . only worked with Windows PowerShell
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Npgsql/4.0.4 -OutFile .\postgres.zip
Expand-Archive .\postgres.zip
Add-Type -Path .\postgres\lib\netstandard2.0\Npgsql.dll

# Create a new connection - and the rest stays the same
$connection = [Npgsql.NpgsqlConnection]::new('host=postgreshost.domain.com dbname=pgDb user=john password=Somepass1')

# A new NpgsqlCommand works just like your SqlCommand
$command = [Npgsql.NpgsqlCommand]::new($connection)

# Command text of course might be slightly different with different SQL dialects
$command.CommandText = 'SELECT * FROM distributors ORDER BY name'
$command.CommandType = 'Text'
$connection.Open()

# This model provides uniform access to data, regardless of the source
$reader = $command.ExecuteReader()

while ($reader.Read())
{
    Write-Host "Distributor-ID $($reader.did), Name: $($reader.Name)"
}

# As with MSSQL, Postgre connections should also be properly closed
$connection.Close()
