Import-Module -Name ActiveDirectory
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

$loggedUser = cmd.exe /c "whoami"
$time = Get-Date -Format "dd/MM/yyyy HH:mm"

$users = Import-Csv -Path .\MGMTUsers.csv

$exitScript = $False
$userExist = 0
$outGrid = @() 
foreach ($user in $users) {    
    try {
        $exist = Get-ADUser -Identity $user.UserName.Trim() -Properties CanonicalName -ErrorAction SilentlyContinue
    } catch {}

    If ($exist -eq $null) {} 
    else {
        $outGrid += @( [PSCustomObject]@{
            UserName = $exist.SamAccountName;
            Name = $exist.Name;
            'OU Path' = $exist.CanonicalName;
        } )
        $exitScript = $True
        $userExist++  
        $exist = $null
    }
}

if ($exitScript) {
    [void][System.Windows.Forms.Messagebox]::Show("Number of existing AD users: $userExist", "New ADUsers")
    $outGrid | Out-GridView -Title "Existing AD Users" -Wait
    Exit
}

[String]$CopyUserOU = ""
$CopyUserCN = ""
$CopyUser = $null
while ($CopyUserOU -eq "") {
    $UserInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter user to copy:", "New ADUsers", " ")
    $UserName = [string]$UserInput.Trim()

    if ($UserInput -eq '') {
        Exit
    }
    try {
        $CopyUser = Get-ADUser -Identity $UserName -Property CanonicalName -ErrorAction SilentlyContinue
    } catch {
        if ($UserInput -ne " ") {
            [void][System.Windows.Forms.Messagebox]::Show("Invalid Username: $UserName", "New ADUsers")
        }
        $CopyUser = ""
        Continue
    }
    $CopyUserOU = ($CopyUser.DistinguishedName -split ",",2)[1]
    $CopyUserC = $CopyUser.CanonicalName -split ‘/’
    $CopyUserCN = $CopyUserC[0..($CopyUserC.Count – 2)] -join ‘/’
}

$LoginPassword = ""
while ($LoginPassword -eq "" -or $LoginPassword -notmatch ("\d\d\d\d\d\d")) {
    $PassInput = [Microsoft.VisualBasic.Interaction]::InputBox("Enter first login password:", "New ADUsers", " ")
    $LoginPassword = $PassInput.Trim()

    if ($PassInput -eq '') {
        Exit
    }
}

$num = 0
foreach ($user in $users) {

    $NewUser = @{
        SamAccountName = $user.UserName.Trim();
        GivenName = $user.FirstName;
        SurName = $user.LastName;
        Name = $user.FullName;
        DisplayName = $user.FullName;
        UserPrincipalName = $user.UserName + "@domain";
        EmployeeID = $user.EmployeeID
        EmployeeNumber = $user.EmployeeNumber
        AccountPassword = (ConvertTo-SecureString $LoginPassword -AsPlainText -Force);
        Enabled = $True;
        Path = $CopyUserOU;
        ChangePasswordAtLogon = $True;
        PasswordNeverExpires = $False;
        CannotChangePassword = $False;
        City = $user.City;
        Office = $user.City;
        Company = $user.Company;
        Organization = $user.Company;
        OtherName  = $user.HebrewName;
        Country = "IL";
        Department = $user.Department;
        Division = $user.Division;
        Title = $user.Title;
        OfficePhone = if ($user.OfficePhone -gt 0) {$user.OfficePhone} else {$null}
        MobilePhone = if ($user.MobilePhone -gt 0) {$user.MobilePhone} else {$null}
    }
    
    New-ADUser @NewUser
    
    $CreatedUser = Get-ADUser -Identity $NewUser.SamAccountName -Properties CanonicalName

    if ($user.Email -ne $null) {
        Set-ADUser -Identity $NewUser.SamAccountName -EmailAddress $user.Email
        Set-ADUser $NewUser.SamAccountName -Add @{proxyAddresses="SMTP:"+ $NewUser.SamAccountName + "@domain"}
        Set-ADUser $NewUser.SamAccountName -Add @{targetAddress="SMTP:"+ $NewUser.SamAccountName +"@domain"}
    }

    Get-ADPrincipalGroupMembership -Identity $CopyUser | Where-Object {$_.SamAccountName -ne "Domain Users" -or $_.Name -ne "Domain Users"} | 
    ForEach-Object { 
        Add-ADPrincipalGroupMembership -Identity $CreatedUser -MemberOf $_.SamAccountName -ErrorAction SilentlyContinue | Out-Null; 
        Add-ADPrincipalGroupMembership -Identity $CreatedUser -MemberOf $_.Name -ErrorAction SilentlyContinue | Out-Null;
    }

    $CreatedUser = Get-ADUser -Identity $NewUser.SamAccountName -Properties CanonicalName,MemberOf

    $CreatedUser | Select-Object SamAccountName,Enabled,CanonicalName,MemberOf | Format-List
    $CreatedUser | Select-Object SamAccountName,Enabled,CanonicalName,@{Name="Creation Date";Expression={Get-Date -Format "dd/MM/yyyy HH:mm"}},@{Name="User's OU Path";Expression={$ADuser.CanonicalName}} | 
    Export-Csv ".\CreatedUsers.csv" -Append -NoTypeInformation
    $CreatedUser | Select-Object SamAccountName,Enabled,CanonicalName,@{Name="Creation Date";Expression={Get-Date -Format "dd/MM/yyyy HH:mm"}},@{Name="User's OU Path";Expression={$ADuser.CanonicalName}} | 
    Export-Csv "C:\temp\NewUsers.csv" -Append -NoTypeInformation

    if ($CreatedUser) {
        $num++
        $outGrid += @( [PSCustomObject]@{
            UserName = $CreatedUser.SamAccountName;
            Name = $CreatedUser.Name;
            'OU Path' = $CreatedUser.CanonicalName;
            'User Groups' = $CreatedUser.MemberOf;
        } )
    }
}

if ($num -ne 0 ) {
    [void] [System.Windows.Forms.Messagebox]::Show("Users created: $num `nUsers OU: $CopyUserCN", "New ADUsers")

    if ($outGrid -ne $null) {
        $outGrid | Out-GridView -Title "New AD Users" -Wait
        }
}
