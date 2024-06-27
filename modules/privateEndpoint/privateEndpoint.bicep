targetScope = 'resourceGroup'

param webAppName string = 'ad-webAppName'
param location string = resourceGroup().location
param webAppId string
param subnetName string
param virtualNetworkName string
param vnetId string
var privateEndpointName = '${webAppName}-privateEndpoint'
var privateDnsZoneName = 'privatelink.azurewebsites.net'
var pvtEndpointDnsGroupName = '${privateEndpointName}/mydnsgroupname'
param tags object

// Resource for Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${webAppName}-privateEndpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: '${webAppName}-privateLink'
        properties: {
          privateLinkServiceId: webAppId
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
  tags: tags
}


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}

}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

output privateEndpointDetails object = {
  name: privateEndpoint.name
  id: privateEndpoint.id
}
