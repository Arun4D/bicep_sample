targetScope = 'subscription'

param resourceGroupName string
param resourceGroupLocation string
param tags object

resource newResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: tags
}

output resourceGroupDetails object = {
  name: newResourceGroup.name
  location: newResourceGroup.location
  id: newResourceGroup.id
}
