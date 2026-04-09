<#
.SYNOPSIS
    Destroys all resources created by the MLZ AD + Entra Starter Kit deployment.

.DESCRIPTION
    Removes all resource groups, subscription-level Defender plans, policy
    assignments, and optionally the Entra security group created by the starter kit.
    Uses the same input parameters as the deployment so RG names are computed
    identically to how they were created.

.PARAMETER SubscriptionId
    The Azure subscription ID where the deployment was made.

.PARAMETER Identifier
    The MLZ identifier used during deployment (max 3 chars, e.g. "mlz").

.PARAMETER EnvironmentAbbreviation
    The environment abbreviation used during deployment (e.g. "dev", "test", "prod").

.PARAMETER Location
    The Azure region used during deployment (e.g. "eastus", "usgovvirginia").

.PARAMETER WorkloadName
    The workload name used during deployment (e.g. "adlab").

.PARAMETER EntraGroupName
    Optional. The Entra security group name to delete. If not provided the group
    is not deleted.

.PARAMETER RemoveDefenderPlans
    Switch. If set, removes all Defender for Cloud plan assignments at subscription scope.

.PARAMETER RemovePolicyAssignments
    Switch. If set, removes NIST/IL5 policy assignments created by the deployment.

.PARAMETER Force
    Switch. Skips confirmation prompts.

.EXAMPLE
    .\destroy.ps1 -SubscriptionId "xxxx" -Identifier "mlz" -EnvironmentAbbreviation "dev" `
        -Location "eastus" -WorkloadName "adlab" -RemoveDefenderPlans -RemovePolicyAssignments
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$Identifier,

    [Parameter(Mandatory)]
    [string]$EnvironmentAbbreviation,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory)]
    [string]$WorkloadName,

    [string]$EntraGroupName = "",

    [switch]$RemoveDefenderPlans,

    [switch]$RemovePolicyAssignments,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Location abbreviation map — must match solution.json exactly
# ---------------------------------------------------------------------------
$locationAbbreviations = @{
    "australiacentral"   = "auc";  "australiacentral2"  = "auc2"; "australiaeast"      = "aue"
    "australiasoutheast" = "ause"; "brazilsouth"        = "brs";  "brazilsoutheast"    = "brse"
    "canadacentral"      = "cac";  "canadaeast"         = "cae";  "centralindia"       = "inc"
    "centralus"          = "usc";  "eastasia"           = "ase";  "eastus"             = "use"
    "eastus2"            = "use2"; "francecentral"      = "frc";  "francesouth"        = "frs"
    "germanynorth"       = "den";  "germanywestcentral" = "dewc"; "israelcentral"      = "ilc"
    "italynorth"         = "itn";  "japaneast"          = "jpe";  "japanwest"          = "jpw"
    "jioindiacentral"    = "injc"; "jioindiawest"       = "injw"; "koreacentral"       = "krc"
    "koreasouth"         = "krs";  "northcentralus"     = "usnc"; "northeurope"        = "eun"
    "norwayeast"         = "noe";  "norwaywest"         = "now";  "polandcentral"      = "plc"
    "qatarcentral"       = "qac";  "southafricanorth"   = "zan";  "southafricawest"    = "zaw"
    "southcentralus"     = "ussc"; "southeastasia"      = "asse"; "southindia"         = "ins"
    "swedencentral"      = "sec";  "switzerlandnorth"   = "chn";  "switzerlandwest"    = "chw"
    "uaecentral"         = "aec";  "uaenorth"           = "aen";  "uksouth"            = "uks"
    "ukwest"             = "ukw";  "westcentralus"      = "uswc"; "westeurope"         = "euw"
    "westindia"          = "inw";  "westus"             = "usw";  "westus2"            = "usw2"
    "westus3"            = "usw3"; "chinaeast"          = "cne";  "chinaeast2"         = "cne2"
    "chinanorth"         = "cnn";  "chinanorth2"        = "cnn2"; "usdodcentral"       = "dodc"
    "usdodeast"          = "dode"; "usgovarizona"       = "az";   "usgovtexas"         = "tx"
    "usgovvirginia"      = "va"
}

if (-not $locationAbbreviations.ContainsKey($Location.ToLower())) {
    Write-Error "Unknown location '$Location'. Add it to the locationAbbreviations map."
    exit 1
}

$locAbbr   = $locationAbbreviations[$Location.ToLower()]
$idLower   = $Identifier.ToLower()
$nameBase  = "$idLower-$EnvironmentAbbreviation-$locAbbr"

# ---------------------------------------------------------------------------
# Resource groups created by this deployment
# MLZ core creates: hub-rg-network, hub-rg-operations, t0-rg-network,
# t1-rg-network, t2-rg-network (and the workload tier3 rg-network)
# The workload/tier3 RG is where VMs, CSPM, Sentinel LAW land.
# ---------------------------------------------------------------------------
$mlzCoreRgs = @(
    "$nameBase-hub-rg-network",
    "$nameBase-hub-rg-operations",
    "$nameBase-t0-rg-network",
    "$nameBase-t1-rg-network",
    "$nameBase-t2-rg-network"
)
$workloadRg = "$nameBase-$WorkloadName-rg-network"

$allRgs = $mlzCoreRgs + @($workloadRg)

# ---------------------------------------------------------------------------
# Defender plans enabled by this deployment
# ---------------------------------------------------------------------------
$defenderPlans = @(
    "CloudPosture", "VirtualMachines", "StorageAccounts", "SqlServerVirtualMachines",
    "Containers", "AppServices", "KeyVaults", "Arm", "Dns",
    "OpenSourceRelationalDatabases", "CosmosDbs", "Api"
)

# ---------------------------------------------------------------------------
# Policy assignments created by this deployment
# ---------------------------------------------------------------------------
$policyAssignments = @(
    "assign-nist-800-53",
    "assign-nist-800-171",
    "assign-dod-il5"
)

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " MLZ Starter Kit - Destroy Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Subscription : $SubscriptionId"
Write-Host "Identifier   : $Identifier"
Write-Host "Environment  : $EnvironmentAbbreviation"
Write-Host "Location     : $Location ($locAbbr)"
Write-Host "Workload     : $WorkloadName"
Write-Host ""
Write-Host "Resource groups to delete:" -ForegroundColor Yellow
$allRgs | ForEach-Object { Write-Host "  - $_" }
if ($RemoveDefenderPlans)     { Write-Host "Defender plans will be reset to Free" -ForegroundColor Yellow }
if ($RemovePolicyAssignments) { Write-Host "Policy assignments will be removed" -ForegroundColor Yellow }
if ($EntraGroupName)          { Write-Host "Entra group '$EntraGroupName' will be deleted" -ForegroundColor Yellow }
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Type 'yes' to proceed with destruction"
    if ($confirm -ne "yes") {
        Write-Host "Aborted." -ForegroundColor Red
        exit 0
    }
}

# Set subscription context
Write-Host "`nSetting subscription context..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set subscription context."; exit 1 }

