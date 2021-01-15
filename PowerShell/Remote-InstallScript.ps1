Clear-Host
$computers = Get-Content -Path .\Computers.txt
$status = @()

foreach ($computer in $computers) {
    try {
        $copyLocation = "\\$computer\C$"
        $tempInstall = "\\$computer\C$\DefaultInstallation.msi"
        $installFile = "\\Some_Share\DefaultInstallation.msi"
        $folderX86 = "\\$computer\C$\Program Files\Folder"
        $folderX64 = "\\$computer\C$\Program Files (x86)\Folder"

        Write-Host "$computer : " -BackgroundColor Yellow -ForegroundColor Blue
        if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {            
            $freeSpace = (Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computer -Filter "DeviceID='C:'"  | Select-Object @{n = "FreeSpace"; e = {[math]::Round($_.FreeSpace / 1GB, 2)}}).FreeSpace -lt 2
            if (!$freeSpace) {

                Write-Host "$computer : Starting copy of Installation file" -ForegroundColor Cyan
                try {
                    Copy-Item -Path $installFile -Destination $copyLocation -Force #| Out-Null
                } catch {
                    Write-Host "$computer : Copy of Installation file failed" -ForegroundColor Red
                }

                if (Test-Path -Path "$tempInstall") {  
                    Write-Host "$computer : Copy of Installation file was succesfull. Starting Installation" -ForegroundColor Cyan
                    Invoke-Command -ComputerName $computer -ScriptBlock {Start-Process msiexec.exe -Wait -ArgumentList "/I C:\DefaultInstallation.msi /norestart /qn"}
               
                    $os = (Get-WmiObject -Computer $computer -Class Win32_OperatingSystem).OSArchitecture
                    Start-Sleep -Seconds 30
                    $reg = $null

                    if ($os -eq "32-bit") {
                    
                        if ((Test-Path -Path "$folderX86\") -and (Test-Path -Path "$folderX86\")) {
                        
                            try {
                                Remove-Item -Path $tempInstall -Force
                            }
                            catch {
                                Write-Host "$computer : Could not remove installation file" -ForegroundColor Magenta
                            }

                            $status += @( [PSCustomObject]@{ "Computer Name" = $computer; "Installtion Status" = "Installation finished"; } )
                            Write-Host "$computer : Installation finished" -ForegroundColor Green
                        }

                        else {
                            $status += @( [PSCustomObject]@{ "Computer Name" = $computer; "Installtion Status" = "Installation failed"; } )
                            Write-Host "$computer : Installation failed" -ForegroundColor Red
                        }

                    }
                    elseif ($os -eq "64-bit") {

                        if ((Test-Path -Path "$folderX64\") -and (Test-Path -Path "$folderX64\") -and ($reg -eq $True)) {
                        
                            try {
                                Remove-Item -Path $tempInstall -Force
                            }
                            catch {
                                Write-Host "$computer : Could not remove installation file" -ForegroundColor Magenta
                            }

                            $status += @( [PSCustomObject]@{ "Computer Name" = $computer; "Installtion Status" = "Installation finished"; } )
                            Write-Host "$computer : Installation finished" -ForegroundColor Green
                        }

                        else {
                            $status += @( [PSCustomObject]@{ "Computer Name" = $computer; "Installtion Status" = "Installation failed"; } )                            
                            Write-Host "$computer : Installation failed" -ForegroundColor Red
                        }
                    }

                }
                else {
                    $status += @( [PSCustomObject]@{ "Computer Name" = $computer; "Installtion Status" = "Copy of Installation file failed"; } )                     
                    Write-Host "$computer : Copy of Installation file failed" -ForegroundColor Red
                }

            
            }
            else {
                $status += @( [PSCustomObject]@{ "Computer Name" = $computer; "Installtion Status" = "Not enough avaliable space"; } ) 
                Write-Host "$computer : Not enough avaliable space in $computer" -ForegroundColor Red
            }
        }
        else {
            $status += @( [PSCustomObject]@{ "Computer Name" = $computer; "Installtion Status" = "No Connection to computer"; } )
            Write-Host "$computer : No Connection to $computer" -ForegroundColor Red
        }
        Write-Host ""

    }
    catch {
        
    }
}
$status | Sort-Object -Property "Installtion Status" | Export-Csv -Path .\Installation.csv -NoTypeInformation -Append