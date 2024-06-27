targetScope = 'subscription'

var configMap = loadJsonContent('../../config/dev.json')
var globalConfigMap = loadJsonContent('../../config/global.json')
var configFinal = union(configMap.config, globalConfigMap.global_map)
var envTagsFinal = union(configMap.environment_tags, globalConfigMap.global_tags)

@description('Resource group creation')
module resourceGroupModule '../../../modules/resource_group/rg.bicep' = [
  for rg in items(configFinal.resource_group): {
    name: '${rg.key}-rg-create'
    params: {
      resourceGroupLocation: configFinal.location
      resourceGroupName: rg.value
      tags: envTagsFinal
    }
    scope: subscription()
  }
]

output resourceGroupOutput array = [
  for (rg, i) in items(configFinal.resource_group): {
    name: resourceGroupModule[i].outputs.resourceGroupDetails.name
    location: resourceGroupModule[i].outputs.resourceGroupDetails.location
    id: resourceGroupModule[i].outputs.resourceGroupDetails.id
  }
]

var networkRgName = first(filter(items(configFinal.resource_group), rg => rg.key == 'nw')).?value
//var jmpRgName = first(filter(items(configFinal.resource_group), rg => rg.key == 'jmp')).?value

@description('Virtual network creation')
module vnet '../../../modules/vnet/vnet.bicep' = {
  name: '${configFinal.vnet.name}-create'
  params: {
    vnetName: configFinal.vnet.name
    vnetLocation: configFinal.location
    addressPrefix: configFinal.vnet.address_space
    subnet: configFinal.subnet
    tags: envTagsFinal
  }
  scope: resourceGroup(networkRgName)

  dependsOn: [resourceGroupModule]
}

@description('NSG creation')
module nsgModule '../../../modules/nsg/nsg.bicep' = [
  for rg in items(configFinal.nsg): {
    name: '${rg.key}-nsg-create'
    params: {
      nsgName: rg.value
      tags: envTagsFinal
    }
    scope: resourceGroup(networkRgName)

    dependsOn: [resourceGroupModule, vnet]
  }
]

var jumpBoxSubnetName = first(filter(items(configFinal.subnet), snet => snet.key == 'jump-box'))!.key
var azureBastionSubnetName = first(filter(items(configFinal.subnet), snet => snet.key == 'AzureBastionSubnet'))!.key

@batchSize(1)
@description('vm creation')
module vmModule '../../../modules/vm_win/vm_win.bicep' = [
  for rg in items(configFinal.virtual_machine): {
    name: '${rg.key}-vm-create'
    params: {
      vmConfig: rg.value
      globalConfigMap: globalConfigMap.global_map
      adminUsername: 'adadmin'
      adminPassword: 'P@$$w0rd1234!'
      publicIPAllocationMethod: 'Static'
      publicIpSku: 'Standard'
      virtualNetworkName: configFinal.vnet.name
      subnetName: jumpBoxSubnetName
    }
    scope: resourceGroup(networkRgName)

    dependsOn: [vnet]
  }
]

@description('PublicIP creation')
module publicipModule '../../../modules/publicip/publicip.bicep' = {
  name: '${configFinal.publicip.name}'
  params: {
    sku_name: configFinal.publicip.sku_name
    privateIPAllocationMethod: configFinal.publicip.privateIPAllocationMethod
    tags: envTagsFinal
  }
  scope: resourceGroup(networkRgName)

  dependsOn: [vmModule]
}

@description('Bastion creation')
module bastionModule '../../../modules/bastion/bastion.bicep' = {
  name: '${configFinal.bastion.name}'
  params: {
    bastionPublicIpId: publicipModule.outputs.pipDetails.id
    virtualNetworkName: configFinal.vnet.name
    subnetName: azureBastionSubnetName
    sku_name: configFinal.bastion.sku_name
    privateIPAllocationMethod: configFinal.bastion.privateIPAllocationMethod
    tags: envTagsFinal
  }
  scope: resourceGroup(networkRgName)

  dependsOn: [publicipModule]
}

module webappModule '../../../modules/webapp/webapp.bicep' = {
  name: 'adwebapp-create'
  params: {
  }
  scope: resourceGroup(networkRgName)

  dependsOn: [bastionModule]
}

module privateEndpointModule '../../../modules/privateEndpoint/privateEndpoint.bicep' = {
  name: 'privateEndpoint-create'
  params: {
    webAppName: webappModule.outputs.webappDetails.webAppName
    webAppId: webappModule.outputs.webappDetails.webAppId
    virtualNetworkName: configFinal.vnet.name
    subnetName: jumpBoxSubnetName
    vnetId: vnet.outputs.vnetId
    tags: envTagsFinal
  }
  scope: resourceGroup(networkRgName)

  dependsOn: [webappModule, vnet]
}
