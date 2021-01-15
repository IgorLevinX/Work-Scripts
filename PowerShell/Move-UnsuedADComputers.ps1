Import-Module -Name ActiveDirectory

$computers = Get-ADComputer -Filter {OperatingSystem -like "Windows*"} -SearchBase "OU_Path" -Properties OperatingSystem,LastLogonDate,WhenCreated,CanonicalName,DistinguishedName | 
Where-Object {$_.DistinguishedName -notlike "*Unused Workstations*" -and ($_.LastLogonDate -lt (Get-Date).AddMonths(-1) -and $_.WhenCreated -lt (Get-Date).AddMonths(-1))} | Select-Object Name,OperatingSystem,LastLogonDate,WhenCreated,CanonicalName,DistinguishedName
$computersList = @()

foreach ($computer in $computers) {
    $pc = $($computer.Name)
    if (-not (Test-Connection -ComputerName $pc -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host "$pc"
            $pcObj = Get-ADComputer -Identity $pc -ErrorAction SilentlyContinue
            Move-ADObject -Identity $pcObj -TargetPath "Unused Workstations"
            Disable-ADAccount -Identity $($pcObj.SamAccountName)

            $checkPC = Get-ADComputer -Identity $pc -ErrorAction SilentlyContinue
            if ($checkPC.Enabled -eq $false -or $checkPC.DistinguishedName.Contains("Unused Workstations") -eq $true) {
                $computersList += $computer
            }
    }
}

if ($computersList.Length -gt 0) {
    $computersList | Select-Object Name,OperatingSystem,LastLogonDate,WhenCreated,CanonicalName,DistinguishedName | Export-Csv -Path ".\UnusedADComputers.csv" -Force -NoTypeInformation
    Send-MailMessage -UseSsl -From 'username@domain' -To 'username@domain' -Subject 'Unusued AD Computers Objects' -Attachments ".\UnusedADComputers.csv" -SmtpServer 'smtp_server' -Port 'port_number'
    Remove-Item -Path ".\UnusedADComputers.csv" -Force
}
