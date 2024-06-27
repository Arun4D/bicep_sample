targetScope = 'resourceGroup'

param bastionName string = 'myBastion'
param location string = resourceGroup().location
param bastionPublicIpId string
param subnetName string
param virtualNetworkName string

param privateIPAllocationMethod string
param sku_name string
param tags object

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: bastionName
  location: location
  sku: {
    name: sku_name
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: privateIPAllocationMethod
          publicIPAddress: {
            id: bastionPublicIpId
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  tags: tags
}

output bastionDetails object = {
  name: bastionName
  id: bastion.id
}
