New-PolarisGetRoute -Path /containerizedapi -Scriptblock {$response.Send("Your lucky number is $(Get-Random -min 0 -max 9999)");}
Start-Polaris -Port 8080
while ($true)
{ sleep 1 } 