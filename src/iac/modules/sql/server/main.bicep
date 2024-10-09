param serverName string
param environmentName string
param location string
param administratorLogin string
@secure()
param administratorLoginPassword string

var sqlServerName = 'sql-${serverName}-${environmentName}'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

output id string = sqlServer.id
output name string = sqlServer.name
