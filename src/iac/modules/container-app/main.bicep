param name string
param location string
param environmentName string
param containerAppEnvironmentName string
param containerRegistryName string
param containerImageName string
param containerImageTag string
param replicaSizeCpu string
param replicaSizeMemory string
param minReplicas int = 1
param maxReplicas int = 1
param targetPort int = 80
param environmentVariables array = []

resource cr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource cae 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppEnvironmentName
}

var standardVariables = []

var containerVariables = union(environmentVariables, standardVariables)

resource ca 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${name}-${environmentName}'
  location: location
  properties: {
    environmentId: cae.id
    configuration: {
      secrets: [
        {
          name: 'acr-password'
          value: cr.listCredentials().passwords[0].value
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: targetPort
        transport: 'auto'
      }
      registries: [
        {
          server: cr.properties.loginServer
          passwordSecretRef: 'acr-password'
          username: cr.listCredentials().username
        }
      ]
    }
    workloadProfileName: 'Consumption'
    template: {
      containers: [
        {
          env: containerVariables
          image: '${containerImageName}:${containerImageTag}'
          name: 'main'
          resources: {
            cpu: json(replicaSizeCpu)
            memory: replicaSizeMemory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output domain string = cae.properties.defaultDomain
output name string = ca.name
output outboundIpAddresses array = ca.properties.outboundIpAddresses
