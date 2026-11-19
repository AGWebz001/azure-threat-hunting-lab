// Azure Activity log -> Log Analytics workspace (AzureActivity table).
//
// The Activity log records control-plane actions on the subscription: who created,
// changed or deleted which resource, role assignments, policy decisions, Service
// Health notices. For a hunter it answers "what happened to the cloud itself", for
// example a VM's NSG rule opened to the internet, a new Owner role assignment, or
// a run-command executed on a VM.
//
// This is what Microsoft Sentinel's "Azure Activity" data connector sets up: a
// diagnostic setting on the subscription that streams the log to the workspace.
// Defining it here keeps it in code. Ingesting Azure Activity data into Log
// Analytics is free.
//
// Deployed at subscription scope (like budget.bicep). The deployment's own
// --location is just where Azure stores the deployment record.
//
// Preview:  az deployment sub what-if --location eastus --name lab-activity-log --template-file infra/activity-log.bicep
// Deploy:   az deployment sub create  --location eastus --name lab-activity-log --template-file infra/activity-log.bicep

targetScope = 'subscription'

@description('Resource group that holds the lab workspace.')
param resourceGroupName string = 'rg-threat-hunting-lab'

@description('Name of the Log Analytics workspace with Sentinel enabled.')
param workspaceName string = 'log-threat-hunting-lab'

@description('Activity log categories to send. All of them: the volume is small and ingestion is free.')
param categories array = [
  'Administrative'
  'Security'
  'ServiceHealth'
  'Alert'
  'Recommendation'
  'Policy'
  'Autoscale'
  'ResourceHealth'
]

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: workspaceName
}

// Diagnostic settings are not taggable, so there is no project tag here.
resource activityLogToWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-activity-to-threat-hunting-lab'
  properties: {
    workspaceId: workspace.id
    logs: [
      for c in categories: {
        category: c
        enabled: true
      }
    ]
  }
}

output diagnosticSettingName string = activityLogToWorkspace.name
