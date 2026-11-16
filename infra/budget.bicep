// Monthly cost budget for the whole subscription, with email alerts.
// Deployed at subscription scope, before any billable lab resource.
//
// Preview:  az deployment sub what-if --location eastus --template-file infra/budget.bicep --parameters contactEmail=<address>
// Deploy:   az deployment sub create  --location eastus --template-file infra/budget.bicep --parameters contactEmail=<address>

targetScope = 'subscription'

@description('Email address that receives budget alerts. Passed at deploy time; never committed.')
param contactEmail string

@description('Monthly budget amount in the subscription billing currency.')
@minValue(1)
param amount int = 30

@description('Budget name.')
param budgetName string = 'budget-threat-hunting-lab'

@description('First day of the month the budget starts. Defaults to the current month.')
param startDate string = utcNow('yyyy-MM-01')

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      actual100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [
          contactEmail
        ]
      }
    }
  }
}

output budgetName string = budget.name
output monthlyAmount int = amount
