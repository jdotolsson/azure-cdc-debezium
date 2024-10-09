param serverName string
param name string
param environmentName string
param location string

var sqlDbName = 'sqldb${name}${environmentName}'

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: serverName
}

resource sqlDB 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDbName
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
    zoneRedundant: false
    readScale: 'Disabled'
    autoPauseDelay: 60
    requestedBackupStorageRedundancy: 'Local'
    #disable-next-line BCP036
    minCapacity: '0.5'
  }
}

output name string = sqlDB.name
