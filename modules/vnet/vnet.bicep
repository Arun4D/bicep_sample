targetScope = 'resourceGroup'

param vnetName string
param vnetLocation string
param addressPrefix [string]
param subnet object
param tags object

// Virtual Network Resource
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefix
    }
    subnets: [
      for snet in items(subnet): {
        name: snet.key
        properties: {
          addressPrefixes: snet.value
        }
      }
    ]
  }
  tags: tags
}

// Output the VNet ID
output vnetId string = vnet.id
