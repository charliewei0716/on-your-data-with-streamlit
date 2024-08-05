param location string
param resourceToken string
param tags object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${abbrs.webServerFarms}${resourceToken}'
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: 'B1'
  }
  kind: 'linux'
}

resource web 'Microsoft.Web/sites@2022-03-01' = {
  name: '${abbrs.webSitesAppService}${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.9'
      ftpsState: 'Disabled'
      appCommandLine: 'startup.sh'
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }

 resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
      ENABLE_ORYX_BUILD: 'true'
    }
  }
