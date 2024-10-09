param environmentName string
param name string
param location string
param containerAppEnvironmentName string
param containerRegistryName string
param eventHubNameSpaceName string

var deploymentName = uniqueString(deployment().name)

resource accessKeys 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' existing = {
  name: '${eventHubNameSpaceName}/RootManageSharedAccessKey'
}

module m_ca_debezium 'modules/container-app/main.bicep' = {
  name: 'm_ca_debezium-${deploymentName}'
  params: {
    name: name
    location: location
    containerAppEnvironmentName: containerAppEnvironmentName
    containerImageName: 'debezium/connect'
    containerImageTag: '2.7'
    containerRegistryName: containerRegistryName
    environmentName: environmentName
    replicaSizeCpu: '1'
    replicaSizeMemory: '2Gi'
    targetPort: 8083
    environmentVariables: [
      {
        name: 'BOOTSTRAP_SERVERS'
        value: '${eventHubNameSpaceName}.servicebus.windows.net:9093'
      }
      {
        name: 'GROUP_ID'
        value: '1'
      }
      {
        name: 'CONFIG_STORAGE_TOPIC'
        value: 'debezium_configs'
      }
      {
        name: 'OFFSET_STORAGE_TOPIC'
        value: 'debezium_offsets'
      }
      {
        name: 'STATUS_STORAGE_TOPIC'
        value: 'debezium_statuses'
      }
      {
        name: 'CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE'
        value: 'false'
      }
      {
        name: 'CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE'
        value: 'true'
      }
      {
        name: 'CONNECT_REQUEST_TIMEOUT_MS'
        value: '60000'
      }
      {
        name: 'CONNECT_SECURITY_PROTOCOL'
        value: 'SASL_SSL'
      }
      {
        name: 'CONNECT_SASL_MECHANISM'
        value: 'PLAIN'
      }
      {
        name: 'CONNECT_SASL_JAAS_CONFIG'
        value: 'org.apache.kafka.common.security.plain.PlainLoginModule required username="$$ConnectionString" password="${accessKeys.listKeys().primaryConnectionString}";'
      }
      {
        name: 'CONNECT_PRODUCER_SECURITY_PROTOCOL'
        value: 'SASL_SSL'
      }
      {
        name: 'CONNECT_PRODUCER_SASL_MECHANISM'
        value: 'PLAIN'
      }
      {
        name: 'CONNECT_PRODUCER_SASL_JAAS_CONFIG'
        value: 'org.apache.kafka.common.security.plain.PlainLoginModule required username="$$ConnectionString" password="${accessKeys.listKeys().primaryConnectionString}";'
      }
      {
        name: 'CONNECT_CONSUMER_SECURITY_PROTOCOL'
        value: 'SASL_SSL'
      }
      {
        name: 'CONNECT_CONSUMER_SASL_MECHANISM'
        value: 'PLAIN'
      }
      {
        name: 'CONNECT_CONSUMER_SASL_JAAS_CONFIG'
        value: 'org.apache.kafka.common.security.plain.PlainLoginModule required username="$$ConnectionString" password="${accessKeys.listKeys().primaryConnectionString}";'
      }
    ]
  }
}

output appEndpoint string = 'https://${m_ca_debezium.outputs.name}.${m_ca_debezium.outputs.domain}'
output outboundIps array = m_ca_debezium.outputs.outboundIpAddresses
