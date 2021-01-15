Clear-Host
Import-Module -Name ActiveDirectory
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

$loggedUser = cmd.exe /c "whoami"
$time = Get-Date -Format "dd/MM/yyyy HH:mm"

$users = Import-Csv -Path .\Users.csv

$loginPassword = ""
while ($loginPassword -eq "" -or $loginPassword -notmatch ("\d\d\d\d\d\d")) {
    $passInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter first login password:", "Reset-Password", " ")
    $loginPassword = $passInput.Trim()
    if ($passInput -eq '') {
        Exit
    }
}
$password = (ConvertTo-SecureString $loginPassword -AsPlainText -Force)

$changedUsers = @()
$FailedUsers = @()
foreach ($user in $users) {
    $ADUser = Get-ADUser -Identity $($user.SamAccountName)
    try {
        Set-ADAccountPassword -Identity $ADUser -NewPassword $password -Reset -ErrorAction Stop
        Set-ADUser -Identity $ADUser -ChangePasswordAtLogon $true -CannotChangePassword $false -PasswordNeverExpires $false -ErrorAction Stop
        $changedUsers += Get-ADUser -Identity $ADUser -Properties SamAccountName,Name,Enabled,LastLogOnDate,PasswordNeverExpires,CannotChangePassword,CanonicalName | Select-Object SamAccountName,Name,Enabled,LastLogOnDate,PasswordNeverExpires,CannotChangePassword,CanonicalName
    } catch {
        [void][System.Windows.Forms.Messagebox]::Show("Error: Could not change $($user.SamAccountName) password properties", "Reset-Password")
        $FailedUsers += Get-ADUser -Identity $ADUser -Properties SamAccountName,Name,Enabled,LastLogOnDate,PasswordNeverExpires,CannotChangePassword,CanonicalName | Select-Object SamAccountName,Name,Enabled,LastLogOnDate,PasswordNeverExpires,CannotChangePassword,CanonicalName
    }
}

if ($changedUsers -ne $null) {
    $changedUsers | Export-Csv -Path .\SuccessfulPasswordReset.csv -NoTypeInformation
}
if ($FailedUsers -ne $null) {
    $FailedUsers | Export-Csv -Path .\FailedPasswordReset.csv -NoTypeInformation
}

$outGrid = @() 
foreach ($user in $changedUsers) {
    try {
        $outGrid += @( [PSCustomObject]@{
            SamAccountName = $user.SamAccountName;
            Name = $user.Name;
            Enabled = $user.Enabled;
            LastLogOnDate = $user.LastLogOnDate;
            PasswordNeverExpires = $user.PasswordNeverExpires;
            CannotChangePassword = $user.CannotChangePassword;
            CanonicalName = $user.CanonicalName;
        } )
    } catch {}
}

if ($outGrid -ne $null) {
    $outGrid | Out-GridView -Title "Reset-Password" -Wait
}

