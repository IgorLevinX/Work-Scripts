Import-Module -Name ActiveDirectory

$users = Import-Csv -Path .\usersinfo365.csv | Select-Object @{Name="UserName";Expression={("$($_.UserPrincipalName)" -split "@")[0]}},UserPrincipalName,DisplayName,MobilePhone,PhoneNumber
$notFound = @()

foreach ($user in $users) {
    try {
        $ADUser = Get-ADUser -Identity $user.UserName -Properties MobilePhone,OfficePhone -ErrorAction SilentlyContinue
        
        [PSCustomObject]@{
            UserName = $ADUser.SamAccountName
            Email = $user.UserPrincipalName
            'Office365 MobilePhone' = if ($user.MobilePhone -eq "") {"No MobilePhone"} else {$user.MobilePhone}
            'AD MobilePhone' = if ($ADUser.MobilePhone -eq $null) {"No MobilePhone"} else {$ADUser.MobilePhone}
            'Office365 PhoneNumber' = if ($user.PhoneNumber -eq "") {"No PhoneNumber"} else {$user.PhoneNumber}
            'AD OfficePhone' = if ($ADUser.OfficePhone -eq $null) {"No OfficePhone"} else {$ADUser.OfficePhone}
        } | Export-Csv -Path .\PhoneCheck.csv -Append -NoTypeInformation

    } catch {
        $notFound += $user
    }
}

$notFound | Export-Csv -Path .\NotFound.csv -NoTypeInformation
