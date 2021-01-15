
# Permanent variables for script.
$computerName = Hostname
$IPAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIPGateway -ne $null}).IPAddress | Select-Object -First 1
$path = "D:\Records\voice"
$folder = Get-Date -Format "yyyyMMdd"
$fullPath = "$path\$folder"
$numOfFolders = (Get-ChildItem -Path $path\$folder | Measure-Object).Count
$currentTime = (Get-Date -Format "HH:mm")
$date = Get-Date -Format "D"
$numOfFiles = $null

# Variables to get the files by the following values as needed, As so can be changed as needed.
$morning = "09:00"
$noon = "13:00"
$evening = "19:00"
$saturdayEvening = "23:30"
$numOfFilesMorning = "10000"
$numOfFilesNoon = "25000"
$numOfFilesEvening = "40000"
$numOfFilesFridayNoon = "20000"
$numOfFilesSaturdayEvening = "6000"

# Function for checking the files and sending mail notifications.
Function Check-NumberOfRecordings {
Param(
    [String]$Path,
    [String]$Time,
    [String]$NumberOfExpectedFiles,
    [String]$NumberOfFolders
)
    $numOfFiles = (Get-ChildItem -Path "$Path\*.wav" -Recurse -Force | Where-Object {$_.LastWriteTime -le $Time} | Measure-Object).Count
    
    # Sends mail notification and sms when there is not enough files
    if ($numOfFiles -lt $NumberOfExpectedFiles) {
        $htmlMessage = @"
            <body style = "background-color :#CC3300">
            <h1 style="font-size:160%;font-family:verdana;text-align:center;">$($computerName) $($IPAddress) Low Recordings File Count Error</h1>
            <p style="font-size:125%;">Number of recording files on $($date) in $($Path) until $($Time): $numOfFiles</p>
            <p style="font-size:125%;">The expected number of files should be: $($NumberOfExpectedFiles)</p> 
            <p style="font-size:125%;">Number of folders on $($date) in $($Path) until $($Time): $($NumberOfFolders)</p>
            </body>
"@
        $messageBody = ConvertTo-Html -Body $htmlMessage -PostContent "<h4> script ran at $(Get-Date)</h4>" | Out-String

        Send-MailMessage -From 'username@domain' -To 'username@domain' -Subject "$($computerName) $($IPAddress) Count Error: Low Numbers of Recordings Files" -BodyAsHtml -Body $messageBody -SmtpServer 'smtp_server' -Port 'port_number'
        
        $SMS = @"
            $($computerName) $($IPAddress) Low Recordings File Count Error
            Number of recording files on $($date) in $($Path) until $($Time): $numOfFiles
            The expected number of files should be: $($NumberOfExpectedFiles)
            Number of folders on $($date) in $($Path) until $($Time): $($NumberOfFolders)
"@
        Invoke-WebRequest -Uri "" -Method POST        
        
    # Sends mail that everything is OK
    } else {
        $htmlMessage = @"
            <body>
            <h1 style="font-size:160%;font-family:verdana;text-align:center;">$($computerName) $($IPAddress) Recordings File Count</h1>
            <p style="font-size:125%;">Number of recording files on $($date) in $($Path) until $($Time): $numOfFiles</p>
            <p style="font-size:125%;">The expected number of files should be: $($NumberOfExpectedFiles)</p> 
            <p style="font-size:125%;">Number of folders on $($date) in $($Path) until $($Time): $($NumberOfFolders)</p>
            </body>
"@
        $messageBody = ConvertTo-Html -Body $htmlMessage -PostContent "<h4> script ran at $(Get-Date)</h4>" | Out-String

        Send-MailMessage -From 'username@domain' -To 'username@domain' -Subject "$($computerName) $($IPAddress) Count: Number of Recordings Files" -BodyAsHtml -Body $messageBody -SmtpServer 'smtp_server' -Port 'port_number'
        
    }
}

# The process to check the files using the function Check-NumberOfRecordings by date, time and number of files.
if (Test-Path -Path "$fullPath" -PathType Container) {
    $day = (Get-Date).DayOfWeek
    
    if ($day -eq "Friday") {
        Check-NumberOfRecordings -Path $fullPath -Time $noon -NumberOfExpectedFiles $numOfFilesFridayNoon -NumberOfFolders $numOfFolders
    
    } elseif ($day -eq "Saturday") {
        Check-NumberOfRecordings -Path $fullPath -Time $saturdayEvening -NumberOfExpectedFiles $numOfFilesSaturdayEvening -NumberOfFolders $numOfFolders
    
    } else {

        if ($currentTime -gt $morning -and $currentTime -lt $noon) {
            Check-NumberOfRecordings -Path $fullPath -Time $morning -NumberOfExpectedFiles $numOfFilesMorning -NumberOfFolders $numOfFolders

        } elseif ($currentTime -gt $noon -and $currentTime -lt $evening) {
            Check-NumberOfRecordings -Path $fullPath -Time $noon -NumberOfExpectedFiles $numOfFilesNoon -NumberOfFolders $numOfFolders

        } elseif ($currentTime -gt $evening) {
            Check-NumberOfRecordings -Path $fullPath -Time $evening -NumberOfExpectedFiles $numOfFilesEvening -NumberOfFolders $numOfFolders
        }
    }
} else {
    # Send mail notification and sms when the script can't find the folder
    $htmlMessage = @"
        <body style = "background-color :#CC3300">
        <h1 style="font-size:160%;font-family:verdana;text-align:center;">$($computerName) $($IPAddress) No Folder was Created or Found</h1>
        <p style="font-size:125%;">Folder not found in $($Path) on $($date)</p>
        </body>
"@
    $messageBody = ConvertTo-Html -Body $htmlMessage -PostContent "<h4> script ran at $(Get-Date)</h4>" | Out-String

    Send-MailMessage -From 'username@domain' -To 'username@domain' -Subject "$($computerName) $($IPAddress) Error: No Folder was Created or Found" -BodyAsHtml -Body $messageBody -SmtpServer 'smtp_server' -Port 'port_number'


    $SMS = @"
        $($computerName) $($IPAddress) No Folder was Created or Found
        Folder not found in $($Path) on $($date)
"@
    Invoke-WebRequest -Uri "" -Method POST        
        
}


