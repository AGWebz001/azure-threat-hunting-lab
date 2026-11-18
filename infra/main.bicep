// Entry point for the threat hunting lab. Deployed to resource group rg-threat-hunting-lab.
//
// Preview:  az deployment group what-if --resource-group rg-threat-hunting-lab --template-file infra/main.bicep --parameters adminSourceIp=<your-ip>/32
// Deploy:   az deployment group create  --resource-group rg-threat-hunting-lab --template-file infra/main.bicep --parameters adminSourceIp=<your-ip>/32

targetScope = 'resourceGroup'

@description('Region for the Log Analytics workspace and Sentinel. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Region for the network and VMs. Separate from the workspace region because free-trial subscriptions cannot use suitable VM sizes in eastus.')
param computeLocation string = 'northcentralus'

@description('Public IP allowed to reach RDP and SSH, in CIDR form (for example 203.0.113.10/32). Passed at deploy time; never committed.')
param adminSourceIp string

@description('Admin username for the lab VMs.')
param adminUsername string = 'labadmin'

@description('Admin password for the lab VMs. Leave it off the command line so the CLI prompts for it; never stored.')
@secure()
@minLength(12)
param adminPassword string

var tags = {
  project: 'threat-hunting-lab'
}

var vnetName = 'vnet-threat-hunting-lab'
var subnetName = 'snet-lab'

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: computeLocation
    tags: tags
    adminSourceIp: adminSourceIp
    vnetName: vnetName
    subnetName: subnetName
  }
}

module logging 'modules/logging.bicep' = {
  name: 'logging'
  params: {
    location: location
    tags: tags
  }
}

module vms 'modules/vms.bicep' = {
  name: 'vms'
  params: {
    location: computeLocation
    tags: tags
    // Built from names rather than taken from network.outputs so that what-if can
    // evaluate the VM module (a module output is unknown until deploy time).
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
  dependsOn: [
    network
  ]
}

// Azure Monitor Agent on both VMs + data collection rules. The DCR lives in the
// workspace region (location); the agents live with the VMs (computeLocation).
// Can also be deployed on its own with infra/telemetry.bicep.
module telemetry 'modules/telemetry.bicep' = {
  name: 'telemetry'
  params: {
    workspaceLocation: location
    computeLocation: computeLocation
    tags: tags
  }
  dependsOn: [
    vms
    logging
  ]
}

output vmNames array = vms.outputs.vmNames
output vnetName string = network.outputs.vnetName
output workspaceName string = logging.outputs.workspaceName
