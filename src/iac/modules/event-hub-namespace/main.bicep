@minLength(4)
param name string
param environmentName string
param location string
param sku string = 'Standard'

var eventHubNamespaceName = 'evhns-${name}-ns-${environmentName}'

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: sku
    tier: sku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

output name string = eventHubNamespace.name
