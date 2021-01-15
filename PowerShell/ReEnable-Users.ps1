Import-Module -Name ActiveDirectory
Add-Type -AssemblyName System.Windows.Forms   
Add-Type -AssemblyName System.Drawing
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

$loggedUser = cmd.exe /c "whoami"
$time = Get-Date -Format "dd/MM/yyyy HH:mm"

$UserNames = Import-Csv -Path .\Users.csv
$outGrid = @()

#
# Function for copying existing user information to other users during creation
#
$copyButton_Click = {
    $CopyUser = $null
    $CopyUserOU = $null

    # Checking if there is a valid existing user OU to move the new users
    while ($CopyUserOU -eq $null) {
        $UserInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter user to copy:", "ReEnable Users Script", " ")

        $UserName = [string]$UserInput.Trim()

        if ($UserInput -eq '') {
            Return
        }
        try {
            $CopyUser = Get-ADUser -Identity $UserName -Property CanonicalName -ErrorAction SilentlyContinue
        } catch {
            if ($UserInput -ne " ") {
                [System.Windows.Forms.Messagebox]::Show("Invalid Username: $UserName", "ReEnable Users Script")
            }
            $CopyUser = $null
            Continue
        }
        $CopyUserOU = ($CopyUser.DistinguishedName -split ",",2)[1]
    }

    # Getting a valid password for the users
    $LoginPassword = ""
    $SecurePassword = $null
    while ($LoginPassword -eq "" -or $LoginPassword -notmatch ("\d\d\d\d\d\d")) {
        $PassInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter first login password:", "ReEnable Users Script", " ")
        $LoginPassword = $PassInput.Trim()

        if ($PassInput -eq '') {
            Return
        } else {
            $SecurePassword = (ConvertTo-SecureString $LoginPassword -AsPlainText -Force)
        } 
    }
    $groups = Get-ADPrincipalGroupMembership -Identity $CopyUser | Where-Object {$_.SamAccountName -ne "Domain Users" -or $_.Name -ne "Domain Users"}

    <#
    Looping through every user from file:
        1. Enabling the users
        2. Moving them the the OU we got from the copy user
        3. copying permissions to the users from copy user
        4. Setting first login password
    #>
    foreach ($username in $UserNames) {
        $ADUser = Get-ADUser -Identity $($username.UserName)

        if ($ADUser.Enabled -eq $False) {
            $ADUser | Enable-ADAccount
        }

        try {
            Move-ADObject -Identity $ADUser -TargetPath $CopyUserOU
            } catch {}   
        
        foreach ($group in $groups) { 
            Add-ADPrincipalGroupMembership -Identity $($username.UserName) -MemberOf $group.SamAccountName -ErrorAction SilentlyContinue | Out-Null 
            Add-ADPrincipalGroupMembership -Identity $($username.UserName) -MemberOf $group.Name -ErrorAction SilentlyContinue | Out-Null
        }
        
        Set-ADAccountPassword -Identity $($username.UserName) -Reset -NewPassword $SecurePassword
        Set-ADUser -Identity $($username.UserName) -ChangePasswordAtLogon $True -CannotChangePassword $False -PasswordNeverExpires $False

        $ReEnabledUser = Get-ADUser -Identity $($username.UserName) -Properties CanonicalName,MemberOf -ErrorAction SilentlyContinue
        $outGrid += @( [PSCustomObject]@{
            UserName = $ReEnabledUser.SamAccountName;
            Name = $ReEnabledUser.Name;
            Enabled = $ReEnabledUser.Enabled;
            'OU Path' = $ReEnabledUser.CanonicalName;
            'User Groups' = $ReEnabledUser.MemberOf;
        } )
    }

    if ($outGrid -ne $null) {
        $outGrid | Out-GridView -Title "ReEnabled AD Users" -Wait
    }   
    
}
#
# Function for restoring users from existing CSV files if they were exported
#
$restoreButton_Click = {

    # Getting a valid password for the users
    $LoginPassword = ""
    $SecurePassword = $null
    while ($LoginPassword -eq "" -or $LoginPassword -notmatch ("\d\d\d\d\d\d")) {
        $PassInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter first login password:", "ReEnable Users Script", " ")
        $LoginPassword = $PassInput.Trim()

        if ($PassInput -eq "") {
            Return
        } else {
            $SecurePassword = (ConvertTo-SecureString $LoginPassword -AsPlainText -Force)
        } 
    }
     <#
    Looping through every user from file:
        1. Enabling the users
        2. Moving them the the OU we got from their files
        3. copying permissions to the users from their files
        4. Setting first login password
    #>
    foreach ($username in $UserNames) {
        $user = $null
        try {
            $user = Import-Csv -Path ..\$($username.UserName).csv
        } catch {
            [System.Windows.Forms.Messagebox]::Show("User $($username.UserName) doesn't have CSV file", "ReEnable Users Script")
            Return          
        }
        $ADUser = Get-ADUser -Identity $($username.UserName) -Property CanonicalName
        
        If ($ADUser -ne $null) {
            if ($ADUser.Enabled -eq $False) {
                $ADUser | Enable-ADAccount
            } 

            foreach ($group in $user) {

                try {
                    Add-ADPrincipalGroupMembership -Identity $group.UserName -MemberOf $group.SamAccountName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | 
                    Where-Object { $group.SamAccountName -ne "Domain Users" } | Out-Null;

                    Add-ADPrincipalGroupMembership -Identity $group.UserName -MemberOf $group.Name -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | 
                    Where-Object { $group.Name -ne "Domain Users" } | Out-Null;

                } catch {
                    $group | Select-Object UserName,SamAccountName,Name,GroupCategory,GroupScope | Export-Csv -Path .\FailedGroups.csv -Append -NoTypeInformation
                } 
            
                try {
                    $userOU = $null

                    if ($group.DistinguishedName -like "CN=*") {
                        $userOU = ($group.DistinguishedName -split ",",2)[1]
                    } else {
                        $userOU = ($group.DistinguishedName)[0]
                    }

                    Move-ADObject -Identity $ADUser -TargetPath $userOU
                } catch {}
                   
            }
            Set-ADAccountPassword -Identity $($username.UserName) -Reset -NewPassword $SecurePassword
            Set-ADUser -Identity $($username.UserName) -ChangePasswordAtLogon $True -CannotChangePassword $False -PasswordNeverExpires $False
            
        } 

        $ReEnabledUser = Get-ADUser -Identity $ADUser.SamAccountName -Properties CanonicalName,MemberOf -ErrorAction SilentlyContinue
        $outGrid += @( [PSCustomObject]@{
            UserName = $ReEnabledUser.SamAccountName;
            Name = $ReEnabledUser.Name;
            Enabled = $ReEnabledUser.Enabled;
            'OU Path' = $ReEnabledUser.CanonicalName;
            'User Groups' = $ReEnabledUser.MemberOf;
        } )
    }

    if ($outGrid -ne $null) {
        $outGrid | Out-GridView -Title "ReEnabled AD Users" -Wait
    }
}

