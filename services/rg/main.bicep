targetScope = 'subscription'

param rgName string
param location string
param tags object

var configMap = loadJsonContent('../config/rg.json')
var globalConfigMap = loadJsonContent('../config/global.json')
var envTags = union(configMap.environment_tags, globalConfigMap.global_tags)
var envTagsFinal = union(tags, envTags)


@description('Resource group creation')
module resourceGroupModule '../../modules/resource_group/rg.bicep' =   {
    name: '${rgName}-rg-create'
    params: {
      resourceGroupLocation: location
      resourceGroupName: rgName
      tags: envTagsFinal
    }
    scope: subscription()
  }

