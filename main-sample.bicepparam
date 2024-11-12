using './main.bicep'

// These parameters might have acceptable defaults.
param location = 'eastus'
param environment = 'demo'
param workloadName = 'redcap'
param namingConvention = '{workloadName}-{env}-{rtype}-{loc}-{seq}'
param sequence = 1

// These parameters should be modified for your environment
param identityObjectId = '<Valid Entra ID object ID for permissions assignment>'
param vnetAddressSpace = '10.0.0.0/24'

// There are two options for obtaining the REDCap zip file:
// 1. Specify a URL to a publicly accessible zip file.
//    This URL should not require authentication of any kind. For example, an Azure blob storage URL with a SAS token is supported.
// 2. Specify a REDCap community username and password to download the zip file from the REDCap community.
//    Do not specify a URL if you are using this option. The deployment script will download the zip file from the REDCap community.
param redcapZipUrl = '<Valid Redcap Zip URL>'
// -- OR --
param redcapCommunityUsername = '<Valid REDCap Community Username>'
param redcapCommunityPassword = '<Valid REDCap Community Password>'

// These values are used to configure the App Service Deployment Center.
// The defaults below are the Microsoft-maintained Azure REDCap PaaS repository.
// However, you should consider forking that repository and referencing your fork.
// If not specified, the deployment will use the Microsoft-maintained Azure REDCap PaaS repository.
param scmRepoUrl = 'https://github.com/Microsoft/azure-redcap-paas'
param scmRepoBranch = 'main'

// Specify the values for the SMTP host REDCap will use to send emails.
// These values may be left blank if you will not use SMTP for email notifications.
param smtpFQDN = '<Specify valid SMTP FQDN>'
// Be aware of possible restrictions to using SMTP port 25 in Azure.
// See https://learn.microsoft.com/azure/virtual-network/troubleshoot-outbound-smtp-connectivity
param smtpPort = '587'
param smtpFromEmailAddress = '<Specify valid SMTP From Email Address>'

// ** Do not specify anything here! **
// This parameter is required to ensure the parameter file is valid, but should be blank so the password doesn't leak. 
// A new password is generated for each deployment and stored in Key Vault.
param sqlPassword = ''

// param existingVirtualNetworkId = '/subscriptions/c236b7b3-dec1-47a6-856c-8c1f45d88575/resourceGroups/redcap-networkexisting-test-rg-cnc-01/providers/Microsoft.Network/virtualNetworks/redcap-existing-demo-vnet-cnc-01'
// param existingPrivateDnsZonesResourceGroupId = '/subscriptions/c236b7b3-dec1-47a6-856c-8c1f45d88575/resourceGroups/redcap-networkexisting-test-rg-cnc-01'

// param subnets = {
//   PrivateLinkSubnet: {
//     existingSubnetName: 'PlSubnet'
//   }
//   MySQLFlexSubnet: {
//     existingSubnetName: 'SqlSubnet'
//   }
//   IntegrationSubnet: {
//     existingSubnetName: 'WebAppSubnet'
//   }
// }

// param mySqlSkuTier = 'GeneralPurpose'
// param mySqlHighAvailability = 'Enabled'
// param mySqlSkuName = 'Standard_D4ds_v4'
// param availabilityZonesEnabled = true
// param mySqlStorageSizeGB = 200
// param mySqlStorageIops = 1200

// param appServiceTimeZone = 'UTC'
