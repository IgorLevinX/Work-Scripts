$results = @()
$users = Get-ADUser -Filter * -Properties MemberOf,CanonicalName -SearchBase "OU"
#$users = Get-ADUser -Identity iglevin -Properties MemberOf
foreach ($user in $users) {
    $groups = $user.MemberOf
    $groupCollection = @()
    while ($true) {
        Write-Host "$($user.Name)" -ForegroundColor Cyan
        $exitLoop = 0
        $nextGroups = @()    
        foreach ($group in $groups) {
            #Write-Host "$group" -ForegroundColor Cyan
            $groupCollection += $group
            if ($(Get-ADGroup -Identity $group -Properties MemberOf).MemberOf.Count -ne 0) {
                $nextGroups += $(Get-ADGroup -Identity $group -Properties MemberOf).MemberOf
                $exitLoop++
                $exitLoop
                $group
            }
        }
        $nextGroups = $nextGroups | Select-Object -Unique
        $groupCollection = $groupCollection | Select-Object -Unique
        $groups = @()
        foreach ($ng in $nextGroups) {
            if (-not $groupCollection.contains($ng)) {
                $groups += $ng
            }
        }
        if ($exitLoop -eq 0) {
            Break
        }
    }
    $groupCollection = $groupCollection | Select-Object -Unique
    $groupCollection = $groupCollection -join ';'

    $results += New-Object PSObject -Property @{
        UserName = $user.SamAccountName
        Name = $user.Name;
        Enabled = $user.Enabled;
        "User OU Path" = $user.CanonicalName;
        Groups = $groupCollection;
    }
}
$results | Where-Object { $_.Groups -notmatch 'BlueCoat' } | Select-Object UserName,Name,Enabled,"User OU Path" | Export-Csv -Path .\NoBlueCoatUsers.csv -NoTypeInformation
$results | Where-Object { $_.Groups -match 'BlueCoat' } | Select-Object UserName,Name,Enabled,"User OU Path",@{Name='BlueCoat Groups';Expression={$_.Groups.Split(';') -match "BlueCoat"}} | Export-Csv -Path .\BlueCoatUsers.csv -NoTypeInformation


