#Requires -Version 5.0
#Requires -Modules VMware.VimAutomation.Core,Posh-SSH

# Importing VMware and Posh-SSH modules
Import-Module -Name VMware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Clear-Host
Import-Module -Name Posh-SSH -ErrorAction SilentlyContinue

# Function for connecting to vmware servers and creating and active session with the specified server
Function Connect-VMwareServer {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (Test-Connection -ComputerName $_ -Quiet -Count 1) {
                $true
            } else {
                throw "Could not connect to $_"
            }
        })]
        [string[]]$Server
    )

    foreach ($srv in $Server) {
        $cred = Get-Credential -Message "Enter VMware $srv server credentials:"
        if ($cred -ne $null) {
            Connect-VIServer -Server $srv -Credential $cred -Verbose
        }
    }
}

# Function from disconnecting from a specific server and closing the session with the server
Function Disconnect-VMwareServer {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if ((Test-Connection -ComputerName $_ -Quiet -Count 1)) {
                $true
            } elseif ($_ -eq "*") {
                $true
            } else {
                throw "Could not connect to $_"
            }
        })]
        [string[]]$Server
    )

    if ($Server -eq "*") {
        Disconnect-VIServer -Server $Server -Force -Confirm:$false -Verbose
    } else {
        foreach ($srv in $Server) {
            Disconnect-VIServer -Server $srv -Force -Confirm:$false -Verbose
        }
    }
    
}

