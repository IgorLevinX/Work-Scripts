Import-Module -Name ActiveDirectory
Import-Module -Name MSOnline

$cred = Get-Credential

Connect-MsolService -Credential $cred

$MsolUsers = Get-MsolUser -all | Where-Object {$_.Licenses.AccountSkuID -eq "Licenses"} | Select-Object @{Name="UserName";Expression={("$($_.UserPrincipalName)" -split "@")[0]}},UserPrincipalName

foreach ($mso in $MsolUsers) {
    try {
        $user = Get-ADUser -Identity $mso.UserName
        
        if ($user.DistinguishedName -like "*OU*" -and $user.Enabled -eq $False) {

            $noLicence = Get-MsolUser -UserPrincipalName $mso.UserPrincipalName | Select-Object UserPrincipalName,DisplayName,isLicensed,BlockCredential 

            [PSCustomObject]@{

                'AD UserName' = $user.SamAccountName;
                'AD FullName' = $user.Name;
                'AD OU Location' = $user.DistinguishedName;
                'AD Enabled' = $user.Enabled;
                'Office 365 UserName' = $noLicence.UserPrincipalName;
                'Office 365 DisplayName' = $noLicence.DisplayName;
                'Office 365 User Licensed' = $noLicence.isLicensed;
                'Office 365 User Blocked' = $noLicence.BlockCredential;
            
            } | Export-Csv -Path .\GetLicencedUsers.csv -Append -NoTypeInformation -Force -Verbose

        }
    } catch {}
}

