param name string

@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param sku string = 'basic'

@minValue(1)
@maxValue(12)
param replicaCount int = 1

@allowed([
  1
  2
  3
  4
  6
  12
])
param partitionCount int = 1

param location string

resource search 'Microsoft.Search/searchServices@2020-08-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
  }
}


output uri string = 'https://${search.name}.search.windows.net'
output name string = search.name
