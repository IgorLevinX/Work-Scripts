Import-Module -Name ActiveDirectory
Import-Module -Name MSOnline

$password = Get-Content ".\Password.txt" | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PsCredential("username",$password)

Connect-MsolService -Credential $credential

$MsolUsers = Get-MsolUser -all | Where-Object {$_.Licenses.AccountSkuID -eq "license"} | Select-Object @{Name="UserName";Expression={("$($_.UserPrincipalName)" -split "@")[0]}},UserPrincipalName

foreach ($mso in $MsolUsers) {
    $user = Get-ADUser -Identity $mso.UserName -Properties EmailAddress
    if ($user.EmailAddress -eq $null) {
        try {
            Set-ADUser -Identity $mso.UserName -EmailAddress $mso.UserPrincipalName
        } catch {}
    }
}
