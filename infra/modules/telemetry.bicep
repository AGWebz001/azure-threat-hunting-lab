// Telemetry: the Azure Monitor Agent (AMA) on both lab VMs, plus a data collection
// rule (DCR) that ships Windows Security events to the Log Analytics workspace.
//
// Cross-region by design: the VMs live in northcentralus, the workspace in eastus.
// A DCR must sit in the same region as the Log Analytics workspace it sends to, but
// the machines associated with it can be in any region. So the DCR goes in the
// workspace region and the association (an extension resource on the VM) has no
// region of its own.
//
// AMA authenticates with each VM's system-assigned managed identity, which
// vms.bicep already enables.

@description('Region of the Log Analytics workspace. The DCR must be created here.')
param workspaceLocation string

@description('Region of the lab VMs. VM extensions must be created here.')
param computeLocation string

@description('Tags applied to every resource.')
param tags object

@description('Name of the existing Log Analytics workspace (with Sentinel enabled).')
param workspaceName string = 'log-threat-hunting-lab'

@description('Name of the existing Windows lab VM.')
param windowsVmName string = 'vm-win-lab-01'

@description('Name of the existing Linux lab VM.')
param linuxVmName string = 'vm-lnx-lab-01'

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspaceName
}

resource windowsVm 'Microsoft.Compute/virtualMachines@2024-07-01' existing = {
  name: windowsVmName
}

resource linuxVm 'Microsoft.Compute/virtualMachines@2024-07-01' existing = {
  name: linuxVmName
}

// ---------------------------------------------------------------------------
// Azure Monitor Agent
// ---------------------------------------------------------------------------

resource amaWindows 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: windowsVm
  name: 'AzureMonitorWindowsAgent'
  location: computeLocation
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

// Installed now so the Linux VM is ready; it has no DCR until step 4.3 (syslog),
// so it sends nothing yet.
resource amaLinux 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: linuxVm
  name: 'AzureMonitorLinuxAgent'
  location: computeLocation
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

// ---------------------------------------------------------------------------
// Data collection rule: Windows Security events, "Common" set
// ---------------------------------------------------------------------------
//
// The event ID list is Microsoft Sentinel's "Common" tier for the "Windows Security
// Events via AMA" connector: a curated audit trail (logons, account and group
// changes, process creation, scheduled tasks, services, log clearing, Kerberos)
// without the noise of "All Security Events". Split into chunks because each XPath
// query is limited in how many conditions it may hold.
//
// Note: some of these (for example 4688 process creation) only appear once the
// matching Windows audit policy is turned on inside the VM. Collecting them here
// does not switch them on.

var commonSecurityEventIds = [
  [1, 299, 300, 324, 340, 403, 404, 410, 411, 412, 413, 431, 500, 501, 1100]
  [1102, 1107, 1108, 4608, 4610, 4611, 4614, 4622, 4624, 4625, 4634, 4647, 4648, 4649, 4657]
  [4661, 4662, 4663, 4665, 4666, 4667, 4688, 4670, 4672, 4673, 4674, 4675, 4689, 4697, 4700]
  [4702, 4704, 4705, 4716, 4717, 4718, 4719, 4720, 4722, 4723, 4724, 4725, 4726, 4727, 4728]
  [4729, 4733, 4732, 4735, 4737, 4738, 4739, 4740, 4742, 4744, 4745, 4746, 4750, 4751, 4752]
  [4754, 4755, 4756, 4757, 4760, 4761, 4762, 4764, 4767, 4768, 4771, 4774, 4778, 4779, 4781]
  [4793, 4797, 4798, 4799, 4800, 4801, 4802, 4803, 4825, 4826, 4870, 4886, 4887, 4888, 4893]
  [4898, 4902, 4904, 4905, 4907, 4931, 4932, 4933, 4946, 4948, 4956, 4985, 5024, 5033, 5059]
  [5136, 5137, 5140, 5145, 5632, 6144, 6145, 6272, 6273, 6278, 6416, 6423, 6424, 8001, 8002]
  [8003, 8004, 8005, 8006, 8007, 8222, 26401, 30004]
]

var securityXPathQueries = [
  for chunk in commonSecurityEventIds: 'Security!*[System[${join(map(chunk, id => '(EventID=${id})'), ' or ')}]]'
]

resource dcrWindowsSecurity 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-windows-security-events'
  location: workspaceLocation
  tags: tags
  kind: 'Windows'
  properties: {
    description: 'Windows Security events (Sentinel Common set) and Sysmon from lab VMs to the lab workspace.'
    dataSources: {
      windowsEventLogs: [
        {
          name: 'securityEventsCommon'
          // Microsoft-SecurityEvent lands in the SecurityEvent table, which needs
          // Sentinel enabled on the workspace (it is, see logging.bicep).
          streams: [
            'Microsoft-SecurityEvent'
          ]
          xPathQueries: securityXPathQueries
        }
        {
          // Sysmon (installed by infra/scripts/install-sysmon.ps1). Everything in
          // the channel is collected; the Sysmon config on the VM decides what gets
          // logged. Microsoft-Event lands in the Event table (Source ==
          // "Microsoft-Windows-Sysmon"), with the fields packed in EventData XML.
          name: 'sysmonOperational'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Microsoft-Windows-Sysmon/Operational!*'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'labWorkspace'
          workspaceResourceId: workspace.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-SecurityEvent'
        ]
        destinations: [
          'labWorkspace'
        ]
      }
      {
        streams: [
          'Microsoft-Event'
        ]
        destinations: [
          'labWorkspace'
        ]
      }
    ]
  }
}

// Links the Windows VM to the DCR. This is what tells its agent what to collect.
resource dcrAssociationWindows 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  scope: windowsVm
  name: 'dcra-windows-security-events'
  properties: {
    description: 'Send Windows Security events from the Windows lab VM.'
    dataCollectionRuleId: dcrWindowsSecurity.id
  }
  dependsOn: [
    amaWindows
  ]
}

output dcrName string = dcrWindowsSecurity.name
