targetScope = 'resourceGroup'

param pipName string = 'ad-publicip'
param location string = resourceGroup().location
param privateIPAllocationMethod string
param sku_name string
param tags object

resource public_ip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: pipName
  location: location
  sku: {
      name: sku_name
  }
  properties: {
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: privateIPAllocationMethod
  }
  tags: tags
}

output pipDetails object = {
  name: pipName
  id: public_ip.id
}
