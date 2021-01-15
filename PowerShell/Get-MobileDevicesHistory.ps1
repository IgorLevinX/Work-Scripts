$credentials = Get-Credential
Write-Output "Getting the Exchange Online cmdlets"
 
$session = New-PSSession -ConnectionUri https://outlook.office365.com/powershell-liveid/ -ConfigurationName Microsoft.Exchange -Credential $credentials -Authentication Basic -AllowRedirection
Import-PSSession $session
 
$csv = "F:\Scripts\Office365\MobileDevices.csv"
$results = @()
$mailboxUsers = Get-Mailbox -ResultSize unlimited
$mobileDevice = @()

foreach($user in $mailboxUsers)
{
$UPN = $user.UserPrincipalName
$displayName = $user.DisplayName
 
$mobileDevices = Get-MobileDeviceStatistics -Mailbox $UPN | Where-Object {$_.LastSyncAttemptTime -gt (Get-Date).AddMonths(-3)}
       
      foreach($mobileDevice in $mobileDevices)
      {
          Write-Output "Getting info about a device for $displayName"
          $properties = @{
          Name = $user.name
          UPN = $UPN
          DisplayName = $displayName
          DeviceFriendlyName = $mobileDevice.DeviceFriendlyName
          DeviceModel = $mobileDevice.DeviceModel
          DeviceOS = $mobileDevice.DeviceOS
          DeviceType = $mobileDevice.DeviceType
          FirstSyncTime = $mobileDevice.FirstSyncTime
          LastPolicyUpdateTime = $mobileDevice.LastPolicyUpdateTime
          LastSyncAttemptTime = $mobileDevice.LastSyncAttemptTime
          LastSuccessSync = $mobileDevice.LastSuccessSync
          IsValid = $mobileDevice.IsValid
          UserDisplayName = $mobileDevice.UserDisplayName
          }
          $results += New-Object psobject -Property $properties
      }
}
 
$results | Select-Object Name,UPN,DisplayName,DeviceFriendlyName,DeviceModel,DeviceOS,DeviceType,FirstSyncTime,LastPolicyUpdateTime,LastSyncAttemptTime,LastSuccessSync,IsValid | Export-Csv -NoTypeInformation -Path $csv
 
Remove-PSSession $session

