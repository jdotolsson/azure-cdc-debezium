
param environmentName string
param name string
param storageAccountName string
param containerImageName string
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

var functionAppName = toLower('func-${name}-${environmentName}')

var defaultAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: storageAccount.listKeys().keys[0].value
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
]

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
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

output id string = functionApp.id
output name string = functionApp.name
