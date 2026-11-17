// Lab network: one virtual network, one subnet, and a network security group (NSG)
// that only lets the lab owner reach the management ports.

@description('Azure region.')
param location string

@description('Tags applied to every resource.')
param tags object

@description('Public IP allowed to reach RDP and SSH, in CIDR form (for example 203.0.113.10/32).')
param adminSourceIp string

@description('Virtual network name.')
param vnetName string = 'vnet-threat-hunting-lab'

@description('Lab subnet name.')
param subnetName string = 'snet-lab'

@description('Address space for the lab virtual network.')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('Address range for the lab subnet.')
param subnetAddressPrefix string = '10.10.1.0/24'

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-threat-hunting-lab'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-Admin'
        properties: {
          description: 'Remote Desktop from the lab owner only.'
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: adminSourceIp
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'Allow-SSH-From-Admin'
        properties: {
          description: 'SSH from the lab owner only.'
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: adminSourceIp
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output subnetId string = vnet.properties.subnets[0].id
output nsgName string = nsg.name
