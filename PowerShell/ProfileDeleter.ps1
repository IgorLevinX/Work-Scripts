Add-Type -AssemblyName System.Windows.Forms   
Add-Type -AssemblyName System.Drawing

$deleteProfilesR_Click = {
    $pc = $textBox.Text
    $loggedUser = Get-WmiObject Win32_ComputerSystem -ComputerName $pc | Where-Object {$_.UserName -ne ''} | ForEach-Object {$_.UserName}
    $user = $loggedUser -creplace '^[^\\]*\\', ''
    $userprofile = Get-WmiObject -Class Win32_UserProfile -ComputerName $pc | Where-Object {$_.LocalPath -like "*$user*"} | Select-Object LocalPath

    if ($user -like "Administrator*") {        
        try {
            Get-WmiObject -Class Win32_UserProfile -ComputerName $pc | Where-Object {!$_.Special -and $_.LocalPath -ne "C:\Users\Administrator" -and $_.LocalPath -notlike "*$user*"} | Remove-WmiObject -ErrorAction SilentlyContinue -Verbose
        } catch {}
                
        Get-WmiObject -Class Win32_UserProfile -ComputerName $pc | Where-Object {!$_.Special} | Select-Object LocalPath | Out-GridView -Title "Profile Deleter"
        [System.Windows.Forms.MessageBox]::Show("Profiles deleted on $pc","Profiles Deletion Script")
        
    } elseif ($userprofile -ne "") {
       try {
            Get-WmiObject -Class Win32_UserProfile -ComputerName $pc | Where-Object {!$_.Special -and $_.LocalPath -ne "C:\Users\Administrator" -and $_.LocalPath -notlike "*$user*"} | Remove-WmiObject -ErrorAction SilentlyContinue -Verbose
        } catch {}
        
        Get-WmiObject -Class Win32_UserProfile -ComputerName $pc | Where-Object {!$_.Special} | Select-Object LocalPath | Out-GridView -Title "Profile Deleter"
        [System.Windows.Forms.MessageBox]::Show("Profiles were deleted execpt $user on $pc","Profiles Deletion Script")
    
    } else {
      [System.Windows.Forms.MessageBox]::Show("Error: could not delete profiles on $pc","Profiles Deletion Script")  
    } 

}

$ZCMHistoryR_Click = {
    $pc = $textBox.Text

    try {
        Set-Service -ComputerName $pc -Name "RemoteRegistry" -Status Running
        Reg Delete "\\$pc\HKEY_LOCAL_MACHINE\SOFTWARE\Novell\ZCM\ZenLgn\History\Cache\bezeqonline.corp" /VA /F
        Set-Service -ComputerName $pc -Name "RemoteRegistry" -Status Stopped
        [System.Windows.Forms.MessageBox]::Show("ZCM history login has been deleted on $pc","Profiles Deletion Script")

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error: coud not delete ZCM history login","Profiles Deletion Script")
    }
}

$CheckConnection_Click = {
    $pc = $textBox.Text

    if (Test-Connection -ComputerName $pc -Count 1 -Quiet) {
        Start-Process CMD -ArgumentList "/K Ping -t $pc" 
    } else {
        [System.Windows.Forms.MessageBox]::Show("Error: computer not found","Profiles Deletion Script")
    }
}

$deleteProfilesL_Click = { 
    $loggedUser = Get-WmiObject Win32_ComputerSystem | Where-Object {$_.UserName -ne ''} | ForEach-Object {$_.UserName}
    $user = $loggedUser -creplace '^[^\\]*\\', ''
    $userprofile = Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.LocalPath -like "*$user*"} | Select-Object LocalPath

    if ($user -like "Administrator*") {        
        try {
            Get-WmiObject -Class Win32_UserProfile | Where-Object {!$_.Special -and $_.LocalPath -ne "C:\Users\Administrator" -and $_.LocalPath -notlike "*$user*"} | Remove-WmiObject -ErrorAction SilentlyContinue -Verbose
        } catch {}        
        [System.Windows.Forms.MessageBox]::Show("Profiles deleted","Profiles Deletion Script")
        rundll32 sysdm.cpl,EditUserProfiles
        
    } elseif ($userprofile -ne "") {
       try {
            Get-WmiObject -Class Win32_UserProfile | Where-Object {!$_.Special -and $_.LocalPath -ne "C:\Users\Administrator" -and $_.LocalPath -notlike "*$user*"} | Remove-WmiObject -ErrorAction SilentlyContinue -Verbose
        } catch {} 
        [System.Windows.Forms.MessageBox]::Show("Profiles were deleted execpt $user","Profiles Deletion Script")
        rundll32 sysdm.cpl,EditUserProfiles
    
    } else {
      [System.Windows.Forms.MessageBox]::Show("Error: could not delete profiles","Profiles Deletion Script")  
    } 
}

