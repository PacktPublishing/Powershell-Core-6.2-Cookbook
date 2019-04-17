throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Deploying traditional SQL workloads on Azure is fairly simple

# If PaaS is enough for you:
Get-Command -Noun AzSqlDatabase*, AzSqlServer*

# Create a new server
New-AzResourceGroup -Name SqlDatabases -Location westeurope

$adminCredential = Get-Credential -UserName sqlgrandmaster
$name = -join (1..12 | ForEach-Object { Get-Random -Min 0 -Max 9 }) # should be random ;) Need to be unique on .database.windows.net
New-AzSqlServer -ResourceGroupName SqlDatabases -ServerName $name -SqlAdministratorCredentials $adminCredential -Location westeurope

# The next bit is important if you ever want to manage your SQL databases remotely...
if (-not (Get-Command Get-PublicIpAddress))
{
    Install-Module AutomatedLab.Common -Scope CurrentUser
}

$param = @{
    ResourceGroupName = 'SqlDatabases'
    ServerName        = $name
    FirewallRuleName  = "AllowedIPs"
    StartIpAddress    = Get-PublicIpAddress
    EndIpAddress      = Get-PublicIpAddress
}
$serverFirewallRule = New-AzSqlServerFirewallRule @param

# Create a new database on your server
New-AzSqlDatabase -DatabaseName db01 -ServerName $name -ResourceGroupName SqlDatabases

# To create a database from a bacpac file, you can use the New-AzSqlDatabaseImport cmdlet
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac"  -Out wwi.bacpac

$storageAccountName = -join (1..10 | ForEach-Object { Get-Random -min 0 -max 9 })
$account = New-AzStorageAccount -Name $storageAccountName -ResourceGroupName SqlDatabases -ErrorAction SilentlyContinue -SkuName Standard_LRS -Location westeurope
$container = New-AzStorageContainer -Name bacpacs -Context $account.Context -ErrorAction SilentlyContinue
$content = Set-AzStorageBlobContent -File .\wwi.bacpac -CloudBlobContainer $container.CloudBlobContainer -Blob 'wwi.bacpac' -Context $account.Context -Force

# With the sample uploaded, try it
$importParam = @{ 
    ResourceGroupName          = "SqlDatabases" 
    ServerName                 = $name 
    DatabaseName               = "db02" 
    DatabaseMaxSizeBytes       = 1GB 
    StorageKeyType             = "StorageAccessKey"
    StorageKey                 = ($account | Get-AzStorageAccountKey)[0].Value
    StorageUri                 = $content.ICloudBlob.StorageUri.PrimaryUri
    Edition                    = "Standard" 
    ServiceObjectiveName       = "S3" 
    AdministratorLogin         = $adminCredential.UserName
    AdministratorLoginPassword = $adminCredential.Password
}

$import = New-AzSqlDatabaseImport @importParam

while ((Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $import.OperationStatusLink).Status -eq 'InProgress')
{
    Start-Sleep -Seconds 5
    Write-Host . -NoNewLine
}

# To retrieve your connection string within PowerShell
$sqlInfo = Get-AzSqlServer -ServerName $name -ResourceGroupName SqlDatabases
$connectionString = 'Server=tcp:{0};Initial Catalog={1};Persist Security Info=False;User ID={2};Password={3};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;' -f $sqlInfo.FullyQualifiedDomainName, 'db02', $adminCredential.UserName, $adminCredential.GetNetworkCredential().Password

# Now you can use your favorite connection type
Describe "Did it work?" {
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $connectionString
    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    It "Should not throw" {
        { $connection.Open() } | Should -Not -Throw
    }

    $command.CommandText = 'SELECT COUNT(*) FROM Sales.Orders'
    $rowcount = $command.ExecuteScalar()
    It "Should have 73595 orders" {
        $rowcount | Should -BeGreaterOrEqual 73595
    }
    $connection.Close()
}

# There are some awesome features available if you are an Azure customer
Enable-AzSqlServerAdvancedThreatProtection -ServerName $name -ResourceGroupName SqlDatabases
$container = New-AzStorageContainer -Name vulscan -Context $account.Context -ErrorAction SilentlyContinue
Update-AzSqlDatabaseVulnerabilityAssessmentSettings -ServerName $name -DatabaseName db02 -StorageAccountName $account.StorageAccountName -ScanResultsContainerName vulscan -ResourceGroupName SqlDatabases
Start-AzSqlDatabaseVulnerabilityAssessmentScan -ServerName $name -DatabaseName db02 -ResourceGroupName SqlDatabases
