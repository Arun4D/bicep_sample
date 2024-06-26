targetScope = 'resourceGroup'

param nsgName string = 'myNSG'
param location string = resourceGroup().location
param tags object

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  tags: tags
}

output nsgDetails object = {
  name: nsgName
  id: nsg.id
}
