#Requires -Version 5.0
#Requires -Modules VMware.VimAutomation.Core
Import-Module -Name VMware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Clear-Host

# Enter admin credentials for VCenter enviroment
$cred = Get-Credential
# Add VCenter server IP Address
$server = ""
# Add virtual machines CSV to import to the script
$file = Import-Csv -Path ".\VM_Locations.csv"
# Connecting to VCenter enviromet using the VCenter IP address and credentials from before
Connect-VIServer -Server $server -Credential $cred -Verbose
# Exporting virtual machines by VMHost to CSV file
Get-VM | Select-Object Name,VMHost | Sort-Object -Property VMHost | Export-Csv -Path .\VM_Hosts.csv