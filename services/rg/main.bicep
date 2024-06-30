targetScope = 'subscription'

param rgName string
param location string
param tags object

@description('Resource group creation')
module resourceGroupModule '../../modules/resource_group/rg.bicep' =   {
    name: '${rgName}-rg-create'
    params: {
      resourceGroupLocation: location
      resourceGroupName: rgName
      tags: tags
    }
    scope: subscription()
  }

