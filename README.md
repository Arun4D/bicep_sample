# bicep_sample

## Build
````
bicep build ./main.bicep --stdout
````

## deploy

1. Create Resource sunscription scope

````
bicep build ./main.bicep --stdout

az deployment sub create  --location westus --name dev-deploy01 --template-file ./main.bicep

az stack sub create  --location westus --name dev-deploy01 --template-file ./main.bicep --deny-settings-mode None

az deployment sub delete --name dev-deploy01
````

2. Delete Resource 

````
az deployment sub delete --name dev-deploy01

````

## Azure DevOps Api Trigger sample

````
echo -n 'Arun Duraisamy:<<PAT>>' | base64


curl -X GET \
  'https://dev.azure.com/arun4duraisamy0719/Bicep-demo/_apis/build/builds?api-version=6.1-preview.6' \
  -H 'Authorization: Basic <<Base64 PAT>>' \
  -H 'Cache-Control: no-cache' -v
````

## Reference

[Vm Creation](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-bicep?tabs=CLI)