param (
  [Parameter(Mandatory = $true)]
  [string]$DomainName,

  [Parameter(Mandatory = $true)]
  [string]$DomainAdminUsername,

  [Parameter(Mandatory = $true)]
  [string]$DomainAdminPassword,

  [Parameter(Mandatory = $true)]
  [string]$DomainControllerIp,

  [int]$RetryCount = 40
)

$ErrorActionPreference = 'Stop'

$cs = Get-CimInstance -ClassName Win32_ComputerSystem
if ($cs.PartOfDomain -and $cs.Domain -ieq $DomainName) {
  Write-Output "Already joined to '$DomainName'."
  exit 0
}

for ($i = 1; $i -le $RetryCount; $i++) {
  $portCheck = Test-NetConnection -ComputerName $DomainControllerIp -Port 389 -InformationLevel Quiet
  if ($portCheck) {
    break
  }

  if ($i -eq $RetryCount) {
    throw "Domain controller $DomainControllerIp was not reachable on LDAP port 389 after $RetryCount attempts."
  }

  Start-Sleep -Seconds 15
}

$securePassword = ConvertTo-SecureString -String $DomainAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$DomainAdminUsername@$DomainName", $securePassword)

$joined = $false
for ($j = 1; $j -le $RetryCount; $j++) {
  try {
    Add-Computer -DomainName $DomainName -Credential $credential -ErrorAction Stop
    $joined = $true
    break
  }
  catch {
    if ($j -eq $RetryCount) {
      throw
    }
    Start-Sleep -Seconds 20
  }
}

if (-not $joined) {
  throw "Unable to join '$env:COMPUTERNAME' to '$DomainName'."
}

# Reboot is required to complete domain join.
shutdown.exe /r /t 15 /f /c "Completing domain join to $DomainName"
