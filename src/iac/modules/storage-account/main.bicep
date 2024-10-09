@minLength(3)
param name string
param location string
param skuName string = 'Standard_LRS'

var storageAccountName = 'st${name}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
   name: storageAccountName
   location: location
   sku: {
      name: skuName
   }
   kind: 'StorageV2'
   properties: {
      accessTier: 'Hot'
   }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
