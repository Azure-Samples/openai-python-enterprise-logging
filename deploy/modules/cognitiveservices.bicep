param name string
param openaiLocation string = 'eastus'

param customSubDomainName string
param deployments array = []
param kind string = 'OpenAI'
param publicNetworkAccess string = 'Disabled'
param sku object = {
  name: 'S0'
}

resource account 'Microsoft.CognitiveServices/accounts@2022-10-01' = {
  name: name
  location: openaiLocation
  kind: kind
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2022-10-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
    scaleSettings: deployment.scaleSettings
  }
}]

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
