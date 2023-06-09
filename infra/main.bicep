targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param appEnvironmentName string = 'aca-env'
param pgSvcName string = 'postgres01'
param pgsqlCliAppName string = 'psql-cloud-cli-app'

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module appEnvironment './core/host/container-apps-environment.bicep' = {
  name: 'appEnvironment'
  scope: rg
  params: {
    name: appEnvironmentName
    location: location
    tags: tags
  }
}

module postgres './core/host/container-app-service.bicep' = {
  name: 'postgres'
  scope: rg
  params: {
    name: pgSvcName
    location: location
    tags: tags
    environmentId: appEnvironment.outputs.appEnvironmentId
    serviceType: 'postgres'
  }
}

module psqlCli './core/host/container-app.bicep' = {
  name: 'psqlCli'
  scope: rg
  params: {
    name: pgsqlCliAppName
    location: location
    tags: tags
    environmentId: appEnvironment.outputs.appEnvironmentId
    serviceId: postgres.outputs.serviceId
    containerImage: 'mcr.microsoft.com/k8se/services/postgres:14'
    containerName: 'psql'
    maxReplicas: 1
    minReplicas: 1
    containerCommands: [ '/bin/sleep', 'infinity' ]
  }
}

module pgweb './core/host/container-app.bicep' = {
  name: 'pgweb'
  scope: rg
  params: {
    name: 'pgweb'
    location: location
    tags: tags
    environmentId: appEnvironment.outputs.appEnvironmentId
    serviceId: postgres.outputs.serviceId
    containerImage: 'docker.io/sosedoff/pgweb:latest'
    containerName: 'pgweb'
    maxReplicas: 1
    minReplicas: 1
    containerCommands: [ '/bin/sh' ]
    containerArgs: [ 
      '-c'
      'PGWEB_DATABASE_URL=$POSTGRES_URL /usr/bin/pgweb --bind=0.0.0.0 --listen=8081'
    ]
    targetPort: 8081
    externalIngress: true
  }
}

output PGWEB_URL string = pgweb.outputs.url
output PSQL_CLI_APP_NAME string = psqlCli.outputs.name
output RESOURCE_GROUP string = rg.name
