// Stand-alone entry point for the telemetry layer only (Azure Monitor Agent + data
// collection rules), for when the workspace and VMs already exist. It does not touch
// the VMs' configuration, so it needs no admin password or IP parameter.
//
// main.bicep includes the same module, so a full rebuild from main.bicep also
// restores telemetry.
//
// Preview:  az deployment group what-if --resource-group rg-threat-hunting-lab --name lab-telemetry --template-file infra/telemetry.bicep
// Deploy:   az deployment group create  --resource-group rg-threat-hunting-lab --name lab-telemetry --template-file infra/telemetry.bicep

targetScope = 'resourceGroup'

@description('Region of the Log Analytics workspace (and therefore of the DCRs).')
param workspaceLocation string = resourceGroup().location

@description('Region of the lab VMs.')
param computeLocation string = 'northcentralus'

var tags = {
  project: 'threat-hunting-lab'
}

module telemetry 'modules/telemetry.bicep' = {
  name: 'telemetry'
  params: {
    workspaceLocation: workspaceLocation
    computeLocation: computeLocation
    tags: tags
  }
}

output dcrName string = telemetry.outputs.dcrName
