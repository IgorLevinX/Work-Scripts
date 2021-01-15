Import-Module -Name Posh-SSH

$service = Get-Service -Name "service" | Select-Object Name,Status,StartType
if ($service.Status -ne "Running" -or $service.StartType -ne "Automatic") {
    Set-Service -Name $service.Name -StartupType Automatic -Status Running
}

$service = Get-Service -Name "service" | Select-Object Name,Status,StartType
if ($service.Status -ne "Running") {
    Send-MailMessage -From 'username@domain' -To 'username@domain' -Subject 'service: name Service' -Body 'service not running and could not be started automatically' -SmtpServer 'smtp_server' -Port "port_number"
}

$password = Get-Content -Path ".\password.txt" | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PsCredential("username",$password)

$session = New-SFTPSession -ComputerName "" -Credential $credential -ErrorAction SilentlyContinue
if ($session -eq $null) {
    Send-MailMessage -From 'username@domain' -To 'username@domain' -Subject 'service: Cannot connect to server' -Body 'service script cannot connect to server' -SmtpServer 'smtp_server' -Port "port_number"
}

$files = Get-SFTPChildItem -SFTPSession $session -Path "/folder/" -Recursive | Select-Object FullName,LastAccessTime
if ($files -eq $null) {
    Send-MailMessage -From 'username@domain' -To 'username@domain' -Subject 'service: No files to copy in server' -Body 'service cannot find files in folder on server to copy' -SmtpServer 'smtp_server' -Port "port_number"
}

foreach ($file in $files.FullName) {
    
    Get-SFTPFile -SFTPSession $session -RemoteFile $file -LocalPath "C:\folder\"
    Get-SFTPFile -SFTPSession $session -RemoteFile $file -LocalPath "D:\folder\"
}
