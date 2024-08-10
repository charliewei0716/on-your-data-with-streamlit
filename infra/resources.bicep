param resourceGroupName string
param location string

@minLength(3)
@maxLength(22)
param resourceToken string

param tags object

param principalId string

var abbrs = loadJsonContent('./abbreviations.json')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-04-01' = {
  parent: storageAccount::blobService
  name: 'data'
}

resource azureOpenAI 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
  location: 'eastus2'
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
  }
}

resource gpt4o 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {  
  name: 'gpt-4o'
  parent: azureOpenAI
  sku: {
    name: 'GlobalStandard'
    capacity: 100
  }
  properties: {
    model: {
      format:'OpenAI'
      name:'gpt-4o'
      version:'2024-05-13'
    }
  }  
}

resource embedding 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' =  {  
  name: 'text-embedding-ada-002'  
  parent: azureOpenAI  
  sku: {
    name: 'Standard'
    capacity: 100
  }
  properties: {
    model: {
      format:'OpenAI'
      name:'text-embedding-ada-002'
      version: '2'
    }
  }
  dependsOn:[
    gpt4o
  ]
}

resource azureAISearch 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: '${abbrs.searchSearchServices}${resourceToken}'
  location: location
  sku: {
    name: 'basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
  }
}

resource searchIndexDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: azureAISearch
  name: guid(azureAISearch.id, azureOpenAI.id, resourceId('Microsoft.Authorization/roleDefinitions', '1407120a-92aa-4202-b7e9-c0e197c71c8f'))
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '1407120a-92aa-4202-b7e9-c0e197c71c8f')
    principalId: azureOpenAI.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource searchServiceContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: azureAISearch
  name: guid(azureAISearch.id, azureOpenAI.id, resourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0'))
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
    principalId: azureOpenAI.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: guid(storageAccount.id, azureOpenAI.id, resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'))
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: azureOpenAI.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource cognitiveServicesOpenAIContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: azureOpenAI
  name: guid(azureOpenAI.id, azureAISearch.id, resourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442'))
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442')
    principalId: azureAISearch.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: guid(storageAccount.id, azureAISearch.id, resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'))
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalId: azureAISearch.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  location: resourceGroup().location
}

resource roleAssignmentContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageAccount.id, resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c'))
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentStorageBlobContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: guid(storageAccount.id, resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'))
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'script-${resourceToken}'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '3.0'
    arguments: '-resourceGroupName ${resourceGroupName} -storageAccountName ${storageAccount.name} -storageAccountId ${storageAccount.id} -azureOpenAIName ${azureOpenAI.name} -aoaiKey ${azureOpenAI.listKeys().key1} -azureAISearchName ${azureAISearch.name}'
    scriptContent: '''
      param (
        [string]$resourceGroupName,
        [string]$storageAccountName,
        [string]$storageAccountId,
        [string]$azureOpenAIName,
        [string]$aoaiKey,
        [string]$azureAISearchName
      )
      
      Set-Content -Path data.txt -Value '7月24日 颱風天'
      $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
      Set-AzStorageBlobContent -File 'data.txt' -Container 'data' -Blob 'data.txt' -Context $storageAccount.Context
      $uri = "https://${azureOpenAIName}.openai.azure.com/openai/ingestion/jobs/data?api-version=2024-05-01-preview"
      $headers = @{'api-key' = $aoaiKey}
      $body = @{
        kind = "SystemCompute"
        searchServiceConnection = @{
          kind = "EndpointWithManagedIdentity"
          endpoint = "https://${azureAISearchName}.search.windows.net"
        }
        datasource = @{
          kind = "Storage"
          containerName = "data"
          chunkingSettings = @{
            maxChunkSizeInTokens = 1024
          }
          storageAccountConnection = @{
            kind = "EndpointWithManagedIdentity"
            endpoint = "https://${storageAccountName}.blob.core.windows.net/"
            resourceId = "ResourceId=${storageAccountId}"
          }
          embeddingsSettings = @(
            @{
              embeddingResourceConnection = @{
                kind = "RelativeConnection"
              }
              modelProvider = "AOAI"
              deploymentName = "text-embedding-ada-002"
            }
          )
        }
        dataRefreshIntervalInHours = 24
        completionAction = "keepAllAssets"
      } | ConvertTo-Json -Depth 5
       
      Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $body -ContentType 'application/json'
    '''
    retentionInterval: 'PT1H'
  }
  dependsOn: [
    searchIndexDataReader
    searchServiceContributor
    storageBlobDataContributor
    cognitiveServicesOpenAIContributor
    storageBlobDataReader
  ]
}

resource cognitiveServicesOpenAIUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: azureOpenAI
  name: guid(azureOpenAI.id, principalId, resourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'))
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: principalId
    principalType: 'User'
  }
}

output AZURE_OPENAI_ENDPOINT string = 'https://${azureOpenAI.name}.openai.azure.com/'
output AZURE_SEARCH_ENDPOINT string = 'https://${azureAISearch.name}.search.windows.net'
