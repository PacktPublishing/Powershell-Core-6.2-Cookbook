throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# Discover first
Get-Command -Noun GcSql*

# To create a new MySQL instance, get start with new settings
$project = Get-GcpProject -Name testproject
$param = @{
    MaintenanceWindowDay  = 7
    MaintenanceWindowHour = 22
    DataDiskSizeGb        = 10
    TierConfig            = 'db-n1-highmem-32'
    IpConfigIpv4Enabled   = $true
}
$settings = New-GcSqlSettingConfig @param

# Next, create an instance configuration
$sql = New-GcSqlInstanceConfig -Project $project -Name mysql01 -DatabaseVer 'MYSQL_5_7' -SettingConfig $settings 

# The instance can now be created
$sqlInstance = Add-GcSqlInstance -InstanceConfig $sql

# Import an existing database structure
Invoke-WebRequest -Method Get -Uri "https://raw.githubusercontent.com/datacharmer/test_db/master/employees.sql" -OutFile employees.sql
$c = Get-Content .\employees.sql | Select -First 111
$c | Set-Content .\employees.sql
Import-GcSqlInstance -Instance mysql01 -ImportFilePath .\employees.sql -Database employees

# Import a dump
Invoke-WebRequest -Method Get -Uri "https://raw.githubusercontent.com/datacharmer/test_db/master/load_departments.dump" -OutFile departments.dump
Import-GcSqlInstance -Instance mysql01 -ImportFilePath .\departments.dump -Database employees

# Connect
$sqlInstance = Get-GcSqlInstance -Name mysql01
$connectionString = 'Server={0};Database=mysql01;Uid=root;Pwd=<USE YOUR OWN>;' -f $sqlInstance.IpAddresses[0].IpAddress