$ZCMHistoryL_Click = {
    try {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Novell\ZCM\ZenLgn\History\Cache\bezeqonline.corp" -Name *
        [System.Windows.Forms.MessageBox]::Show("ZCM history login has been deleted","Profiles Deletion Script")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error: could not delete ZCM history login","Profiles Deletion Script")  
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Profiles Deletion Script"
$form.Size = New-Object System.Drawing.Size(565,280)
$form.StartPosition = "CenterScreen"

$RemoteHeader = New-Object System.Windows.Forms.Label
$RemoteHeader.Location = New-Object System.Drawing.Size(20,20)
$RemoteHeader.Text = "Remote Computer Profiles:"
$RemoteHeader.AutoSize = $true
$RemoteHeader.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($RemoteHeader)

$RemotePCBox = New-Object System.Windows.Forms.Label
$RemotePCBox.Location = New-Object System.Drawing.Size(20,50)
$RemotePCBox.Text = "Enter Remote Computer Name:"
$RemotePCBox.AutoSize = $true
$RemotePCBox.Font = "Microsoft Sans Serif,9.5"
$form.Controls.Add($RemotePCBox)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Size(210,50)
$textBox.AutoSize = $true
$textBox.Width = 200
$textBox.Font = "Microsoft Sans Serif,10"
$form.Controls.Add($textBox)

$line = New-Object System.Windows.Forms.Label
$line.Location = New-Object System.Drawing.Size(10,140)
$line.Text = ""
$line.AutoSize = $false
$line.Width = 560
$line.Height = 2
$line.BorderStyle =  [System.Windows.Forms.BorderStyle]::Fixed3D
$form.Controls.Add($line)
    
$deleteProfilesR = New-Object System.Windows.Forms.Button
$deleteProfilesR.Location = New-Object System.Drawing.Size(20,90)
$deleteProfilesR.Size = New-Object System.Drawing.Size(150,30)
$deleteProfilesR.Text = "Delete Profiles"
$deleteProfilesR.Font = "Microsoft Sans Serif,11"
$form.Controls.Add($deleteProfilesR)

$ZCMHistoryR = New-Object System.Windows.Forms.Button
$ZCMHistoryR.Location = New-Object System.Drawing.Size(198,90)
$ZCMHistoryR.Size = New-Object System.Drawing.Size(150,30)
$ZCMHistoryR.Text = "Delete ZCM History"
$ZCMHistoryR.Font = "Microsoft Sans Serif,11"
$form.Controls.Add($ZCMHistoryR)

$CheckConnection = New-Object System.Windows.Forms.Button
$CheckConnection.Location = New-Object System.Drawing.Size(375,90)
$CheckConnection.Size = New-Object System.Drawing.Size(150,30)
$CheckConnection.Text = "Check Connection"
$CheckConnection.Font = "Microsoft Sans Serif,11"
$form.Controls.Add($CheckConnection)

$LocalHeader = New-Object System.Windows.Forms.Label
$LocalHeader.Location = New-Object System.Drawing.Size(20,160)
$LocalHeader.Text = "Local Computer Profiles:"
$LocalHeader.AutoSize = $true
$LocalHeader.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($LocalHeader)

$deleteProfilesL = New-Object System.Windows.Forms.Button
$deleteProfilesL.Location = New-Object System.Drawing.Size(20,190)
$deleteProfilesL.Size = New-Object System.Drawing.Size(150,30)
$deleteProfilesL.Text = "Delete Profiles"
$deleteProfilesL.Font = "Microsoft Sans Serif,11"
$form.Controls.Add($deleteProfilesL)

$ZCMHistoryL = New-Object System.Windows.Forms.Button
$ZCMHistoryL.Location = New-Object System.Drawing.Size(198,190)
$ZCMHistoryL.Size = New-Object System.Drawing.Size(150,30)
$ZCMHistoryL.Text = "Delete ZCM History"
$ZCMHistoryL.Font = "Microsoft Sans Serif,11"
$form.Controls.Add($ZCMHistoryL)

$deleteProfilesR.Add_Click($deleteProfilesR_Click)
$ZCMHistoryR.Add_Click($ZCMHistoryR_Click)
$CheckConnection.Add_Click($CheckConnection_Click)
$deleteProfilesL.Add_Click($deleteProfilesL_Click)
$ZCMHistoryL.Add_Click($ZCMHistoryL_Click)
  
[void]$form.ShowDialog()
[void]$form.Dispose()

