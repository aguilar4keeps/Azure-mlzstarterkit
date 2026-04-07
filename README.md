# MLZ AD + Entra Starter Kit

This starter kit is aligned to Mission Landing Zone and keeps MLZ network controls in place by:

1. Deploying the official MLZ Tier3 add-on (spoke networking, routing, private-link aligned patterns)
2. Deploying an AD lab workload into that Tier3 subnet:
- 1 domain controller
- 2 member servers
- 3 Windows clients
- Entra sign-in enabled on all VMs (`AADLoginForWindows` + VM Login RBAC)

## Deploy Buttons

Azure Commercial:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2Fmain%2Fsolution.json)

Azure Government:

[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2Fmain%2Fsolution.json)

## Files

- `solution.json`: Subscription-level orchestrator (Tier3 + AD workload)
- `solution.parameters.json`: Tailored starter parameters
- `templates/ad-entra-vms.json`: Resource group template for the six VMs + AD/Entra config
- `templates/scripts/*.ps1`: VM run-command scripts for AD promotion and domain join

## Required Inputs

When you click the blue deploy button, enter these in the portal UI:

- `firewallResourceId`
- `hubStorageAccountResourceId`
- `hubVirtualNetworkResourceId`
- `logAnalyticsWorkspaceResourceId`
- `adminPassword`
- `safeModeAdminPassword`
- `entraLoginPrincipalId`

## Important Notes

- This expects your MLZ hub resources to already exist.
- Location is prompted at deploy time in the UI.
- If Windows 11 SKU is unavailable in your target cloud, change `clientImage*` parameters.
- If this repository stays private, portal-linked raw template URIs are not publicly resolvable. For blue buttons to work directly, repository visibility should be public.
