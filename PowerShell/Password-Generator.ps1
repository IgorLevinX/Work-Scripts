Add-Type -AssemblyName System.Windows.Forms   
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

$geneatePasswords_Click = {
    $passLength = [Int32]$passLengthTextBox.Text
    $passNumSpecial = [Int32]$passNumSpecialTextBox.Text
    $passNum = [Int32]$passNumPasswordsTextBox.Text

    $passwords = @()
    for ($n=0; $n -lt $passNum; $n++) {
        $passwords += "$([System.Web.Security.Membership]::GeneratePassword($passLength,$passNumSpecial))`r`n"
    }

    $windowSize = $null
    if ($passLength -lt 20) {
        $windowSize = $passLength * 20
    } else {
        $windowSize = $passLength * 10
    }

    $formPass = New-Object System.Windows.Forms.Form
    $formPass.Text = "Password Generator"
    $formPass.Size = New-Object System.Drawing.Size($windowSize,300)
    $formPass.StartPosition = "CenterScreen"

    $showPasswords = New-Object System.Windows.Forms.TextBox
    $showPasswords.Location = New-Object System.Drawing.Size(0,10) 
    $showPasswords.Size = New-Object System.Drawing.Size($windowSize,300) 
    $showPasswords.TextAlign = "Center"
    $showPasswords.AutoSize = $true
    $showPasswords.Font = "Microsoft Sans Serif,10"
    $showPasswords.ReadOnly = $true
    $showPasswords.BorderStyle = 0
    $showPasswords.TabStop = $false
    $showPasswords.Multiline = $true
    $showPasswords.ScrollBars = "Both"
    $showPasswords.Text = "Generated Passwords:`r`n$($passwords)"
    $formPass.Controls.Add($showPasswords)

    [void]$formPass.ShowDialog()
    [void]$formPass.Dispose()
}

$exportPasswords_Click = {
    $passLength = [Int32]$passLengthTextBox.Text
    $passNumSpecial = [Int32]$passNumSpecialTextBox.Text
    $passNum = [Int32]$passNumPasswordsTextBox.Text

    $passwords = @()
    for ($n=0; $n -lt $passNum; $n++) {
        $passwords += "$([System.Web.Security.Membership]::GeneratePassword($passLength,$passNumSpecial))"
    }

    $passwords | Select-Object @{Name='Passwords';Expression={$_}} | Export-Csv -Path ".\NewPasswords.csv" -NoTypeInformation

        $windowSize = $null
    if ($passLength -lt 20) {
        $windowSize = $passLength * 20
    } else {
        $windowSize = $passLength * 10
    }

    $formPass = New-Object System.Windows.Forms.Form
    $formPass.Text = "Password Generator"
    $formPass.Size = New-Object System.Drawing.Size($windowSize,300)
    $formPass.StartPosition = "CenterScreen"

    $showPasswords = New-Object System.Windows.Forms.TextBox
    $showPasswords.Location = New-Object System.Drawing.Size(0,10) 
    $showPasswords.Size = New-Object System.Drawing.Size($windowSize,300) 
    $showPasswords.TextAlign = "Center"
    $showPasswords.AutoSize = $true
    $showPasswords.Font = "Microsoft Sans Serif,10"
    $showPasswords.ReadOnly = $true
    $showPasswords.BorderStyle = 0
    $showPasswords.TabStop = $false
    $showPasswords.Multiline = $true
    $showPasswords.ScrollBars = "Both"
    $showPasswords.Text = "Generated Passwords:`r`n$($passwords)"
    $formPass.Controls.Add($showPasswords)

    [void]$formPass.ShowDialog()
    [void]$formPass.Dispose()
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Password Generator"
$form.Size = New-Object System.Drawing.Size(535,170)
$form.StartPosition = "CenterScreen"

$passLengthLabel = New-Object System.Windows.Forms.Label
$passLengthLabel.Location = New-Object System.Drawing.Size(20,20)
$passLengthLabel.Text = "Enter Password Length:"
$passLengthLabel.AutoSize = $true
$passLengthLabel.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($passLengthLabel)

$passLengthTextBox = New-Object System.Windows.Forms.TextBox
$passLengthTextBox.Location = New-Object System.Drawing.Size(270,20)
$passLengthTextBox.AutoSize = $true
$passLengthTextBox.Text = 8
$passLengthTextBox.Width = 35
$passLengthTextBox.MaxLength = 2
$passLengthTextBox.Font = "Microsoft Sans Serif,10"
$form.Controls.Add($passLengthTextBox)

$passNumSpecialLabel = New-Object System.Windows.Forms.Label
$passNumSpecialLabel.Location = New-Object System.Drawing.Size(20,50)
$passNumSpecialLabel.Text = "Enter Number of Special Characters:"
$passNumSpecialLabel.AutoSize = $true
$passNumSpecialLabel.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($passNumSpecialLabel)

$passNumSpecialTextBox = New-Object System.Windows.Forms.TextBox
$passNumSpecialTextBox.Location = New-Object System.Drawing.Size(270,50)
$passNumSpecialTextBox.AutoSize = $true
$passNumSpecialTextBox.Text = 2
$passNumSpecialTextBox.Width = 35
$passNumSpecialTextBox.MaxLength = 2
$passNumSpecialTextBox.Font = "Microsoft Sans Serif,10"
$form.Controls.Add($passNumSpecialTextBox)

$passNumPasswordsLabel = New-Object System.Windows.Forms.Label
$passNumPasswordsLabel.Location = New-Object System.Drawing.Size(20,80)
$passNumPasswordsLabel.Text = "Enter Number of Passwords:"
$passNumPasswordsLabel.AutoSize = $true
$passNumPasswordsLabel.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($passNumPasswordsLabel)

$passNumPasswordsTextBox = New-Object System.Windows.Forms.TextBox
$passNumPasswordsTextBox.Location = New-Object System.Drawing.Size(270,80)
$passNumPasswordsTextBox.AutoSize = $true
$passNumPasswordsTextBox.Text = 1
$passNumPasswordsTextBox.Width = 35
$passNumPasswordsTextBox.MaxLength = 2
$passNumPasswordsTextBox.Font = "Microsoft Sans Serif,10"
$form.Controls.Add($passNumPasswordsTextBox)

$geneatePasswords = New-Object System.Windows.Forms.Button
$geneatePasswords.Location = New-Object System.Drawing.Size(340,25)
$geneatePasswords.Size = New-Object System.Drawing.Size(150,30)
$geneatePasswords.Text = "Generate Passwords"
$geneatePasswords.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($geneatePasswords)

$exportPasswords = New-Object System.Windows.Forms.Button
$exportPasswords.Location = New-Object System.Drawing.Size(340,65)
$exportPasswords.Size = New-Object System.Drawing.Size(150,40)
$exportPasswords.Text = "Generate and Export Passwords"
$exportPasswords.Font = "Microsoft Sans Serif,10.5"
$form.Controls.Add($exportPasswords)

$geneatePasswords.Add_Click($geneatePasswords_Click)
$exportPasswords.Add_Click($exportPasswords_Click)

[void]$form.ShowDialog()
[void]$form.Dispose()

