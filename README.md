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

## Deploy Buttons

Azure Commercial:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F087f2e320ca904d9fc4e354f499ff6c79666a514%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F087f2e320ca904d9fc4e354f499ff6c79666a514%2FuiDefinition.json)

Azure Government:

[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F087f2e320ca904d9fc4e354f499ff6c79666a514%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Faguilar4keeps%2FAzure-mlzstarterkit%2F087f2e320ca904d9fc4e354f499ff6c79666a514%2FuiDefinition.json)

## Files

- `solution.json`: Subscription-level orchestrator (MLZ core + Tier3 + AD lab + CSPM coverage)
- `solution.parameters.json`: Blank starter parameters for CLI deployments
- `templates/ad-entra-vms.json`: Resource group template for six VMs + AD/Entra config
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
