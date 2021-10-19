param location string = 'eastus'
param clusterName string

param nodeCount int = 1
param vmSize string = 'standard_b2s'

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: clusterName
  location: location
  sku: {
    name: 'Basic'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool1'
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
      }
    ]
  }
}
