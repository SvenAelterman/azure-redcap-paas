@description('Server Name for Azure database for MySQL')
param flexibleSqlServerName string

param location string
param tags object

// TODO: skuName and SkuTier are related; should be specified as a single object param, IMHO
@description('Azure database for MySQL sku name ')
param skuName string = 'Standard_B1ms'

@description('Azure database for MySQL pricing tier')
@allowed([
  'GeneralPurpose'
  'MemoryOptimized'
  'Burstable'
])
param SkuTier string = 'Burstable'

@description('Azure database for MySQL storage Size ')
param StorageSizeGB int = 20

@description('Azure database for MySQL storage Iops')
param StorageIops int = 360

param peSubnetId string
param privateDnsZoneId string

param adminUserName string

param roles object
param uamiId string
param uamiPrincipalId string
param deploymentScriptName string

@description('Database administrator password')
@minLength(8)
@secure()
param adminPassword string

@description('MySQL version')
@allowed([
  '8.0.21'
])
param mysqlVersion string = '8.0.21'

@allowed([
  'Enabled'
  'Disabled'
])
@description('Whether or not geo redundant backup is enabled.')
param geoRedundantBackup string = 'Disabled'

param backupRetentionDays int = 7

@allowed([
  'Enabled'
  'Disabled'
])
param highAvailability string = 'Disabled'

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

param databaseName string
param database_charset string = 'utf8'
param database_collation string = 'utf8_general_ci'

param currentTime string = utcNow()

module flexibleServer 'br/public:avm/res/db-for-my-sql/flexible-server:0.4.1' = {
  // TODO: Rename this deployment
  name: 'FlexibleServerDeployment'
  params: {
    name: flexibleSqlServerName
    location: location
    skuName: skuName
    tier: SkuTier

    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword

    privateDnsZoneResourceId: privateDnsZoneId
    delegatedSubnetResourceId: peSubnetId

    backupRetentionDays: backupRetentionDays
    geoRedundantBackup: geoRedundantBackup

    version: mysqlVersion

    storageAutoGrow: 'Enabled'
    storageAutoIoScaling: 'Enabled'
    storageIOPS: StorageIops
    storageSizeGB: StorageSizeGB

    // TODO: Use parameter
    highAvailability: 'Disabled'

    databases: [
      {
        name: databaseName
        charset: database_charset
        collation: database_collation
      }
    ]
  }
}

// resource server 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
//   name: flexibleSqlServerName
//   location: location
//   tags: tags
//   sku: {
//     name: skuName
//     tier: SkuTier
//   }
//   properties: {
//     administratorLogin: adminUserName
//     administratorLoginPassword: adminPassword
//     version: mysqlVersion
//     replicationRole: 'None'
//     createMode: 'Default'
//     backup: {
//       backupRetentionDays: backupRetentionDays
//       geoRedundantBackup: geoRedundantBackup
//     }
//     highAvailability: {
//       mode: highAvailability
//     }
//     network: {
//       delegatedSubnetResourceId: peSubnetId
//       privateDnsZoneResourceId: privateDnsZoneId
//       //publicNetworkAccess: publicNetworkAccess
//     }
//     storage: {
//       autoGrow: 'Enabled'
//       iops: StorageIops
//       storageSizeGB: StorageSizeGB
//       autoIoScaling: 'Enabled'
//       logOnDisk: 'Disabled'
//     }
//   }
// }

// resource database 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-30' = {
//   parent: server
//   name: databaseName
//   properties: {
//     charset: database_charset
//     collation: database_collation
//   }
// }

// Assign the Contributor role to the UAMI on the MySQL server to enable setting the "invisible primary key" parameter
module uamiMySqlRoleAssignmentModule '../common/roleAssignment-mySql.bicep' = {
  name: 'mySqlRole'
  params: {
    mySqlFlexServerName: flexibleServer.outputs.name
    principalId: uamiPrincipalId
    roleDefinitionId: roles.Contributor
  }
}

// Turn off the "invisible primary key" parameter on the server
resource dbConfigDeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.50.0'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    forceUpdateTag: currentTime
    scriptContent: 'az mysql flexible-server parameter set -g ${resourceGroup().name} --server-name ${flexibleServer.outputs.name} --name sql_generate_invisible_primary_key --value OFF'
  }
  tags: tags
  dependsOn: [uamiMySqlRoleAssignmentModule]
}

output mySqlServerName string = flexibleServer.outputs.name
output databaseName string = databaseName
output sqlAdmin string = adminUserName // server.properties.administratorLogin
output fqdn string = flexibleServer.outputs.fqdn