# Checking if all user names from Users.csv exist in AD.
$bool = $True
$invalid = @()
foreach ($username in $UserNames) {
    try {
        Get-ADUser -Identity $username.UserName | Out-Null
    } catch {
        [void][System.Windows.Forms.Messagebox]::Show("Invalid Username: $($username.UserName)", "ReEnable Users Script")
        $invalid += @( [PSCustomObject]@{ "Invalid Usernames" = $($username.UserName);} )
        $bool = $False
    }
}
if ($bool -eq $False) {
    $invalid | Out-GridView -Title "ReEnable Users Script" -Wait
    Exit
}

# GUI Interface for the Script
$form = New-Object System.Windows.Forms.Form
$form.Text = "ReEnable Users Script"
$form.Size = New-Object System.Drawing.Size(300,140)
$form.StartPosition = "CenterScreen"

$Header = New-Object System.Windows.Forms.Label
$Header.Location = New-Object System.Drawing.Size(15,10)
$Header.Text = "Choose an Option:"
$Header.AutoSize = $true
$Header.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($Header)

$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Location = New-Object System.Drawing.Size(15,35)
$copyButton.Size = New-Object System.Drawing.Size(125,45)
$copyButton.Text = "Copy"
$copyButton.Font = "Microsoft Sans Serif,12"
$form.Controls.Add($copyButton)

$restoreButton = New-Object System.Windows.Forms.Button
$restoreButton.Location = New-Object System.Drawing.Size(145,35)
$restoreButton.Size = New-Object System.Drawing.Size(125,45)
$restoreButton.Text = "Restore"
$restoreButton.Font = "Microsoft Sans Serif,12"
$form.Controls.Add($restoreButton)

$copyButton.Add_Click($copyButton_Click)
$restoreButton.Add_Click($restoreButton_Click)

[void]$form.ShowDialog()
[void]$form.Dispose()