# Function for getting all powered on virtuals machines from VMware server by their operating system
Function Get-VirtualMachines {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (Test-Connection -ComputerName $_ -Quiet -Count 1) {
                $true
            } else {
                throw "Could not connect to $_"
            }
        })]
        [string[]]$Server,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('All', 'Windows', 'Linux')]
        [string[]]$OperatingSystem,

        [Parameter()]
        [string]$Domain = "*",

        [Parameter()]
        [ValidateScript({
            if (Test-Path -Path $_ -PathType Container) {
                $True
            } else {
                throw "Could not find $_"
            }
        })]
        [string]$ExportPath = ""

    )
        if ($OperatingSystem -eq "All") {$OS = "*"} else {$OS = $OperatingSystem}
        $VMs = $null
        if ($OS -eq "Linux") {
            $VMs = Get-VM -Server $Server | Where-Object { $_.Guest -notlike "*Windows*" -and $_.PowerState -eq "PoweredOn" -and $_.guest.IPAddress[0] -ne $null -and $_.Guest.HostName -like "*$Domain*" } |
            Select-Object Name,PowerState,VMHost,@{Name="OperatingSystem";Expression={@($_.Guest.OSFullName)}},@{Name="Domain";Expression={$Domain = $_.Guest.HostName -Split'\.'; ($Domain[1..($Domain.Count)] -Join'.').ToLower()}},@{Name="IPAddress";Expression={
                foreach ( $IP in $_.Guest.IPAddress) {
                    if ((($IP -like "10.*") -or ($IP -like "192.*")) -and (Test-Connection -ComputerName $IP -Count 1 -Quiet)) {
                        return $IP
                    }}
            }}
               
        } else {
            $VMs = Get-VM -Server $Server | Where-Object { $_.Guest -like "*$OS*" -and $_.PowerState -eq "PoweredOn" -and $_.guest.IPAddress[0] -ne $null -and $_.Guest.HostName -like "*$Domain*" } |
            Select-Object Name,PowerState,VMHost,@{Name="OperatingSystem";Expression={@($_.Guest.OSFullName)}},@{Name="Domain";Expression={$Domain = $_.Guest.HostName -Split'\.'; ($Domain[1..($Domain.Count)] -Join'.').ToLower()}},@{Name="IPAddress";Expression={
            foreach ( $IP in $_.Guest.IPAddress) {
                    if ((($IP -like "10.*") -or ($IP -like "192.*")) -and (Test-Connection -ComputerName $IP -Count 1 -Quiet)) {
                        return $IP
                    }}
            }}
        }
        $VMs | Format-Table -AutoSize -Wrap
        
        if ($ExportPath -ne "") {
            $DataCenter = Get-Datacenter -Server $Server

            foreach ($vm in $VMs) {
                if (-not (Test-Connection -ComputerName $($vm.IPAddress) -Count 1 -Quiet)) {
                    Write-Verbose -Message "Could not test connection to $($vm.Name) IP: $($vm.IPAddress)" -Verbose
                }
            }

            foreach ($dc in $DataCenter) {
                if (-not (Test-Path -Path "$ExportPath\$dc" -PathType Container)) {
                    New-Item -Name $dc -Path $ExportPath -ItemType Directory -Force | Out-Null
                }
                if ($Domain.Length -ne 1) {
                    if (-not (Test-Path -Path "$ExportPath\$dc\$Domain" -PathType Container)) {
                        New-Item -Name $Domain -Path "$ExportPath\$dc" -ItemType Directory -Force | Out-Null
                    }
                }
            }

            if ($ExportPath -eq ".\") {$ExportPath = (Get-Location).Path}
            
            if ($Domain -match "\*") {
                foreach ($dc in $DataCenter) {
                    Write-Verbose -Message "Exporting $($OperatingSystem) Virtual Machines Names and IP Addresses to $ExportPath\$dc\$($OperatingSystem)VirtualMachines.csv" -Verbose
                }
                foreach ($vm in $VMs) {
                    $dc = Get-Datacenter -Server $(($vm.VMHost).Uid.Split('@').Split(':')[1])
                    $vm | Select-Object Name,IPAddress | Export-Csv -Path "$ExportPath\$dc\$($OperatingSystem)VirtualMachines.csv" -Append -NoTypeInformation
                }

            } else {
                foreach ($dc in $DataCenter) {
                    Write-Verbose -Message "Exporting $($OperatingSystem) Virtual Machines Names and IP Addresses to $ExportPath\$dc\$Domain\$($OperatingSystem)VirtualMachines.csv" -Verbose
                }
                foreach ($vm in $VMs) {
                    $dc = Get-Datacenter -Server $(($vm.VMHost).Uid.Split('@').Split(':')[1])
                    $vm | Select-Object Name,IPAddress | Export-Csv -Path "$ExportPath\$dc\$Domain\$($OperatingSystem)VirtualMachines.csv" -Append -NoTypeInformation
                }
            }
        }
}


