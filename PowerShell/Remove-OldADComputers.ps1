Import-Module -Name ActiveDirectory

$computers = Get-ADComputer -Filter * -SearchBase "OU_Path" -Properties OperatingSystem,LastLogonDate,WhenCreated | Select-Object SamAccountName,Name,OperatingSystem,LastLogonDate,WhenCreated

foreach ($pc in $computers) {
    if (-not (Test-Connection -ComputerName $pc.Name -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        if (($pc.OperatingSystem -like "Windows 7*" -or $pc.OperatingSystem -like "Windows 10*") -and $pc.LastLogonDate -lt (Get-Date).AddMonths(-1) -and $pc.WhenCreated -lt (Get-Date).AddMonths(-1)) {
            Remove-ADComputer -Identity $pc.SamAccountName -Confirm:$false
        }
    }
}