# ---------------------------------------------------------------------------
# 1. Delete resource groups (parallel for speed)
# ---------------------------------------------------------------------------
Write-Host "`n[1/4] Deleting resource groups..." -ForegroundColor Cyan

$jobs = @()
foreach ($rg in $allRgs) {
    $exists = az group show --name $rg --query "name" -o tsv 2>$null
    if ($exists) {
        Write-Host "  Queuing deletion: $rg" -ForegroundColor Yellow
        $jobs += Start-Job -ScriptBlock {
            param($rg, $sub)
            az group delete --name $rg --subscription $sub --yes --no-wait 2>&1
        } -ArgumentList $rg, $SubscriptionId
    } else {
        Write-Host "  Not found (skipping): $rg" -ForegroundColor Gray
    }
}

if ($jobs.Count -gt 0) {
    Write-Host "  Waiting for deletions to complete (this can take 10-20 minutes)..." -ForegroundColor Yellow
    $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    Write-Host "  Resource group deletions initiated." -ForegroundColor Green
} else {
    Write-Host "  No resource groups found to delete." -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# 2. Reset Defender for Cloud plans to Free
# ---------------------------------------------------------------------------
if ($RemoveDefenderPlans) {
    Write-Host "`n[2/4] Resetting Defender for Cloud plans to Free..." -ForegroundColor Cyan
    foreach ($plan in $defenderPlans) {
        Write-Host "  Resetting: $plan" -ForegroundColor Yellow
        az security pricing create --name $plan --tier Free 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    Reset: $plan" -ForegroundColor Green
        } else {
            Write-Host "    Skipped (not enabled or insufficient permissions): $plan" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "`n[2/4] Skipping Defender plan reset (use -RemoveDefenderPlans to enable)" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# 3. Remove policy assignments
# ---------------------------------------------------------------------------
if ($RemovePolicyAssignments) {
    Write-Host "`n[3/4] Removing policy assignments..." -ForegroundColor Cyan
    foreach ($pa in $policyAssignments) {
        $exists = az policy assignment show --name $pa --query "name" -o tsv 2>$null
        if ($exists) {
            az policy assignment delete --name $pa
            Write-Host "  Removed: $pa" -ForegroundColor Green
        } else {
            Write-Host "  Not found (skipping): $pa" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "`n[3/4] Skipping policy assignment removal (use -RemovePolicyAssignments to enable)" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# 4. Delete Entra security group
# ---------------------------------------------------------------------------
if ($EntraGroupName) {
    Write-Host "`n[4/4] Removing Entra security group '$EntraGroupName'..." -ForegroundColor Cyan
    $groupId = az ad group show --group $EntraGroupName --query "id" -o tsv 2>$null
    if ($groupId) {
        az ad group delete --group $groupId
        Write-Host "  Deleted group: $EntraGroupName" -ForegroundColor Green
    } else {
        Write-Host "  Group not found (skipping): $EntraGroupName" -ForegroundColor Gray
    }
} else {
    Write-Host "`n[4/4] Skipping Entra group removal (use -EntraGroupName to enable)" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Destroy complete." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Resource group deletions run asynchronously." -ForegroundColor Yellow
Write-Host "Verify in the portal or run:" -ForegroundColor Yellow
Write-Host "  az group list --query ""[?starts_with(name,'$nameBase')]"" -o table" -ForegroundColor White
Write-Host ""
