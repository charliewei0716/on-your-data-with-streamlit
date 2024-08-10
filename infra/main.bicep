targetScope = 'subscription'

@description('Name of the environment used to generate a short unique hash for resources.')
@minLength(1)
@maxLength(64)
param environmentName string

@description('Primary location for all resources')
param location string

param principalId string

var tags = { 'azd-env-name': environmentName }

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

var abbrs = loadJsonContent('./abbreviations.json')

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'resources'
  scope: resourceGroup
  params: {
    resourceGroupName: resourceGroup.name
    location: location
    resourceToken: resourceToken
    tags: tags
    principalId: principalId
  }
}

output AZURE_OPENAI_ENDPOINT string = resources.outputs.AZURE_OPENAI_ENDPOINT
output AZURE_SEARCH_ENDPOINT string = resources.outputs.AZURE_SEARCH_ENDPOINT
