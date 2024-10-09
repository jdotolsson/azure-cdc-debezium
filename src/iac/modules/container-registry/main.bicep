
@minLength(2)
param name string
param environmentName string
param location string
param acrSku string = 'Basic'

var acrName = 'acr${name}${environmentName}'

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
}

output loginServer string = acrResource.properties.loginServer
output name string = acrResource.name
