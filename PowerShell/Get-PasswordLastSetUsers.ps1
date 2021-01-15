Clear-Host
Import-Module -Name ActiveDirectory
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

$date = [Microsoft.VisualBasic.Interaction]::InputBox("Enter number of months backward to check password last change date", "Get-PasswordLastSetUsers")
try {
    $date = [int]$date
    if ($date -ne 0) {
        #$date = (Get-Date).AddMonths(-$date)
        $date = (Get-Date).AddDays(-$date)
    } elseif ($date -eq 0) {
        $date = Get-Date
    } else {
        [void][System.Windows.Forms.Messagebox]::Show("Error: No valid number has been entered", "Get-PasswordLastSetUsers")
        Exit
    }
} catch {
    [void][System.Windows.Forms.Messagebox]::Show("Error: No valid number has been entered", "Get-PasswordLastSetUsers")
    Exit
}

$ou = [Microsoft.VisualBasic.Interaction]::InputBox("Enter OU distinguishedName or leave empty for using: OU", "Get-PasswordLastSetUsers", "")
try {
    if ($ou -eq "") {
        $ou = "OU"
    } elseif (-not ([adsi]::Exists("LDAP://$ou"))) {
        [void][System.Windows.Forms.Messagebox]::Show("Error: No valid OU distinguishedName has been entered", "Get-PasswordLastSetUsers")
        Exit
    }
} catch {
    [void][System.Windows.Forms.Messagebox]::Show("Error: No valid OU distinguishedName has been entered", "Get-PasswordLastSetUsers")
    Exit
}

if ($date -ne "" -or $ou -ne "") {
    $users = Get-ADUser -Filter {(PasswordLastSet -lt $date) -and (Enabled -eq $true)} -SearchBase $ou -Properties LastLogOnDate,PasswordLastSet,PasswordNeverExpires,PasswordExpired,CannotChangePassword,CanonicalName
    $users | Sort-Object -Property CanonicalName,PasswordLastSet | Select-Object SamAccountName,Name,Enabled,@{Name="LastLogOnDate";Expression={Get-Date -Date $($_.LastLogOnDate) -Format "dd/MM/yyyy"}},@{Name="PasswordLastSet";Expression={Get-Date -Date $($_.PasswordLastSet) -Format "dd/MM/yyyy"}},PasswordNeverExpires,PasswordExpired,CannotChangePassword,CanonicalName | Export-Csv .\Users.csv -NoTypeInformation -Verbose

    $outGrid = @() 
    foreach ($user in $users) {
        try {
            $outGrid += @( [PSCustomObject]@{
                SamAccountName = $user.SamAccountName;
                Name = $user.Name;
                Enabled = $user.Enabled;
                LastLogOnDate = Get-Date -Date $($user.LastLogOnDate) -Format "dd/MM/yyyy";
                PasswordLastSet = Get-Date -Date $($user.PasswordLastSet) -Format "dd/MM/yyyy";
                PasswordNeverExpires = $user.PasswordNeverExpires;
                PasswordExpired = $user.PasswordExpired;
                CannotChangePassword = $user.CannotChangePassword;
                CanonicalName = $user.CanonicalName;
            } )
        } catch {}
    }

    if ($outGrid -ne $null) {
        $outGrid | Out-GridView -Title "Get-PasswordLastSetUsers" -Wait
    }
}