targetScope = 'subscription'

param environmentName string
param location string = 'swedencentral'
param sqlServerUser string
@secure()
param sqlServerPassword string
@minLength(4)
@maxLength(4)
param uniqueId string = take(uniqueString('core'), 4)
param changeProcessorImageName string = 'mcr.microsoft.com/azure-functions/dotnet8-quickstart-demo:1.0'

var deploymentName = uniqueString(deployment().name)
var coreName = 'core-${uniqueId}'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-product-${environmentName}'
  location: location
}

module m_eventHubNamespace 'modules/event-hub-namespace/main.bicep' = {
  scope: rg
  name: 'm_hub_namespace-${deploymentName}'
  params: {
    name: coreName
    environmentName: environmentName
    location: location
  }
}

module m_eventHub 'modules/event-hub-namespace/hub/main.bicep' = {
  scope: rg
  name: 'm_ns_hub-${deploymentName}'
  params: {
    namespace: m_eventHubNamespace.outputs.name
    name: 'product'
    environmentName: environmentName
  }
}

module m_sqlServer 'modules/sql/server/main.bicep' = {
  scope: rg
  name: 'm_sql_server-${deploymentName}'
  params: {
    administratorLogin: sqlServerUser
    administratorLoginPassword: sqlServerPassword
    environmentName: environmentName
    location: location
    serverName: coreName
  }
}

module m_sql_db 'modules/sql/db/main.bicep' = {
  scope: rg
  name: 'm_sql_db-${deploymentName}'
  params: {
    name: 'products'
    environmentName: environmentName
    location: location
    serverName: m_sqlServer.outputs.name
  }
}

module m_acr 'modules/container-registry/main.bicep' = {
  scope: rg
  name: 'm_acr-${deploymentName}'
  params: {
    name: replace(coreName, '-', '')
    location: location
    environmentName: environmentName
  }
}

module m_cae 'modules/container-app-environment/main.bicep' = {
  scope: rg
  name: 'm_cae-${deploymentName}'
  params: {
    name: coreName
    location: location
    environmentName: environmentName
  }
}

module m_ca_debezium 'debezium-app.bicep' = {
   scope: rg
   name: 'm_ca_debezium-${deploymentName}'
   params: {
      location: location
      containerAppEnvironmentName: m_cae.outputs.name
      containerRegistryName: m_acr.outputs.name
      environmentName:  environmentName
      eventHubNameSpaceName: m_eventHubNamespace.outputs.name
      name: 'debezium'
   }
}

module m_st_account 'modules/storage-account/main.bicep' = {
  scope: rg
  name: 'm_st_account-${deploymentName}'
  params: {
    name: 'products${uniqueId}'
    location: location
    queues: [
      'products-feed'
      'reviews-feed'
    ]
  }
}

module m_ca_function 'modules/function/main.bicep' = {
  scope: rg
  name: 'm_ca_func-${deploymentName}'
  params: {
    name: 'change-processor'
    location: location
    containerImageName: changeProcessorImageName
    environmentName: environmentName
    managedEnvironmentName: m_cae.outputs.name
    storageAccountName: m_st_account.outputs.storageAccountName
    eventHubNamespaceName: m_eventHubNamespace.outputs.name
    acrName: m_acr.outputs.name
  }
}
module m_search_ai 'modules/search-ai/main.bicep' = {
  scope: rg
  name: 'm_search_ai-${deploymentName}'
  params: {
    name: coreName
    location: location
  }
}


output resourceGroupName string = rg.name
output eventhubName string = m_eventHub.outputs.name
output eventhubNamespaceName string = m_eventHubNamespace.outputs.name
output sqlServerId string = m_sqlServer.outputs.id
output sqlServerName string = m_sqlServer.outputs.name
output sqlServerUser string = sqlServerUser
output sqlDatabaseName string = m_sql_db.outputs.name
output debeziumEndpoint string = m_ca_debezium.outputs.appEndpoint
output debeziumOutboundIps array = m_ca_debezium.outputs.outboundIps
output acrLoginServer string = m_acr.outputs.loginServer
output acrName string = m_acr.outputs.name
output searchIndexUri string = m_search_ai.outputs.uri
output searchIndexName string = m_search_ai.outputs.name
