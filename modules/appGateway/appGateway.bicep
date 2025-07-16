param domainName string

param backendUrl string
param name string
param pipName string
param agwSku string = 'WAF_v2'
param subnetId string

param tags object

param uamiId string
param uamiPrincipalId string

param tlsCertificateInKeyVaultId string
param roles object

param deploymentNameStructure string

// var keyVaultSubscriptionId = split(tlsCertificateInKeyVaultId, '/')[2]
// var keyVaultResourceGroupName = split(tlsCertificateInKeyVaultId, '/')[4]

// Assign permissions to the identity to retrieve the Key Vault secret for the certificate
// resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
//   name: split(tlsCertificateInKeyVaultId, '/')[8]
//   scope: resourceGroup(keyVaultSubscriptionId, keyVaultResourceGroupName)
// }

// resource secret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' existing = {
//   name: split(tlsCertificateInKeyVaultId, '/')[10]
//   parent: keyVault
// }

// resource secretRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(resourceGroup().id, uamiPrincipalId, roles['Key Vault Secrets User'])
//   // TODO: Use the correct scope for this role assignment (secret only)
//   //scope: secret
//   properties: {
//     roleDefinitionId: roles['Key Vault Secrets User']
//     principalType: 'ServicePrincipal'
//     principalId: uamiPrincipalId
//   }
// }

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'agw-pip'), 64)
  params: {
    name: pipName

    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    tags: tags
    zones: [1, 2, 3]
  }
}

var backendPoolName = 'appServiceBackendPool'
var backendHttpSettingsName = 'appServiceBackendHttpsSetting'
var frontendPortName = 'port443'
var frontendIpConfigurationName = 'public'
var httpsListenerName = 'public443'
var httpListenerName = 'public80'
var sslCertificateName = 'az-apgw-x-002-ssl-certificate'

module applicationGateway 'br/public:avm/res/network/application-gateway:0.7.0' = {
  name: 'applicationGatewayDeployment'
  params: {
    name: name
    availabilityZones: [1, 2, 3]

    gatewayIPConfigurations: [
      {
        name: 'apw-ip-configuration'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: backendUrl
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsName
        properties: {
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          port: 443
          protocol: 'Https'
          requestTimeout: 30
        }
      }
    ]
    enableHttp2: true
    enableTelemetry: false
    frontendIPConfigurations: [
      {
        name: frontendIpConfigurationName
        properties: {
          publicIPAddress: {
            id: publicIpAddress.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortName
        properties: {
          port: 443
        }
      }
    ]
    httpListeners: [
      {
        name: httpsListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              name,
              frontendIpConfigurationName
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, frontendPortName)
          }
          hostNames: [domainName]
          protocol: 'https'
          requireServerNameIndication: false
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', name, sslCertificateName)
          }
        }
      }
      // {
      //   name: httpListenerName
      //   properties: {
      //     frontendIPConfiguration: {
      //       id: resourceId(
      //         'Microsoft.Network/applicationGateways/frontendIPConfigurations',
      //         name,
      //         frontendIpConfigurationName
      //       )
      //     }
      //     frontendPort: {
      //       id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, frontendPortName)
      //     }
      //     hostNames: []
      //     protocol: 'Http'
      //     requireServerNameIndication: false
      //   }
      // }
    ]
    managedIdentities: {
      userAssignedResourceIds: [
        uamiId
      ]
    }
    probes: [
      // TODO: Create custom probe?
      // {
      //   name: 'privateVmHttpSettingProbe'
      //   properties: {
      //     host: '10.0.0.4'
      //     interval: 60
      //     match: {
      //       statusCodes: [
      //         '200'
      //         '401'
      //       ]
      //     }
      //     minServers: 3
      //     path: '/'
      //     pickHostNameFromBackendHttpSettings: false
      //     protocol: 'Http'
      //     timeout: 15
      //     unhealthyThreshold: 5
      //   }
      // }
    ]
    redirectConfigurations: [
      // {
      //   name: 'httpRedirect80'
      //   properties: {
      //     includePath: true
      //     includeQueryString: true
      //     redirectType: 'Permanent'
      //     requestRoutingRules: [
      //       {
      //         id: resourceId(
      //           'Microsoft.Network/applicationGateways/requestRoutingRules',
      //           name,
      //           'httpRedirect80-public443'
      //         )
      //       }
      //     ]
      //     targetListener: {
      //       id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, httpsListenerName)
      //     }
      //   }
      // }
    ]
    requestRoutingRules: [
      {
        name: 'public443-appServiceBackend'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, backendPoolName)
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              name,
              backendHttpSettingsName
            )
          }
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, httpsListenerName)
          }
          priority: 100
          ruleType: 'Basic'
        }
      }
      // {
      //   name: 'httpRedirect80-public443'
      //   properties: {
      //     httpListener: {
      //       id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, httpListenerName)
      //     }
      //     priority: 300
      //     redirectConfiguration: {
      //       id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', name, 'httpRedirect80')
      //     }
      //     ruleType: 'Basic'
      //   }
      // }
    ]
    rewriteRuleSets: [
      // TODO: Implement for REDCap /surveys endpoint
      // {
      //   name: 'customRewrite'
      //   properties: {
      //     rewriteRules: [
      //       {
      //         actionSet: {
      //           requestHeaderConfigurations: [
      //             {
      //               headerName: 'Content-Type'
      //               headerValue: 'JSON'
      //             }
      //             {
      //               headerName: 'someheader'
      //             }
      //           ]
      //           responseHeaderConfigurations: []
      //         }
      //         conditions: []
      //         name: 'NewRewrite'
      //         ruleSequence: 100
      //       }
      //     ]
      //   }
      // }
    ]
    sku: agwSku
    sslCertificates: [
      {
        name: sslCertificateName
        properties: {
          keyVaultSecretId: tlsCertificateInKeyVaultId
        }
      }
    ]
    tags: tags
  }
}
