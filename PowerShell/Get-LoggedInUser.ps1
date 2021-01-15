[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

cls
$pc = [Microsoft.VisualBasic.Interaction]::InputBox("Enter computer name:", "LoggedIn")

if ($pc) {
    if (Test-Connection -ComputerName $pc -Count 1 -Quiet) {
    $log = Get-WmiObject win32_computersystem -ComputerName $pc | Where-Object {$_.UserName -ne ''} | ForEach-Object {$_.UserName}

        if ($log) {
            [System.Windows.Forms.Messagebox]::Show("The connected user is: " + $log, "LoggedIn")
        } else {
            [System.Windows.Forms.Messagebox]::Show("No user is connected", "LoggedIn")
        }

    } else {
        [System.Windows.Forms.Messagebox]::Show("Computer not found", "LoggedIn")
        cls
    }
}




