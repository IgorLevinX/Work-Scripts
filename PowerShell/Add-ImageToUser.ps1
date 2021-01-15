Clear-Host
Import-Module -Name ExchangeOnlineShell

if (!(Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" })) {
    $cred = Get-Credential
    Connect-ExchangeOnlineShell -Credential $cred | Out-Null
    Clear-Host
}

$user = Read-Host -Prompt "Enter Office 365 UserName"
$photo = Read-Host -Prompt "Enter Photo Name"

Set-UserPhoto -Identity $user -PictureData ([System.IO.File]::ReadAllBytes("C:\HDScripts\AddEmployeeInfo\Photos\$photo.jpg")) -Preview -Confirm:$False -Verbose
Set-UserPhoto -Identity $user -Save -Confirm:$False -Verbose
Get-UserPhoto -Identity $user -Verbose