# Function for getting the DST and current time from linux servers.
Function Get-LinuxDST {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (Test-Path -Path $_ -PathType Leaf) {
                $True
            } else {
                throw "Could not find $_"
            }
        })]      
        [string]$FilePath
    )
    
    begin {
        #$Servers = Get-Content -Path $FilePath
        Get-SSHSession | Remove-SSHSession -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
        $Servers = Import-Csv -Path $FilePath
        $credDef = Get-Credential -UserName root -Message "Enter the default credentials for linux servers:"
        $credLinux = $null

        if ($credDef -eq $null) {
            Break
        }

        Function Get-DST {
            param(
                [String]$IPAddress,
                [String]$ServerName,
                [System.Management.Automation.PSCredential]$Credential
            )
            $year = (Get-Date).Year
            $dst = $null
            $bool = $true
            while ($bool) {
                try {
                    New-SSHSession -ComputerName $IPAddress -Credential $Credential -Force -ConnectionTimeout 30 -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
                    if (Get-SSHSession -Server $IPAddress) {
                        $bool = $false
                    }
                } catch {
                    $Credential = Get-Credential -Message "Enter $ServerName $IPAddress credentials:" -UserName root
                    if ($Credential -eq $null) {
                        $bool = $false
                    }
                }
            }
            $session = Get-SSHSession -Server $IPAddress
            if ($session -ne $null) {
                Write-Verbose -Message "Connected to $IPAddress" -Verbose

                if ((Get-Date).Month -lt 6) {
                    $dstZero = $($($((Invoke-SSHCommand -SSHSession $session -Command "zdump -v /etc/localtime | grep $year").Output[0]) -replace "/etc/localtime  " -replace " isdst=0 gmtoff=7200").Split("="))[1].TrimStart(" ")
                    $dstOne = $($($((Invoke-SSHCommand -SSHSession $session -Command "zdump -v /etc/localtime | grep $year").Output[1]) -replace "/etc/localtime  " -replace " isdst=1 gmtoff=10800").Split("="))[1].TrimStart(" ")
                    $dst = "$dstZero - $dstOne"
                } else {
                    $dstTwo = $($($((Invoke-SSHCommand -SSHSession $session -Command "zdump -v /etc/localtime | grep $year").Output[2]) -replace "/etc/localtime  " -replace " isdst=1 gmtoff=10800").Split("="))[1].TrimStart(" ")
                    $dstThree = $($($((Invoke-SSHCommand -SSHSession $session -Command "zdump -v /etc/localtime | grep $year").Output[3]) -replace "/etc/localtime  " -replace " isdst=0 gmtoff=7200").Split("="))[1].TrimStart(" ")
                    $dst = "$dstTwo - $dstThree"
                }
                
                $name = (Invoke-SSHCommand -SSHSession $session -Command "hostname").Output
                $date = (Invoke-SSHCommand -SSHSession $session -Command "date").Output
                $localDate = Get-Date -Format "ddd MMM d HH:mm:ss yyyy"

            } else {
                Write-Verbose -Message "Failed to connect to $IPAddress" -Verbose
                $name = $ServerName
            }

            if ($FilePath -eq ".\") {$FilePath = (Get-Location).Path}
            $ExportPath = $FilePath.Substring(0, $FilePath.LastIndexOf('\'))

            if ($session -ne $null) { Write-Verbose -Message "Exporting $IPAddress DST info..." -Verbose }
            [PSCustomObject]@{
                ComputerName = $($name);
                IPAddress = $IPAddress;
                StandardChangeDate = $($dst);
                CurrentTime = $($date);
                LocalComputerTime = $($localDate);
            } | Export-Csv -Path "$ExportPath\LinuxDSTInformation.csv" -NoTypeInformation -Append -Force
            
            if ($session -ne $null) {
                Remove-SSHSession -SSHSession $session | Out-Null
                if ((Get-SSHSession -Server $IPAddress) -eq $null) {
                    Write-Verbose -Message "Disconnected from $IPAddress" -Verbose
                } else {
                    Write-Verbose -Message "Failed to disconnect from $IPAddress, session may still be open" -Verbose
                }
            }
        }
    }
    process {
        foreach ($Server in $Servers) {
            $serverIP = $($Server.IPAddress)
            $serverName = $($Server.Name)
            $checkConn = New-SSHSession -ComputerName $serverIP -Force -ConnectionTimeout 30 -WarningAction SilentlyContinue -Credential $credDef 2>&1
            $checkCred = $checkConn.Exception.Message
            if ((Get-SSHSession).Host -ne $null) {Remove-SSHSession -SSHSession (Get-SSHSession -Server $serverIP) | Out-Null}

            if ($checkCred -like "*Permission denied (*)*") {
                $credLinux = Get-Credential -Message "Enter $serverName $serverIP credentials:" -UserName root
                if ($credLinux -eq $null) {
                    Write-Verbose -Message "Failed to connect to $serverIP" -Verbose
                    $ExportPath = $FilePath.Substring(0, $FilePath.LastIndexOf('\'))
                    [PSCustomObject]@{
                    ComputerName = $serverName;
                    IPAddress = $serverIP;
                    StandardChangeDate = $null;
                    CurrentTime = $null;
                    } | Export-Csv -Path "$ExportPath\LinuxDSTInformation.csv" -NoTypeInformation -Append -Force
                    Continue
                }
                Get-DST -IPAddress $serverIP -ServerName $serverName -Credential $credLinux
            } else {
                $credLinux = $credDef
                Get-DST -IPAddress $serverIP -ServerName $serverName -Credential $credLinux
            }
        }
    }
}

# Function for getting the DST and current time from windows servers.
Function Get-WindowsDST {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (Test-Path -Path $_ -PathType Leaf) {
                $True
            } else {
                throw "Could not find $_"
            }
        })] 
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    if (Test-Path -Path .\Function-Get-WindowsDSTinfo.ps1) {
        . .\Function-Get-WindowsDSTinfo.ps1
        $servers = Import-Csv -Path $FilePath
        $serversIP = $servers.IPAddress
        $ExportPath = $FilePath.Substring(0, $FilePath.LastIndexOf('\'))
        $serversIP | Function-Get-WindowsDSTinfo -Credential $Credential | Select-Object IPAddress,ComputerName,StandardChangeDate,CurrentTime,LocalComputerTime | Export-Csv -Path "$ExportPath\WindowsDSTInformation.csv" -NoTypeInformation

    } else {
        Write-Verbose -Message "Could not find Get-WindowsDSTinfo.ps1 script for getting windows servers DST"
    }
}

# Function for checking if the servers in the DST files are online and up.
Function Check-ConnectionToServers {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (Test-Path -Path $_ -PathType Leaf) {
                $True
            } else {
                throw "Could not find $_"
            }
        })]      
        [string]$FilePath,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Windows', 'Linux')]
        [string[]]$OperatingSystem

    )

    $Servers = Import-Csv -Path $FilePath
    $ExportPath = $FilePath.Substring(0, $FilePath.LastIndexOf('\'))
    $credAdmin = $null
    if ($OperatingSystem -eq "Windows") {
        $credAdmin = Get-Credential -Message "Enter administrator credentials for the servers"
    }
    
    foreach ($srv in $Servers) {
        $ip = $($srv.IPAddress)
        Write-Verbose "Checking $ip" -Verbose
        if (Test-Connection -ComputerName $ip -Count 2 -Quiet) {
            if ($OperatingSystem -eq "Windows") {
                Get-Wmiobject -Class "Win32_ComputerSystem" -ComputerName $ip -Credential $credAdmin | Select-Object @{Name="IPAddress";Expression={$ip}},Name,@{Name="ConnectionToServer";Expression={"True"}},Domain | Export-Csv -Path "$ExportPath\WindowsServersConnectionCheck.csv" -NoTypeInformation -Append
            } elseif ($OperatingSystem -eq "Linux") {
                $ip | Select-Object @{Name="IPAddress";Expression={$ip}},@{Name="Name";Expression={$($srv.Name)}},@{Name="ConnectionToServer";Expression={"True"}},@{Name="Domain";Expression={"$null"}} | Export-Csv -Path "$ExportPath\LinuxServersConnectionCheck.csv" -NoTypeInformation -Append
            }
        } else {
            if ($OperatingSystem -eq "Windows") {
                $ip | Select-Object @{Name="IPAddress";Expression={$ip}},@{Name="Name";Expression={$($srv.Name)}},@{Name="ConnectionToServer";Expression={"False"}}@{Name="Domain";Expression={"$null"}} | Export-Csv -Path "$ExportPath\WindowsServersConnectionCheck.csv" -NoTypeInformation -Append
            } elseif ($OperatingSystem -eq "Linux") {
                $ip | Select-Object @{Name="IPAddress";Expression={$ip}},@{Name="Name";Expression={$($srv.Name)}},@{Name="ConnectionToServer";Expression={"False"}}@{Name="Domain";Expression={"$null"}} | Export-Csv -Path "$ExportPath\LinuxServersConnectionCheck.csv" -NoTypeInformation -Append
            }
        }
    }
}