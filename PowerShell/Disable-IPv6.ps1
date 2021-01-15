$computers = Get-ADComputer -Filter * -SearchBase "OU=Computers,OU=GOV,DC=GOV,DC=BOnline" | select Name

#$cred = Get-Credential

foreach ($pc in $computers) {
    #Set-Service -ComputerName $($pc.Name) -Name WinRM -StartupType Automatic -Status Running -Verbose -ErrorAction SilentlyContinue

    Invoke-Command -ComputerName $pc -Credential $cred -ScriptBlock { 
        try {
            Disable-NetAdapterBinding –InterfaceAlias “Ethernet” –ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        } 
        catch {}
        try {
            Disable-NetAdapterBinding –InterfaceAlias “Ethernet0” –ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        } 
        catch {}
        
        $reg = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters -Name DisabledComponents -ErrorAction SilentlyContinue
        if ($reg) {
            Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters -Name DisabledComponents -Value 0xffffffff
        } else {
            New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters -Name DisabledComponents -Value 0xffffffff
        }

        Netsh interface 6to4 set state disabled
        Netsh interface isatap set state disabled
        Netsh interface teredo set state disabled
    }
}
