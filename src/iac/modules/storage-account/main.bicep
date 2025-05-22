@minLength(3)
param name string
param location string
param skuName string = 'Standard_LRS'
param queues array = []

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

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2021-08-01' = {
   name: 'default'
   parent: storageAccount
   properties: {}
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = [for item in queues: {
   name: item
   parent: queueServices
}]


output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
