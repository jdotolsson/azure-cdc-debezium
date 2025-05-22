param environmentName string
param name string
param storageAccountName string
param eventHubNamespaceName string
param containerImageName string
param acrName string
param location string
param managedEnvironmentName string
param managedEnvironmentWorkloadProfileName string = 'Consumption'
param minReplicas int = 0
param maxReplicas int = 10
param appSettings array = []

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: managedEnvironmentName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}


resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' existing = {
  name: acrName
}

resource rule 'Microsoft.EventHub/namespaces/authorizationRules@2023-01-01-preview' existing = {
  name: '${eventHubNamespaceName}/RootManageSharedAccessKey'
}

var functionAppName = toLower('func-${name}-${environmentName}')

var defaultAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'eventhubnamespace_connectionstring'
    value: rule.listKeys('2023-01-01-preview').primaryConnectionString
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
    value: acr.name
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
    value: acr.listCredentials().passwords[0].value
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: acr.properties.loginServer
  }
]

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp,linux,container,azurecontainerapps'
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    workloadProfileName: managedEnvironmentWorkloadProfileName
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerImageName}'
      functionAppScaleLimit: maxReplicas
      minimumElasticInstanceCount: minReplicas
      appSettings: union(defaultAppSettings, appSettings)
    }
  }
}

var acrpullId = subscriptionResourceId('Microsoft.Authorization/roleAssignments', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(subscription().subscriptionId, resourceGroup().id, acr.id, functionApp.id)
  properties: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrpullId
  }
}

output id string = functionApp.id
output name string = functionApp.name
