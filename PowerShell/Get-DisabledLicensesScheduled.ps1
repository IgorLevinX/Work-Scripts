Import-Module -Name ActiveDirectory
Import-Module -Name MSOnline

$password = Get-Content "C:\ADScripts\Password.txt" | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PsCredential("username",$password)
Connect-MsolService -Credential $credential
$MsolUsers = Get-MsolUser -all | Where-Object {$_.IsLicensed -eq $True} | Select-Object @{Name="UserName";Expression={("$($_.UserPrincipalName)" -split "@")[0]}},UserPrincipalName,DisplayName,BlockCredential

foreach ($mso in $MsolUsers) {
    try {
        $user = Get-ADUser -Identity $mso.UserName -ErrorAction SilentlyContinue

        if ($user.DistinguishedName -like "*DisabledAccounts*" -and $user.Enabled -eq $False) {
            $licenses = (Get-MsolUser -UserPrincipalName $mso.UserPrincipalName).Licenses.AccountSkuId -replace "domain:"
            
            if ($licenses -is [System.Array]) {
                $allLicenses = ""
                for ($l = 0; $l -lt $licenses.Length; $l++) {
                    $allLicenses += "$($licenses[$l]) | "
                }
                $licenses = $allLicenses
            } 

            [PSCustomObject]@{
                'AD UserName' = $user.SamAccountName;
                'AD FullName' = $user.Name;
                'AD OU Location' = $user.DistinguishedName;
                'AD Enabled' = $user.Enabled;
                'Office 365 UserName' = $mso.UserPrincipalName;
                'Office 365 DisplayName' = $mso.DisplayName;
                'Office 365 User Licensed' = $mso.isLicensed;
                'Office 365 User Blocked' = $mso.BlockCredential;
                'Office 365 User Licenses' = $licenses;
            } | Export-Csv -Path .\DisabledOffice365Users.csv -Append -NoTypeInformation -Force -Verbose
        }
    } catch {}
}
$tempPath = Test-Path -Path ".\DisabledOffice365Users.csv" -PathType Leaf
if ($tempPath -eq $True) {
    Send-MailMessage -UseSsl -From 'username@domain' -To 'username@domain' -Subject 'Disabled Office 365 users with Licenses' -Attachments ".\DisabledOffice365Users.csv" -SmtpServer 'smtp_server' -Port 'port_number'
    Remove-Item -Path ".\DisabledOffice365Users.csv" -Force
}
