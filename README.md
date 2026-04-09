# MLZ AD + Entra Starter Kit

This starter kit is aligned to Mission Landing Zone and deploys in one shot:

1. Core MLZ hub resources (including networking, private-link aligned services, and optional Bastion)
2. MLZ Tier3 workload network
3. AD + Entra workload in Tier3 subnet:
- 1 domain controller
- 2 member servers
- 3 Windows clients
- Entra sign-in enabled on all VMs (`AADLoginForWindows` + VM Login RBAC)
4. CSPM/CWPP coverage sample resources:
- 1 SQL Database
- 1 Storage account + 1 blob container
- 1 Container registry
- 1 Resource Manager nested deployment sample

---

## Deploy

Azure Commercial:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F8d05d674a2c1a86b03a0fbced1e9cb40b4f6b2b7%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F8d05d674a2c1a86b03a0fbced1e9cb40b4f6b2b7%2FuiDefinition.json)

Azure Government:

[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F8d05d674a2c1a86b03a0fbced1e9cb40b4f6b2b7%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F8d05d674a2c1a86b03a0fbced1e9cb40b4f6b2b7%2FuiDefinition.json)

---

## Destroy (Teardown)

Use the script below to remove everything created by this deployment. Click the button to open Azure Cloud Shell, then paste the command for your environment.

[![Open in Cloud Shell](https://shell.azure.com/images/launchcloudshell.png)](https://shell.azure.com/powershell)

### What the destroy script removes

| Step | What gets removed | Flag required |
|------|-------------------|---------------|
| 1 | **All resource groups** whose name starts with `{identifier}-{env}-{locationAbbr}-` — this covers the MLZ hub RGs (hub network, hub operations, tier0–2) and the workload tier3 RG containing all VMs, CSPM resources, Log Analytics workspace, and Sentinel | *(always runs)* |
| 2 | **Defender for Cloud plans** — resets CloudPosture, Defender for Servers, Storage, SQL, Containers, App Service, Key Vault, ARM, DNS, OSS DB, Cosmos DB, and API plans back to Free tier | `-RemoveDefenderPlans` |
| 3 | **Policy assignments** — removes the NIST SP 800-53, NIST SP 800-171, and DoD Impact Level 5 assignments created at subscription scope | `-RemovePolicyAssignments` |
| 4 | **Entra security group** — deletes the Azure AD/Entra ID group used for VM login RBAC | `-EntraGroupName "group-name"` |

> **Warning:** This is irreversible. All VMs, data, networking, and associated resources will be permanently deleted. Defender plan changes take effect immediately and affect billing.

### Requirements

- Azure CLI (`az`) installed and logged in
- Owner or Contributor role at subscription scope
- PowerShell 5.1+ or PowerShell 7+

### Usage

**Minimum** — deletes all resource groups only, with confirmation prompt:
```powershell
$scriptUrl = "https://raw.githubusercontent.com/aguilar4keeps/Azure-mlzstarterkit/main/destroy.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile destroy.ps1
.\destroy.ps1 `
  -SubscriptionId "<your-subscription-id>" `
  -Identifier "<identifier-used-at-deploy>" `
  -EnvironmentAbbreviation "<dev|test|prod>" `
  -Location "<azure-region>"
```

**Full teardown** — removes everything including Defender plans, policies, and Entra group:
```powershell
$scriptUrl = "https://raw.githubusercontent.com/aguilar4keeps/Azure-mlzstarterkit/main/destroy.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile destroy.ps1
.\destroy.ps1 `
  -SubscriptionId "<your-subscription-id>" `
  -Identifier "<identifier-used-at-deploy>" `
  -EnvironmentAbbreviation "<dev|test|prod>" `
  -Location "<azure-region>" `
  -EntraGroupName "<group-name>" `
  -RemoveDefenderPlans `
  -RemovePolicyAssignments `
  -Force
```

**Example** (matching a deployment with identifier `mlz`, environment `dev`, region `eastus`):
```powershell
.\destroy.ps1 `
  -SubscriptionId "9f2be59b-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
  -Identifier "mlz" `
  -EnvironmentAbbreviation "dev" `
  -Location "eastus" `
  -EntraGroupName "mlz-lab-vm-users" `
  -RemoveDefenderPlans `
  -RemovePolicyAssignments `
  -Force
```

The script discovers resource groups dynamically by prefix match and deletes them in parallel. Deletion typically takes 15–30 minutes. To verify after completion:
```powershell
az group list --query "[?starts_with(name,'mlz-dev-use-')]" -o table
```

---

## Files

- `solution.json`: Subscription-level orchestrator (MLZ core + Tier3 + AD lab + CSPM coverage)
- `solution.parameters.json`: Blank starter parameters for CLI deployments
- `destroy.ps1`: Teardown script — removes all resource groups, optional Defender/policy/Entra cleanup
- `templates/ad-entra-vms.json`: Resource group template for VMs + AD/Entra config
- `templates/cspm-coverage.json`: SQL, Storage/container, ACR, and Resource Manager sample resources
- `templates/scripts/*.ps1`: VM run-command scripts for AD promotion and domain join

## Required Inputs

When you click the blue deploy button, enter these in the portal UI:

- `location`
- `identifier`
- `workloadName`
- `workloadShortName`
- `prefix`
- `adminUsername`
- `adminPassword`
- `safeModeAdminPassword`
- `domainName`
- `domainNetbiosName`
- `entraLoginPrincipalId`

## Important Notes

- This deployment now creates MLZ hub resources and no longer requires pre-existing hub IDs.
- Bastion is enabled by default (`deployBastion = true`) and can be toggled in UI.
- If Windows 11 SKU is unavailable in your target cloud, change `clientImage*` parameters.
- If this repository stays private, portal-linked raw template URIs are not publicly resolvable. For blue buttons to work directly, repository visibility should be public.
