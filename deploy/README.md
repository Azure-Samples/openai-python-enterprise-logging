# Deployment steps using infrastructure-as-code
While the reference architecture can be deployed using the Azure Portal, leveraging infrastructure-as-code can make the process quicker and more repeatable. The following outlines how to leverage the Bicep code in this repository to deploy the reference architecture.

## Prerequisites
- [Azure Subscription](https://azure.microsoft.com/en-us/get-started/)
- [Azure OpenAI Application](https://aka.ms/oai/access) 

## Provision the Azure resources
### Provision the Azure resources that are defined in the Bicep code
1. Sign in to the Azure Portal, and open the Cloud Shell. The following steps will assume the use of Bash
2. `git clone` this repository
3. `cd` to the `deploy` directory
4. Create a variable called `RG` and assign a resource group name you prefer (e.g., `RG=rg-openaiapp`)
5. Create a vailable called `LOC` and assign the name of the Azure region you prefer (e.g., `LOC=eastus`) 
6. Create the resource group: `az group create -l $LOC -n $RG`
7. Preview the changes that will be made with the Bicep code: `az deployment group what-if --resource-group $RG --template-file main.bicep --parameters @main.parameters.json` (If asked to specify parameters `suffix` and `customSubDomainName` then set a unique value of your choice)
8. Apply the Bicep code: `az deployment group create --resource-group $RG --template-file main.bicep --parameters @main.parameters.json` (If asked to specify parameters `suffix` and `customSubDomainName` then set a unique value of your choice)

### Provision the remaining Azure resources
The current version of the Bicep does not deploy the following Azure resources, do they need to be deployed using other means such as through the Azure Portal GUI.
-	Azure Log Analytics
-	Azure Key Vault
-	Azure Storage

## Configuration
The current version of the Bicep does not include all the configuration that is needed. Therefore follow the steps outlined [here]
(https://github.com/Azure-Samples/openai-python-enterprise-logging#configuration), and apply the configurations that are missings