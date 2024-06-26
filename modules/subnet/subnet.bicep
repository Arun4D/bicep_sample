targetScope = 'resourceGroup'

param subnetName string
param addressPrefixes [string]
param vnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

// subnet Resource
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefixes: addressPrefixes
    
  }
}

// Output the subnet ID
output subnetDetails object = {
  name: subnetName
  id: subnet.id
}
