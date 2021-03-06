
$computerName = Hostname
$IPAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null }).IPAddress | Select-Object -First 1
$recipients = ""
$newestImagePath = Get-Date (Get-Date).AddDays(-1) -Format "yyyyMMdd"
$oldFilesDate = Get-Date (Get-Date).AddYears(-2) -Format "yyyyMMdd"
$backupPath = ".\Dest"
$sourcePath = ".\Source"
$fullSourcePath = "$sourcePath\$newestImagePath"
$fullDestPath = "$backupPath\$newestImagePath"

# Backing up daily recordings
$backupPathCheck = Test-Path -Path $backupPath -PathType Container -ErrorAction SilentlyContinue
if (!$backupPathCheck) {             
    New-Item -ItemType directory -Path $backupPath
}
else {
    Send-MailMessage -UseSsl -From 'username@domain' -To $recipients -Subject "$($computerName) $($IPAddress) backup path does not exist" -Body "$($computerName) $($IPAddress) backup path does not exist" -SmtpServer 'smtp_server' -Port 'port_number'
    Start-Sleep -Seconds 5
    Exit
}

$fullSourcePathCheck = Test-Path -Path $fullSourcePath -PathType Container -ErrorAction SilentlyContinue
if (!$fullSourcePathCheck) {             
    New-Item -ItemType directory -Path $fullSourcePath
}
else {
    Send-MailMessage -UseSsl -From 'username@domain' -To $recipients -Subject "$($computerName) $($IPAddress) source path does not exist" -Body "$($computerName) $($IPAddress) source path does not exist" -SmtpServer 'smtp_server' -Port 'port_number'
    Start-Sleep -Seconds 5
    Exit
}

$fullDestPathCheck = Test-Path -Path $fullDestPath -PathType Container -ErrorAction SilentlyContinue
if (!$fullDestPathCheck) {             
    New-Item -ItemType directory -Path $fullDestPath
}
else {
    Send-MailMessage -UseSsl -From 'username@domain' -To $recipients -Subject "$($computerName) $($IPAddress) destination path does not exist" -Body "$($computerName) $($IPAddress) destination path does not exist" -SmtpServer 'smtp_server' -Port 'port_number'
    Start-Sleep -Seconds 5
    Exit
}

$sourceFilePath = Get-ChildItem $fullSourcePath -Recurse | Select-Object FullName, Name, Length, Directory 

foreach ($file in $sourceFilePath) {
    $testFile = Test-Path -Path "$fullDestPath\$($file.Name)" -ErrorAction SilentlyContinue
    if (!$testFile) {
        $fileDirectory = $fullDestPath + '\' + ($file.Directory.Name)
        $fileDirectoryCheck = Test-Path -Path $fileDirectory -PathType Container -ErrorAction SilentlyContinue
       
        if (!$fileDirectoryCheck) {
            New-Item -ItemType directory -Path $fileDirectory  
        }
       
        Copy-Item -Path $file.FullName -Destination $fileDirectory -Recurse -Force
    }
    else {
        Write-Host "file existed"
    }
}

#$destFilePath = Get-ChildItem $fullDestPath -Recurse | Select-Object FullName, Name, Length

$measureSource = Get-ChildItem $fullSourcePath -Recurse | Measure-Object -Property Length -Sum
$measureDest = Get-ChildItem $fullDestPath -Recurse | Measure-Object -Property Length -Sum

if (-not ($measureSource.Count -eq $measureDest.Count -and $measureSource.Sum -eq $measureDest.Sum)) {
    Send-MailMessage -UseSsl -From 'username@domain' -To $recipients -Subject "$($computerName) $($IPAddress) completed unsuccessfully" -Body "$($computerName) $($IPAddress) completed unsuccessfully" -SmtpServer 'smtp_server' -Port 'port_number'
}

# Remove old recordings
$backupPath = ".\Dest"
$sourcePath = ".\Source"

$oldSourceFolders = Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -lt $oldFilesDate } 
$oldDestFolders = Get-ChildItem -Path $backupPath | Where-Object { $_.Name -lt $oldFilesDate }

$oldSourceFiles = $oldSourceFolders | Get-ChildItem -Recurse | Select-Object FullName, Name, Length, Directory
$oldDestFiles = $oldDestFolders | Get-ChildItem -Recurse | Select-Object FullName, Name, Length, Directory

$measureSource = $oldSourceFiles | Measure-Object -Property Length -Sum
$measureDest = $oldDestFiles | Measure-Object -Property Length -Sum

$ifDeleted = $false
if ($measureSource.Count -eq $measureDest.Count -and $measureSource.Sum -eq $measureDest.Sum) {
    Write-Host "here"
    foreach ($folder in $oldSourceFolders) {
        Write-Host "$sourcePath\$folder"
        try {
            Remove-Item -Path "$sourcePath\$folder" -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            $ifDeleted = $true
        }
    }
}
else {
    Send-MailMessage -UseSsl -From 'username@domain' -To $recipients -Subject "$($computerName) $($IPAddress) the source and destination folders are not equal" -Body "$($computerName) $($IPAddress) the source and destination folders are not equal" -SmtpServer 'smtp_server' -Port 'port_number'
}

if ($ifDeleted) {
    Send-MailMessage -UseSsl -From 'username@domain' -To $recipients -Subject "$($computerName) $($IPAddress) could not delete old recordings folders" -Body "$($computerName) $($IPAddress) could not delete old recordings folders" -SmtpServer 'smtp_server' -Port 'port_number'
}
