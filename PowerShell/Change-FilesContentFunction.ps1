# Written by Igor Levin.

# Declaring the main function
Function Change-FilesContent {
    # Declaring the parameters
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (Test-Path -Path $_ -PathType Any) {
                $True
            } else {
                throw "Could not find $_"
            }
        })]
        [String]$Path = "",

        [Parameter()]
        [Switch]$Recurse,

        [Parameter(Mandatory)]
        [String[]]$OldContent,

        [Parameter(Mandatory)]
        [String[]]$NewContent
    )

    $files = $null
    # if statement to check if the Recurse paramter has been used.
    # After the check run the Get-ChileItem command to get the files form the location we need.
    if ($Recurse -eq $true) {
        $files = Get-ChildItem -Path $Path -Recurse | Sort-Object -Property Extension | Select-Object FullName,Extension
    } else {
        $files = Get-ChildItem -Path $Path | Sort-Object -Property Extension | Select-Object FullName,Extension
    }

    $numOfFiles = ($files | Measure-Object).Count
    $countArray = @()
    $first = $true

    Function Replace-FileContent {
        Param(
            [String]$FilePath,
            [System.Collections.Hashtable]$NumberOfCounts
        )

        $content = Get-Content -Path $FilePath -Raw
        $containsOldContent = $content | ForEach-Object { foreach ( $oc in $OldContent ) { $_ -match $oc } } 
        $containsNewContent = $content | ForEach-Object { foreach ( $nc in $NewContent ) { $_ -match $nc } } 
        if ($containsOldContent -contains $True) {

            for ($i = 0; $i -lt $OldContent.Length; $i++) {
                $content = $content.Replace($OldContent[$i],$NewContent[$i])
            } 
            Set-Content -Path $FilePath -Value $content -Verbose
        
            $NumberOfCounts.TotalFileCount++
            $NumberOfCounts.ChangedFileCount++

        } elseif ($containsNewContent -contains $True) {
            $NumberOfCounts.TotalFileCount++
            $NumberOfCounts.AlreadyChangedFileCount++

        } else {
            $NumberOfCounts.TotalFileCount++
            $NumberOfCounts.NoContentFileCount++
        }
    }

    foreach ($file in $files) {
        $ext = $file.Extension
        if ($first -eq $true) {
            $numCount = @{Extension = $ext; TotalFileCount = 0; ChangedFileCount = 0; AlreadyChangedFileCount = 0; NoContentFileCount = 0;}
            Replace-FileContent -FilePath $($file.FullName) -NumberOfCounts $numCount
            $countArray += $numCount

        } elseif ($first -eq $false -and $ext -eq $countArray[-1].Extension) {
            Replace-FileContent -FilePath $($file.FullName) -NumberOfCounts $countArray[-1]

        } elseif ($first -eq $false -and $ext -ne $($countArray[-1].Extension)) {
            $numCount = @{Extension = $ext; TotalFileCount = 0; ChangedFileCount = 0; AlreadyChangedFileCount = 0; NoContentFileCount = 0;}
            Replace-FileContent -FilePath $($file.FullName) -NumberOfCounts $numCount
            $countArray += $numCount
        }
        $first = $false
    }

    Write-Host ""
    Write-Host "Number of total files: $numOfFiles"
    Write-Host ""
    foreach ($count in $countArray) {
        if ($count.ChangedFileCount -gt 0 -or $count.AlreadyChangedFileCount -gt 0) {
            Write-Host "Number of total $($count.Extension) files: $($count.TotalFileCount)"
            Write-Host "Number of $($count.Extension) files changed: $($count.ChangedFileCount)"
            Write-Host "Number of $($count.Extension) files already changed: $($count.AlreadyChangedFileCount)"
            Write-Host "Number of $($count.Extension) files that didn't had any of the requested values: $($count.NoContentFileCount)"
            Write-Host ""
        } else {
            Write-Host "$($count.TotalFileCount) $($count.Extension) files did not needed to be changed because they didn't had the requested values"
            Write-Host ""
        }
    }

}