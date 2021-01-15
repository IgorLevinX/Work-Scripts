# Original script not written by me (Igor Levin) but heavily edited by me for use as a function to run on remote computers by the main script I created. 

Function Function-Get-WindowsDSTinfo {
    [CmdletBinding(DefaultParametersetName = "DL")]
    param(
        [parameter(Position = 0, ValueFromPipeLine = $true)]
        [alias("CN", "Computer")]
        [String[]]$ComputerName = "$env:COMPUTERNAME",
 
        [Parameter(ParameterSetName = "DL")] 
        [Switch]$Daylight,
 
        [Parameter(ParameterSetName = "STND")]
        [Switch]$Standard,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        #Adjusting ErrorActionPreference to stop on all errors
        $TempErrAct = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        #Getting The Current Year
        $CurrentYear = (Get-Date).Year
    }#End Begin Script Block

    Process {
        Foreach ($Computer in $ComputerName) {
            #Making ComputerName UPPER CASE and removing trailing empty spaces.
            $Computer = $Computer.ToUpper().Trim()
            Try {
                #Creating a DateTime Object from Win32_LocalTime from the supplied ComputerName
                $Win32LT = $null
                try {
                    $Win32LT = Get-WmiObject -Class Win32_LocalTime -ComputerName $Computer -Credential $Credential -ErrorAction Stop
                } catch {
                    $Win32LT = Invoke-Command -ComputerName $Computer -Authentication Negotiate -ScriptBlock {Get-WmiObject -Class Win32_LocalTime} -Credential $Credential
                }
                $Name = $Win32LT.__SERVER
                $Month = $Win32LT.Month
                $Day = $Win32LT.Day
                $Year = $Win32LT.Year
                $Hour = $Win32LT.Hour
                $Minute = $Win32LT.Minute
                $Second = $Win32LT.Second
                #Converting the Win32_LocalTime information in to a DateTime object.
                [Datetime]$LocalTime = "$Month/$Day/$Year $Hour`:$Minute`:$Second"
                $LocalComputerTime = Get-Date -Format "MM/dd/yyyy h:mm:ss tt"
     
                #Gathering TimeZone Information From Win32_TimeZone
                $TimeZone = $null
                try {
                    $TimeZone = Get-WmiObject -Class Win32_TimeZone -ComputerName $Computer -Credential $Credential -ErrorAction Stop
                } catch {
                    $TimeZone = Invoke-Command -ComputerName $Computer -Authentication Negotiate -ScriptBlock {Get-WmiObject -Class Win32_TimeZone} -Credential $Credential
                }
                $Name = $TimeZone.PSComputerName           
                $DayTime = $TimeZone.DaylightName
                $STNDTime = $TimeZone.StandardName
                $DSTHour = $TimeZone.DaylightHour
                $STNDHour = $TimeZone.StandardHour
     
                #Using the Switch Statements to convert numeric values into more meaningful information.
                #This information can be found in the links provided in the Function's Help
                Switch ($TimeZone.DaylightDay) {
                    1 { $DSTDay = "First" }
                    2 { $DSTDay = "Second" }
                    3 { $DSTDay = "Third" }
                    4 { $DSTDay = "Fourth" }
                    5 { $DSTDay = "Last" }
                }#End Switch ($TimeZone.DaylightDay)      
                Switch ($TimeZone.DaylightDayOfWeek) {
                    0 { $DSTDoW = "Sunday" }
                    1 { $DSTDoW = "Monday" }
                    2 { $DSTDoW = "Tuesday" }
                    3 { $DSTDoW = "Wednesday" }
                    4 { $DSTDoW = "Thursday" }
                    5 { $DSTDoW = "Friday" }
                    6 { $DSTDoW = "Saturday" }
                }#End Switch ($TimeZone.DaylightDayOfWeek)      
                Switch ($TimeZone.DaylightMonth) {
                    1 { $DSTMonth = "January" }
                    2 { $DSTMonth = "February" }
                    3 { $DSTMonth = "March" }
                    4 { $DSTMonth = "April" }
                    5 { $DSTMonth = "May" }
                    6 { $DSTMonth = "June" }
                    7 { $DSTMonth = "July" }
                    8 { $DSTMonth = "August" }
                    9 { $DSTMonth = "September" }
                    10 { $DSTMonth = "October" }
                    11 { $DSTMonth = "November" }
                    12 { $DSTMonth = "December" }
                }#End Switch ($TimeZone.DaylightMonth)      
                Switch ($TimeZone.StandardDay) {
                    1 { $STNDDay = "First" }
                    2 { $STNDDay = "Second" }
                    3 { $STNDDay = "Third" }
                    4 { $STNDDay = "Fourth" }
                    5 { $STNDDay = "Last" }
                }#End Switch ($TimeZone.StandardDay)      
                Switch ($TimeZone.StandardDayOfWeek) {
                    0 { $STNDWeek = "Sunday" }
                    1 { $STNDWeek = "Monday" }
                    2 { $STNDWeek = "Tuesday" }
                    3 { $STNDWeek = "Wednesday" }
                    4 { $STNDWeek = "Thursday" }
                    5 { $STNDWeek = "Friday" }
                    6 { $STNDWeek = "Saturday" }
                }#End Switch ($TimeZone.StandardDayOfWeek)      
                Switch ($TimeZone.StandardMonth) {
                    1 { $STNDMonth = "January" }
                    2 { $STNDMonth = "February" }
                    3 { $STNDMonth = "March" }
                    4 { $STNDMonth = "April" }
                    5 { $STNDMonth = "May" }
                    6 { $STNDMonth = "June" }
                    7 { $STNDMonth = "July" }
                    8 { $STNDMonth = "August" }
                    9 { $STNDMonth = "September" }
                    10 { $STNDMonth = "October" }
                    11 { $STNDMonth = "November" }
                    12 { $STNDMonth = "December" }
                }#End Switch ($TimeZone.StandardMonth)
     
                #Calculating the actual DST/Standard time change date - Through loops.
                [DateTime]$DDate = "$DSTMonth 01, $CurrentYear $DSTHour`:00:00"
                [DateTime]$SDate = "$STNDMonth 01, $CurrentYear $STNDHour`:00:00"

                #DST Date Loop
                $i = 0
                While ($i -lt $TimeZone.DaylightDay) {
                    If ($DDate.DayOfWeek -eq $TimeZone.DaylightDayOfWeek) {
                        $i++
                        If ($i -eq $TimeZone.DaylightDay) {
                            $DFinalDate = $DDate
                        }#End If ($i -eq $TimeZone.DaylightDay)
                        Else {
                            $DDate = $DDate.AddDays(1)
                        }#End Else
                    }#End If ($DDate.DayOfWeek -eq $TimeZone.DaylightDayOfWeek)
                    Else {
                        $DDate = $DDate.AddDays(1)
                    }#End Else
                }#End While ($i -lt $TimeZone.DaylightDay)
     
                #Addressing the DayOfWeek Issue "Last" vs. "Forth" when there are only four of one day in a month
                If ($DFinalDate.Month -ne $TimeZone.DaylightMonth) {
                    $DFinalDate = $DFinalDate.AddDays(-7)
                }

                #Standard Date Loop
                $i = 0
                While ($i -lt $TimeZone.StandardDay) {
                    If ($SDate.DayOfWeek -eq $TimeZone.StandardDayOfWeek) {
                        $i++
                        If ($i -eq $TimeZone.StandardDay) {
                            $SFinalDate = $SDate
                        }#End If ($i -eq $TimeZone.StandardDay)
                        Else {
                            $SDate = $SDate.AddDays(1)
                        }#End Else
                    }#End If ($SDate.DayOfWeek -eq $TimeZone.StandardDayOfWeek)
                    Else {
                        $SDate = $SDate.AddDays(1)
                    }#End Else
                }#End While ($i -lt $TimeZone.StandardDay)
     
                #Addressing the DayOfWeek Issue "Last" vs. "Forth" when there are only four of one day in a month
                If ($SFinalDate.Month -ne $TimeZone.StandardMonth) {
                    $SFinalDate = $SFinalDate.AddDays(-7)
                }

                #Creating Daylight/Standard Object
                If ((-not $Standard) -and (-not $Daylight)) {
                    $DL_STND = New-Object PSObject -Property @{
                        IPAddress         = $Computer
                        ComputerName      = $Name
                        CurrentTime       = $LocalTime
                        LocalComputerTime = $LocalComputerTime
                        DaylightName      = $DayTime
                        DaylightDay       = $DSTDay
                        DaylightDayOfWeek = $DSTDoW
                        DaylightMonth     = $DSTMonth
                        DaylightChangeDate = $DFinalDate
                        StandardName      = $STNDTime
                        StandardDay       = $STNDDay
                        StandardDayOfWeek = $STNDWeek
                        StandardMonth     = $STNDMonth
                        StandardChangeDate = $SFinalDate
                    }#End $DL New-Object
                    $DL_STND = $DL_STND | Select-Object -Property IPAddress, ComputerName, CurrentTime, LocalComputerTime, DaylightName, DaylightDay, DaylightDayOfWeek, DaylightMonth, DaylightChangeDate, StandardName, StandardDay, StandardDayOfWeek, StandardMonth, StandardChangeDate
                    $DL_STND
                }#End If ((-not $Standard) -and (-not $Daylight))
                #Creating Parameters so that there is a choice as to which information is returend
                If ($Daylight) {
                    #Creating Daylight Saving Time Object
                    $DL = New-Object PSObject -Property @{
                        IPAddress         = $Computer
                        ComputerName      = $Name
                        CurrentTime       = $LocalTime
                        LocalComputerTime = $LocalComputerTime
                        DaylightName      = $DayTime
                        DaylightDay       = $DSTDay
                        DaylightDayOfWeek = $DSTDoW
                        DaylightMonth     = $DSTMonth
                        DaylightChangeDate = $DFinalDate
                    }#End $DL New-Object
                    $DL = $DL | Select-Object -Property IPAddress, ComputerName, CurrentTime, LocalComputerTime, DaylightName, DaylightDay, DaylightDayOfWeek, DaylightMonth, DaylightChangeDate
                    $DL
                }#End of If ($Daylight)
                If ($Standard) {
                    #Creating Standard Time Object
                    $STND = New-Object PSObject -Property @{
                        IPAddress         = $Computer
                        ComputerName      = $Name
                        CurrentTime       = $LocalTime
                        LocalComputerTime = $LocalComputerTime
                        StandardName      = $STNDTime
                        StandardDay       = $STNDDay
                        StandardDayOfWeek = $STNDWeek
                        StandardMonth     = $STNDMonth
                        StandardChangeDate = $SFinalDate
                    }#End $DL New-Object PSObject
                    $STND = $STND | Select-Object -Property IPAddress, ComputerName, CurrentTime, LocalComputerTime, StandardName, StandardDay, StandardDayOfWeek, StandardMonth, StandardChangeDate
                    $STND
                }#End If ($Standard)
                Write-Host "$Computer DST was exported" -ForegroundColor Cyan
            }#End Try
            Catch {
                $Computer | Select-Object @{Name="IPAddress";Expression={$Computer}}
                Write-Warning "$Computer threw an exception"
                $Error[0].Exception.Message | Out-Null
            }#End Catch
        }#End Foreach ($Computer in $ComputerName)
    }#End Process Script Block
 
    End {
        #Resetting ErrorActionPref
        $ErrorActionPreference = $TempErrAct
    }
}#End function Get-WindowsDSTInfo