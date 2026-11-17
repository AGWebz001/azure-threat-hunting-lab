// Lab machines: one Windows Server 2022 VM and one Ubuntu 22.04 VM in the lab subnet.
// Each has a public IP (reachable only from the admin IP, enforced by the subnet NSG),
// a system-assigned identity (used later by the Azure Monitor Agent), and a nightly
// auto-shutdown so a forgotten VM does not burn credit.

@description('Azure region.')
param location string

@description('Tags applied to every resource.')
param tags object

@description('Resource ID of the subnet the VMs join.')
param subnetId string

@description('Admin username for both VMs.')
param adminUsername string

@description('Admin password for both VMs. Prompted for at deploy time; never stored.')
@secure()
param adminPassword string

@description('Size of the Windows VM. 2 vCPU / 8 GB.')
param windowsVmSize string = 'Standard_B2as_v2'

@description('Size of the Linux VM. 2 vCPU / 4 GB.')
param linuxVmSize string = 'Standard_B2als_v2'

@description('Daily auto-shutdown time, 24-hour HHmm.')
param shutdownTime string = '2200'

@description('Time zone for the auto-shutdown time.')
param shutdownTimeZone string = 'Eastern Standard Time'

var machines = [
  {
    name: 'vm-win-lab-01'
    computerName: 'win-lab-01'
    os: 'windows'
    size: windowsVmSize
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2022-datacenter-g2'
      version: 'latest'
    }
  }
  {
    name: 'vm-lnx-lab-01'
    computerName: 'lnx-lab-01'
    os: 'linux'
    size: linuxVmSize
    imageReference: {
      publisher: 'Canonical'
      offer: '0001-com-ubuntu-server-jammy'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
  }
]

resource publicIps 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for m in machines: {
    name: 'pip-${m.name}'
    location: location
    tags: tags
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'
    }
  }
]

resource nics 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for (m, i) in machines: {
    name: 'nic-${m.name}'
    location: location
    tags: tags
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: subnetId
            }
            publicIPAddress: {
              id: publicIps[i].id
            }
          }
        }
      ]
    }
  }
]

resource vms 'Microsoft.Compute/virtualMachines@2024-07-01' = [
  for (m, i) in machines: {
    name: m.name
    location: location
    tags: tags
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      hardwareProfile: {
        vmSize: m.size
      }
      osProfile: {
        computerName: m.computerName
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: m.os == 'linux'
          ? {
              disablePasswordAuthentication: false
            }
          : null
      }
      storageProfile: {
        imageReference: m.imageReference
        osDisk: {
          name: 'osdisk-${m.name}'
          createOption: 'FromImage'
          deleteOption: 'Delete'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: nics[i].id
            properties: {
              deleteOption: 'Delete'
            }
          }
        ]
      }
      securityProfile: {
        securityType: 'TrustedLaunch'
        uefiSettings: {
          secureBootEnabled: true
          vTpmEnabled: true
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }
]

// The name must be exactly 'shutdown-computevm-<vmName>' for Azure to treat it as
// the VM's auto-shutdown schedule.
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = [
  for (m, i) in machines: {
    name: 'shutdown-computevm-${m.name}'
    location: location
    tags: tags
    properties: {
      status: 'Enabled'
      taskType: 'ComputeVmShutdownTask'
      dailyRecurrence: {
        time: shutdownTime
      }
      timeZoneId: shutdownTimeZone
      targetResourceId: vms[i].id
      notificationSettings: {
        status: 'Disabled'
      }
    }
  }
]

output vmNames array = [for m in machines: m.name]
