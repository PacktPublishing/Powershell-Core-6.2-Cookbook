throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

#region Installation through MSI
$path = Join-Path -Path $([IO.Path]::GetTempPath()) -ChildPath pwsh.msi
Invoke-WebRequest -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/PowerShell-6.2.0-win-x64.msi' -OutFile $path
$installation = Start-Process -FilePath msiexec -ArgumentList "/i `"$path`"", "/L*v `"$path.log`"", '/qn' -PassThru -Wait -NoNewWindow

if ($installation.ExitCode -in 0, 3010)
{
    Write-Host "PowerShell is ready..."
    pwsh
}
#endregion

#region Installation with Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install powershell /y
#endregion