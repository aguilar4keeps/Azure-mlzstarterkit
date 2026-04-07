param (
  [Parameter(Mandatory = $true)]
  [string]$DomainName,

  [Parameter(Mandatory = $true)]
  [string]$DomainNetbiosName,

  [Parameter(Mandatory = $true)]
  [string]$SafeModeAdminPassword
)

$ErrorActionPreference = 'Stop'

# Install AD DS binaries if needed.
if (-not (Get-WindowsFeature -Name 'AD-Domain-Services').Installed) {
  Install-WindowsFeature -Name 'AD-Domain-Services' -IncludeManagementTools | Out-Null
}

Import-Module ADDSDeployment

try {
  $null = Get-ADDomain -Identity $DomainName -ErrorAction Stop
  Write-Output "Domain '$DomainName' already exists. Skipping promotion."
}
catch {
  $safeMode = ConvertTo-SecureString -String $SafeModeAdminPassword -AsPlainText -Force

  Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $DomainNetbiosName `
    -InstallDNS `
    -Force `
    -NoRebootOnCompletion:$false `
    -SafeModeAdministratorPassword $safeMode
}
