// Entry point for the threat hunting lab. Deployed to resource group rg-threat-hunting-lab.
//
// Preview:  az deployment group what-if --resource-group rg-threat-hunting-lab --template-file infra/main.bicep --parameters adminSourceIp=<your-ip>/32
// Deploy:   az deployment group create  --resource-group rg-threat-hunting-lab --template-file infra/main.bicep --parameters adminSourceIp=<your-ip>/32

targetScope = 'resourceGroup'

@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Public IP allowed to reach RDP and SSH, in CIDR form (for example 203.0.113.10/32). Passed at deploy time; never committed.')
param adminSourceIp string

var tags = {
  project: 'threat-hunting-lab'
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    tags: tags
    adminSourceIp: adminSourceIp
  }
}

module logging 'modules/logging.bicep' = {
  name: 'logging'
  params: {
    location: location
    tags: tags
  }
}

output vnetName string = network.outputs.vnetName
output workspaceName string = logging.outputs.workspaceName
