param vmConfig object
param globalConfigMap object

param has_public_ip bool = vmConfig.has_public_ip
param instanceArray array = vmConfig.instance_name
param ip_address array = vmConfig.ip_address
param vm_size [string] = vmConfig.vm_size
param image string = vmConfig.image

param subnetName string = 'Subnet'
param virtualNetworkName string = 'MyVNET'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Allocation method for the Public IP used to access the Virtual Machine.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('SKU for the Public IP used to access the Virtual Machine.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Standard'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = [
  for vmName in instanceArray: if (has_public_ip) {
    name: '${vmName}-public-ip'
    location: location
    sku: {
      name: publicIpSku
    }
    properties: {
      publicIPAllocationMethod: publicIPAllocationMethod
      dnsSettings: {
        domainNameLabel: toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')
      }
    }
  }
]

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = [
  for (vmName, index) in instanceArray: {
    name: '${vmName}-nic'
    location: location
    properties: {
      ipConfigurations: [
        for (nic, nic_index) in ip_address[index]: {
          name: '${vmName}-${nic.name}}'
          properties: {
            privateIPAllocationMethod: nic.allocation_type
            privateIPAddressVersion: nic.ip
            primary: nic.primary
            subnet: {
              id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
            }
          }
        }
      ]
    }
  }
]

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = [
  for (vmName, index) in instanceArray: {
    name: vmName
    location: location
    properties: {
      hardwareProfile: {
        vmSize: vm_size[index]
      }
      osProfile: {
        computerName: vmName
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      storageProfile: {
        imageReference: {
          publisher: first(filter(items(globalConfigMap.image), l_image => l_image.key == image)).?value.?publisher
          offer: first(filter(items(globalConfigMap.image), l_image => l_image.key == image)).?value.?offer
          sku: first(filter(items(globalConfigMap.image), l_image => l_image.key == image)).?value.?sku
          version: first(filter(items(globalConfigMap.image), l_image => l_image.key == image)).?value.?version
        }
        osDisk: {
          createOption: 'FromImage'
          diskSizeGB: first(filter(items(globalConfigMap.disk_size), disk => disk.key == vmConfig.os_disk_size)).?value
          managedDisk: {
            storageAccountType: first(filter(
              items(globalConfigMap.data_disk_types),
              disk => disk.key == substring(vmConfig.os_disk_size, 0, 1)
            )).?value
          }
        }
        /*       dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ] */
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: nic[vmName].id
          }
        ]
      }
      /* diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    } */
      securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
    }
    dependsOn:[nic]
  }
  
]
