param name string
param environmentName string
param location string

var caeName = 'cae-${name}-${environmentName}'

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
   name: caeName
   location: location
   properties: {
      zoneRedundant: false
      workloadProfiles: [
         {
            workloadProfileType: 'Consumption'
            name: 'Consumption'
         }
      ]
   }
 }

 output name string = environment.name
