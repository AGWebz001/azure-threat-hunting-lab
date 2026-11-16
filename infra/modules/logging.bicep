// Central log store and SIEM: a Log Analytics workspace with Microsoft Sentinel
// enabled on top of it.

@description('Azure region.')
param location string

@description('Tags applied to every resource.')
param tags object

@description('Workspace name.')
param workspaceName string = 'log-threat-hunting-lab'

@description('Days of log retention. 30 is the minimum for the pay-as-you-go tier.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily ingestion cap in GB. Ingestion stops for the day once reached. Keeps cost bounded.')
param dailyQuotaGb int = 1

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
  }
}

// Enables Microsoft Sentinel on the workspace.
resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2024-03-01' = {
  scope: workspace
  name: 'default'
  properties: {}
}

output workspaceName string = workspace.name
output workspaceId string = workspace.id
