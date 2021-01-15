# Written by Igor Levin.

Function Find-Text {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Text
    )

    $7Zips = (Get-ChildItem -Path "$PWD\Files\*.7z" -Recurse -Force).FullName
    $temp = "$PWD\Files"
    if ($7Zips -ne $null) {
        while ($7Zips -ne $null) {
            $7Zips | ForEach-Object {& "${env:ProgramFiles}\7-Zip\7z.exe" x $_ "-o$($($_.Substring(0,$_.LastIndexOf('\'))))" -y}
            $7Zips | ForEach-Object {Remove-Item -Path $_ -Force}
            $7Zips = (Get-ChildItem -Path "$PWD\Files\*.7z" -Recurse -Force).FullName
        }
    }

    $textFound = @()
    $files = (Get-ChildItem -Path ".\Files\*.txt" -Recurse -Force -ErrorAction SilentlyContinue).FullName

    foreach ($file in $files) {
        $string = Select-String -Path $file -Pattern $Text
        
        if ($string -ne $null) {
            $textFound += $file 
        }
    }
    $textFound | Out-GridView -Title "Files Found"
    "Text $($Text) found:`r`n-----------------" | Out-File -FilePath ".\Found.txt" -Force
    $textFound | Out-File -FilePath ".\Found.txt" -Append -Force
}