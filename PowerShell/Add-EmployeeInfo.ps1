Import-Module -Name ActiveDirectory

$usersinfo = Import-Csv -Path .\usersinfo.csv -Encoding UTF8

# Function to check if there is info to add to users.
Function Add-Info {
    param([string]$UserName, [string]$UserInfo, [string]$Attribute)
    
    if ($user.$Attribute -gt 0) {
        $user.$Attribute
    } elseif ($UserInfo -ne $null) {
        $UserInfo
    } else {
        $null
    }
}

# Loop throught all users in file and add them the info written there
foreach ($user in $usersinfo) {
    $ADuser = Get-ADuser -Identity $user.Username -Properties *

    # Hash tale for adding the info from the file to the relevant parameter.
    $info = @{
        Identity = $ADuser.SamAccountName;
        EmployeeID = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.EmployeeID -Attribute 'EmployeeID';
        EmployeeNumber = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.EmployeeNumber -Attribute 'EmployeeNumber';
        City = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.City -Attribute 'City';
        Office = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.Office -Attribute 'City';
        Company = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.Company -Attribute 'Company';
        Organization = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.Organization -Attribute 'Company';
        OtherName  = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.OtherName -Attribute 'HebrewName';
        Department = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.Department -Attribute 'Department';
        Division = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.Division -Attribute 'Division';
        Title = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.Title -Attribute 'Title';
        OfficePhone = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.OfficePhone -Attribute 'OfficePhone';
        MobilePhone = Add-Info -UserName $ADuser.SamAccountName -UserInfo $ADuser.MobilePhone -Attribute 'MobilePhone';
        Country = "IL";
    }
    # Spllating the hash table on the Set-ADUser command to add the info the the user.
    Set-ADUser @info

    # Priniting to screen the user info after adding it from the file.
    Get-ADUser -Identity $ADuser.SamAccountName -Properties EmployeeID,EmployeeNumber,OtherName,OfficePhone,MobilePhone,Title,Office,Department,Division,Company,City,Country | 
    Select-Object SamAccountName,Name,EmployeeID,EmployeeNumber,OtherName,Title,Office,OfficePhone,MobilePhone,Department,Division,Company,City,Country
}

