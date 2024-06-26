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

@batchSize(1)
@description('subnet creation')
module subnetModule '../../../modules/subnet/subnet.bicep' = [
  for rg in items(configFinal.subnet): {
    name: '${rg.key}-snet-create'
     params: {
      subnetName: rg.key
      addressPrefixes:rg.value
      vnetName: configFinal.vnet.name
     }
    scope: resourceGroup(networkRgName)

    dependsOn: [resourceGroupModule, vnet]
  }
]

var jumpBoxSubnetName = first(filter(items(configFinal.subnet), snet => snet.key == 'jump-box'))!.key


@batchSize(1)
@description('vm creation')
module vmModule '../../../modules/vm_win/vm_win.bicep' = [
  for rg in items(configFinal.virtual_machine): {
    name: '${rg.key}-vm-create'
     params: {
      vmConfig: rg.value
      globalConfigMap : globalConfigMap.global_map
      adminUsername: 'adadmin'
      adminPassword: 'P@$$w0rd1234!'
      publicIPAllocationMethod: 'Static'
      publicIpSku: 'Standard'
      virtualNetworkName: configFinal.vnet.name
      subnetName: jumpBoxSubnetName
     }
    scope: resourceGroup(networkRgName)

    dependsOn: [subnetModule]
  }
]

