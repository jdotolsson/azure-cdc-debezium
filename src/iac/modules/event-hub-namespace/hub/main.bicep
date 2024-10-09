param namespace string
param name string
param environmentName string
param messageRetentionInDays int = 7
param partitionCount int = 1

var eventHubName = 'evh-${name}-${environmentName}'

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' existing = {
  name: namespace
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: messageRetentionInDays
    partitionCount: partitionCount
  }
}

output name string = eventHub.name
