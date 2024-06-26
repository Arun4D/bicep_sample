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
````

2. Delete Resource 

````
az deployment sub delete --name dev-deploy01
````