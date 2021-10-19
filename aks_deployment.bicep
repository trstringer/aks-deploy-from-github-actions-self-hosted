targetScope = 'subscription'

param location string = 'eastus'
param resourceName string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceName
  location: location
}

module aks './aks_cluster.bicep' = {
  name: resourceName
  scope: rg
  params: {
    location: location
    clusterName: resourceName
  }
}
