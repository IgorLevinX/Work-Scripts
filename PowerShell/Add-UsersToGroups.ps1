Import-Module -Name ActiveDirectory

$users = Import-Csv -Path .\Users.csv
$groups = Import-Csv -Path .\Groups.csv

if (Test-Path -Path .\UsersGroups.csv -ErrorAction SilentlyContinue) {
    Remove-Item -Path .\UsersGroups.csv -Force -ErrorAction SilentlyContinue
}

foreach ($user in $users) {
    $ADUser = Get-ADUser -Identity $user.UserName -ErrorAction SilentlyContinue
    if ($ADUser) {
        foreach ($group in $groups) {
            $ADGroup = Get-ADGroup -Identity $group.GroupName -ErrorAction SilentlyContinue
            if ($ADGroup) {
                Add-ADGroupMember -Identity $ADGroup -Members $ADUser -ErrorAction SilentlyContinue -Verbose
            } else {
                Write-Host "Error: Could not find Group: $($group.GroupName)"
            }
        }
    }
    else {
        Write-Host "Error: Could not find User: $($user.UserName)"
    }
}

Start-Sleep -Seconds 15

foreach ($user in $users) {
    $ADUser = Get-ADUser -Identity $user.UserName -ErrorAction SilentlyContinue
    if ($ADUser) {
        $ADGroups = @()
        foreach ($group in $groups) {
            $ADGroup = Get-ADPrincipalGroupMembership -Identity $ADUser.SamAccountName -ErrorAction SilentlyContinue | Where-Object {$_.SamAccountName -eq $($group.GroupName)}
            if ($ADGroup) {
                $ADGroups += "$($group.GroupName) Exist"
            } else {
                $ADGroups += "$($group.GroupName) Not Exist"
            }
        }
        $ADGroupsFormatted = ""
        for ($i = 0; $i -lt $ADGroups.Length; $i++) {
            $ADGroupsFormatted += "$($ADGroups[$i]) | "
        }
        if ($ADGroupsFormatted) {
            [PSCustomObject]@{
                UserName = $ADUser.SamAccountName
                NewGroups = $ADGroupsFormatted
            } | Export-Csv -Path .\UsersGroups.csv -Append -NoTypeInformation -Force -Verbose
        }

    } else {
        Write-Host "Error: Could not find User: $($user.UserName)"
    }
}