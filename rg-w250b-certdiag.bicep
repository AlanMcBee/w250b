param sites_app_w250b_certdiag_name string = 'app-w250b-certdiag'
param vaults_kv_w250b_certdiag_name string = 'kv-w250b-certdiag'
param serverfarms_asp_w250b_certdiag_name string = 'asp-w250b-certdiag'
param certificates_cert_w250b_certdiag_name string = 'cert-w250b-certdiag'
param certificates_overthinker_blog_app_w250b_certdiag_undefined_name string = 'overthinker.blog-app-w250b-certdiag-undefined'

resource vaults_kv_w250b_certdiag_name_resource 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: vaults_kv_w250b_certdiag_name
  location: 'eastus'
  properties: {
    sku: {
      family: 'A'
      name: 'Standard'
    }
    tenantId: 'e610ede6-70d4-4d98-8337-26dd7081ef0e'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: '98.36.158.27/32'
        }
      ]
      virtualNetworkRules: []
    }
    accessPolicies: [
      {
        tenantId: 'e610ede6-70d4-4d98-8337-26dd7081ef0e'
        objectId: '887235fb-6466-474f-a7f8-d3e55b4466d1'
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'GetRotationPolicy'
            'SetRotationPolicy'
            'Rotate'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
        }
      }
      {
        tenantId: 'e610ede6-70d4-4d98-8337-26dd7081ef0e'
        objectId: 'c01c622f-874a-455f-899b-6d637ffff2a0'
        permissions: {
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    vaultUri: 'https://${vaults_kv_w250b_certdiag_name}.vault.azure.net/'
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

resource certificates_overthinker_blog_app_w250b_certdiag_undefined_name_resource 'Microsoft.Web/certificates@2022-03-01' = {
  name: certificates_overthinker_blog_app_w250b_certdiag_undefined_name
  location: 'East US'
  properties: {
    hostNames: [
      'overthinker.blog'
    ]
    canonicalName: 'overthinker.blog'
  }
}

resource serverfarms_asp_w250b_certdiag_name_resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: serverfarms_asp_w250b_certdiag_name
  location: 'East US'
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'app'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource vaults_kv_w250b_certdiag_name_cert_w250b_certdiag 'Microsoft.KeyVault/vaults/keys@2022-11-01' = {
  parent: vaults_kv_w250b_certdiag_name_resource
  name: 'cert-w250b-certdiag'
  location: 'eastus'
  properties: {
    attributes: {
      enabled: true
      nbf: 1677529894
      exp: 1709067094
    }
  }
}

resource Microsoft_KeyVault_vaults_secrets_vaults_kv_w250b_certdiag_name_cert_w250b_certdiag 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  parent: vaults_kv_w250b_certdiag_name_resource
  name: 'cert-w250b-certdiag'
  location: 'eastus'
  properties: {
    contentType: 'application/x-pkcs12'
    attributes: {
      enabled: true
      nbf: 1677529894
      exp: 1709067094
    }
  }
}

resource certificates_cert_w250b_certdiag_name_resource 'Microsoft.Web/certificates@2022-03-01' = {
  name: certificates_cert_w250b_certdiag_name
  location: 'East US'
  properties: {
    hostNames: [
      'overthinker.blog'
    ]
    keyVaultId: vaults_kv_w250b_certdiag_name_resource.id
    keyVaultSecretName: certificates_cert_w250b_certdiag_name
  }
}

resource sites_app_w250b_certdiag_name_resource 'Microsoft.Web/sites@2022-03-01' = {
  name: sites_app_w250b_certdiag_name
  location: 'East US'
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${sites_app_w250b_certdiag_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'overthinker.blog'
        sslState: 'SniEnabled'
        thumbprint: '0FE730FC9EFDFE9761E15A4BF2698D79EA622042'
        hostType: 'Standard'
      }
      {
        name: '${sites_app_w250b_certdiag_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverfarms_asp_w250b_certdiag_name_resource.id
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    customDomainVerificationId: '4FB57762254A57D926249B095A1A678BDD39F78ED134E0AEADF8965B633C6780'
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource sites_app_w250b_certdiag_name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  parent: sites_app_w250b_certdiag_name_resource
  name: 'ftp'
  location: 'East US'
  properties: {
    allow: true
  }
}

resource sites_app_w250b_certdiag_name_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  parent: sites_app_w250b_certdiag_name_resource
  name: 'scm'
  location: 'East US'
  properties: {
    allow: true
  }
}

resource sites_app_w250b_certdiag_name_web 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: sites_app_w250b_certdiag_name_resource
  name: 'web'
  location: 'East US'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.html'
      'index.html'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v6.0'
    phpVersion: '5.6'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: true
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 100
    detailedErrorLoggingEnabled: false
    publishingUsername: '$app-w250b-certdiag'
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'Disabled'
    preWarmedInstanceCount: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {
    }
  }
}

resource sites_app_w250b_certdiag_name_sites_app_w250b_certdiag_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: sites_app_w250b_certdiag_name_resource
  name: '${sites_app_w250b_certdiag_name}.azurewebsites.net'
  location: 'East US'
  properties: {
    siteName: 'app-w250b-certdiag'
    hostNameType: 'Verified'
  }
}

resource sites_app_w250b_certdiag_name_overthinker_blog 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: sites_app_w250b_certdiag_name_resource
  name: 'overthinker.blog'
  location: 'East US'
  properties: {
    siteName: 'app-w250b-certdiag'
    hostNameType: 'Verified'
    sslState: 'SniEnabled'
    thumbprint: '0FE730FC9EFDFE9761E15A4BF2698D79EA622042'
  }
}