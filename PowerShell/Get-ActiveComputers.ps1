Import-Module -Name ActiveDirectory

$computers = Get-Content -Path .\computers.txt

foreach ($pc in $computers) {
    $lastLogOn = (Get-ADComputer -Identity $pc -Properties LastLogOnDate).LastLogOnDate
    $loggedUser = $null
    $connection = $null
    if (Test-Connection -ComputerName $pc -Count 1 -Quiet) {
        $loggedUser = Get-WmiObject win32_computersystem -ComputerName $pc | Where-Object {$_.UserName -ne ''} | ForEach-Object {$_.UserName}
        $connection = "True"
    } else {
        $loggedUser = ""
        $connection = "False"
    }
    
    [PSCustomObject]@{
       'ComputerName' = $pc
       'LoggedUser' = $loggedUser
       'Connection' = $connection
       'LastLogOnDate' = $lastLogOn
               
    } | Export-Csv -Path .\TestedComputers.csv -NoTypeInformation -Append
}

