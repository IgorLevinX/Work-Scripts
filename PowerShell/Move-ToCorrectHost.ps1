#Requires -Version 5.0
#Requires -Modules VMware.VimAutomation.Core
Import-Module -Name VMware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Clear-Host

# Enter admin credentials for VCenter enviroment
$cred = Get-Credential
# Add VCenter IP Address
$server = ""
# Add virtual machines CSV file for importing to the script
$file = Import-Csv -Path ".\VM_Hosts.csv"
# Connecting to VCenter enviromet using the VCenter IP address and credentials from before
Connect-VIServer -Server $server -Credential $cred -Verbose

# Looping on all virtual machines from the CSV file for cheking if the machines in the correct ESXi host
# If not moving them to the ESXi host written in the file
foreach ($vm in $file) {
    $vmName = $vm.Name
    $vmHost = $vm.VMHost
    $vmRTHost = (Get-VM -Name $vmName).VMHost
    if ($vmHost -ne $vmRTHost) {
        Get-VM -Name $vmName | Move-VM -Destination $vmHost -VMotionPriority High -Verbose | Out-Null
    }
    Get-VM -Name $vmName | Select-Object Name,VMHost
}

# Getting the virtual machines from the VCenter and checking and exporting if the virtual machines are in the correct ESXi host after previous proccess.
Get-VM | Select-Object Name,VMHost,@{Name="VMHost_Equal";Expression={ $_ | ForEach-Object {if ($file.Name -contains $_.Name) {
    $text = ($file | Select-String -Pattern "=$($_.Name);").ToString()
    $VMhostName = $text.split(';')[1].split('=')[1]
    $vmh = (Get-VM -Name $_.Name).VMHost
    if ($VMhostName -eq $_.VMHost) {
        return "True"
    } else {
        return "False"
    }
} else {return "file not containing $($_.Name)"}}}} | 
Sort-Object -Property VMHost | Export-Csv -Path .\VM_Correct_Hosts.csv -NoTypeInformation