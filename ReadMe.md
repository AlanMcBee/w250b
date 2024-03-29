# REDCap Deployment

--------------------------------------------------------------------------------

## Deploying manually

### Preconditions

1. Install PowerShell 7.1 or later

1. Install Azure PowerShell modules (2.11 was tested)

1. Connect to Azure using Az PowerShell:

    ```powershell
    Connect-AzAccount
    ```

1. Select correct Azure subscription using Az PowerShell:

    ```powershell
    $subscription = 'subscription name or id' # Change this to your subscription name or id
    Select-AzContext -Subscription $subscription
    ```

1. Clone this git repository locally

1. Recommended (not required, but the instructions from here will assume you did this step):

    1. Install PowerShell SecretManagement and SecretStore modules:

        ```powershell
        Install-Module -Name Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force
        Install-Module -Name Microsoft.PowerShell.SecretStore -Repository PSGallery -Force
        ```

    1. Create a new secret vault:

        ```powershell
        $vaultName = 'REDCap' # Change this to your vault name
        Register-SecretVault -Name $vaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
        ```

    1. Add passwords required by the script to the vault. The names here are examples only:

        ```powershell
        Set-Secret -Name 'MySqlPW' -Secret (Read-Host -AsSecureString 'Enter REDCap MySQL database administrator password')
        Set-Secret -Name 'REDCapPW' -Secret (Read-Host -AsSecureString 'Enter REDCap community user password')
        Set-Secret -Name 'SmtpPW' -Secret (Read-Host -AsSecureString 'Enter SMTP login password')
        Set-Secret -Name 'PfxPW' -Secret (Read-Host -AsSecureString 'Enter PFX certificate password')
        ```

    These values will stay in your vault until you remove them.

1. If you plan to override any of the default values in `redcapAzureDeploy.parameters.json`, make your changes to that file now. Some values you may want to change:

| Parameter                                                   | Default value       | Effective value                          |
| ---------                                                   | -------------       | ---------------                          |
| Cdph_Organization                                           | `ITSD`              | `ITSD`                                   |
| Cdph_BusinessUnit                                           | `ESS`               | `ESS`                                    |
| Cdph_BusinessUnitProgram                                    | `RedCap`            | `RedCap`                                 |
| Cdph_Environment                                            | `Dev`               | `Dev`                                    |
| Cdph_ResourceInstance                                       | `1`                 | `01`                                     |
| Cdph_ClientIPAddress                                        | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| Cdph_SslCertificateThumbprint                               | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
|                                                             |                     |                                          |
| Arm_MainSiteResourceLocation                                | `eastus`            | `eastus`                                 |
| Arm_StorageResourceLocation                                 | `westus`            | `westus`                                 |
| Arm_DeploymentCreationDateTime                              | *(empty)*           | Current UTC date/time                    |
|                                                             |                     |                                          |
| AppServicePlan_SkuName                                      | `S1`                | `S1`                                     |
| AppServicePlan_Capacity                                     | `1`                 | `1` instance                             |
|                                                             |                     |                                          |
| AppService_LinuxFxVersion                                   | `php\               |8.2`                                      | `php\|8.2` |
| AppService_WebApp_Subdomain                                 | *(empty)*           | `redcap-dev-01.cdph.ca.gov`              |
| AppService_WebApp_CustomDomainDnsTxtRecordVerificationValue | *(empty)*           | A random value (shared in output)        |
| AppService_WebHost_SourceControl_GitHubRepositoryUri        | *(empty)*           | `https://github.com/AlanMcBee/w250b.git` |
|                                                             |                     |                                          |
| DatabaseForMySql_Tier                                       | `GeneralPurpose`    | `GeneralPurpose`                         |
| DatabaseForMySql_Sku                                        | `Standard_D4ads_v5` | `Standard_D4ads_v5`                      |
| DatabaseForMySql_ServerName                                 | *(empty)*           | `REDCap-Dev-01.mysql.database.azure.com` |
| DatabaseForMySql_AdministratorLoginName                     | `redcap_app`        | `redcap_app`                             |
| <del>*DatabaseForMySql_AdministratorLoginPassword*</del>    |                     | *DO NOT SET IN THIS FILE*                |
| DatabaseForMySql_StorageGB                                  | `20`                | `20` GiB                                 |
| DatabaseForMySql_BackupRetentionDays                        | `7`                 | `7` days                                 |
| DatabaseForMySql_DbName                                     | `redcap`            | `redcap_db`                              |
|                                                             |                     |                                          |
| StorageAccount_Redundancy                                   | `Standard_LRS`      | `Standard_LRS`                           |
|                                                             |                     |                                          |
| ProjectRedcap_CommunityUsername                             | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| <del>*ProjectRedcap_CommunityPassword*</del>                |                     | *DO NOT SET IN THIS FILE*                |
| ProjectRedcap_DownloadAppZipUri                             | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| ProjectRedcap_DownloadAppZipVersion                         | `latest`            | `latest`                                 |
|                                                             |                     |                                          |
| Smtp_FQDN                                                   | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| Smtp_Port                                                   | `587`               | `587`                                    |
| Smtp_UserLogin                                              | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| <del>*Smtp_UserPassword*</del>                              |                     | *DO NOT SET IN THIS FILE*                |
| Smtp_FromEmailAddress                                       | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
|                                                             |                     |                                          |
| Monitor_ApplicationInsights                                 | `true`              | `true`                                   |

For any parameters that are marked as *OVERRIDE IS REQUIRED*, you must provide a value, either by saving it in the `redcapAzureDeploy.parameters.json` file or by passing it in on the command line (which can include modifying the `Deploy-REDCapKeyVault.ps1` or `Deploy-REDCapMain.ps1` files).
Note that no passwords should be saved in the `redcapAzureDeploy.parameters.json` file. Instead, use the PowerShell SecretStore module to store them in the vault, or else provide them from the command line.
See the []

Consult the files `redcapAzureDeployMain.bicep` and `redcapAzureDeployKeyVault.bicep` for more information about the parameters.

1. Check the availability of resources in the regions you selected.

    While the site https://azure.microsoft.com/en-us/regions/services/ will generally indicate the availability of resources in a region, it does not always reflect limits on your subscription or temporary availability changes.

    1. Azure Database for MySQL Flexible Server

    Use this PowerShell script to check whether the region you selected for the Azure Database for MySQL Flexible Server is available:

    ```powershell
    $flexibleServerSku = 'Standard_D4ads_v5'
    $flexibleServerTier = 'GeneralPurpose'
    $resourceProvider = Get-AzResourceProvider -ProviderNamespace Microsoft.DBforMySQL
    $flexibleServers = $resourceProvider.ResourceTypes | ? ResourceTypeName -eq 'flexibleServers'
    $location = $flexibleServers.Locations | ? { $_ -eq 'East US' }
    # WIP - need to check for $location.Capabilities
    $skus = Get-AzComputeResourceSku -Location eastus
    ```

--------------------------------------------------------------------------------

## Invoking the deployment script

1. In PowerShell, initialize the secure password variables:

    * If you chose to use the PowerShell SecretStore module recommended earlier:

        ```powershell
        $mySqlPW = Get-Secret -Name 'MySqlPW' # Do not use -AsPlainText
        $redCapPW = Get-Secret -Name 'REDCapPW' # Do not use -AsPlainText
        $smtpPW = Get-Secret -Name 'SmtpPW' # Do not use -AsPlainText
        $pfxPW = Get-Secret -Name 'PfxPW' # Do not use -AsPlainText
        ```

    * If you chose ***not*** to use the PowerShell SecretStore module:

        ```powershell
        $mySqlPW = Read-Host -AsSecureString 'Enter REDCap MySQL database administrator password'
        $redCapPW = Read-Host -AsSecureString 'Enter REDCap community user password'
        $smtpPW = Read-Host -AsSecureString 'Enter SMTP login password'
        $pfxPW = Read-Host -AsSecureString 'Enter PFX certificate password'
        ```

1. In PowerShell, initialize additional variables:

    Initialize a variable with the path to your PFX certificate file:

    ```powershell
    $pfxPath = 'C:\path\to\your\certificate.pfx'
    ```

    Initialize a variable with your client workstation's IP address:

    ```powershell
    $clientIP = '192.168.0.1' # Replace with your IP address (hint: search the Web for "what is my ip address")
    # Alternately, you can use the following command to get your IP address:
    # $clientIP = Invoke-RestMethod -Uri 'https://api.ipify.org'
    ```

    If you will use optional arguments, initialize the variables for them now. For example:

    ```powershell
    $resourceGroupName = 'rg-ITSD-ESS-REDCap-Dev-01'
    $resourceGroupInstance = 1
    $mainSiteResourceLocation = 'eastus'
    $storageResourceLocation = 'westus'
    ```

1. Recommended, but optional:

    In PowerShell, initialize the Azure context:

    ```powershell
    Connect-AzAccount
    ```

    Make sure you are using the AzContext you want to use. The context will select the subscription for a tenant, and the assets will be created in that subscription. You can use the `Get-AzContext` command to see the current context, the `Get-AzContext -ListAvailable` command to see all saved contexts, and the `Select-AzContext` command to change it to a different saved context.

    In PowerShell, turn on the Information stream to view the information-level progress of the deployment script:

    ```powershell
    $InformationPreference = 'Continue'
    ```

1. In PowerShell, run the `Deploy-REDCap.ps1` script. Choose one of the following options (simple or advanced):

    * Simple usage:

        * Using only the *required* arguments:

        ```powershell
        .\Deploy-REDCap.ps1 `
            -Cdph_ClientIPAddress $clientIP`
            -Cdph_PfxCertificatePath $pfxPath `
            -Cdph_PfxCertificatePassword $pfxPW `
            -DatabaseForMySql_AdministratorLoginPassword $mySqlPW `
            -ProjectRedcap_CommunityPassword $redCapPW `
            -Smtp_UserPassword $smtpPW
        ```

        * Using *all* of the arguments:

        ```powershell
        .\Deploy-REDCap.ps1 `
            -Arm_ResourceGroupName $resourceGroupName `
            -Arm_MainSiteResourceLocation $mainSiteResourceLocation `
            -Arm_StorageResourceLocation $storageResourceLocation `
            -Cdph_ResourceInstance $resourceGroupInstance `
            -Cdph_ClientIPAddress $clientIP `
            -Cdph_PfxCertificatePath $pfxPath `
            -Cdph_PfxCertificatePassword $pfxPW `
            -DatabaseForMySql_AdministratorLoginPassword $mySqlPW `
            -ProjectRedcap_CommunityPassword $redCapPW `
            -Smtp_UserPassword $smtpPW
        ```

    * Advanced PowerShell users can use splatting (shown with all arguments):

        ```powershell
        $deployArgs = @{
            Arm_ResourceGroupName = 'rg-ITSD-ESS-REDCap-Dev-01'
            Arm_MainSiteResourceLocation = 'eastus'
            Arm_StorageResourceLocation = 'westus'
            Cdph_ResourceInstance = 1
            Cdph_ClientIPAddress = Invoke-RestMethod -Uri 'https://api.ipify.org' # See note above about this parameter
            Cdph_PfxCertificatePath = 'C:\path\to\your\certificate.pfx'
            Cdph_PfxCertificatePassword = Get-Secret -Name 'PfxPW' # Do not use -AsPlainText
            DatabaseForMySql_AdministratorLoginPassword = Get-Secret -Name 'MySqlPW' # Do not use -AsPlainText
            ProjectRedcap_CommunityPassword = Get-Secret -Name 'REDCapPW' # Do not use -AsPlainText
            Smtp_UserPassword = Get-Secret -Name 'SmtpPW' # Do not use -AsPlainText
        }
        .\Deploy-REDCap.ps1 @deployArgs
        ```

    -----

    Note: It might make sense for you to create your own local `deploy.ps1` script that contains the above commands, so that you can just run that script to initialize your environment, at least during your initial testing. For example:
    
    ```powershell
    # deploy.ps1
    if (-not (Test-SecretVault  Mcaps529128 -ErrorAction SilentlyContinue))
    Unlock-SecretVault -Name 'REDCap'
    Select-AzContext -Name 'name of your Az PowerShell context' # Use Get-AzContext -ListAvailable to see the list of contexts
    $deployArgs = @{
        Arm_ResourceGroupName = 'rg-ITSD-ESS-REDCap-Dev-01'
        Arm_MainSiteResourceLocation = 'eastus'
        Arm_StorageResourceLocation = 'westus'
        Cdph_ResourceInstance = 1
        Cdph_PfxCertificatePath = 'C:\path\to\your\certificate.pfx'
        Cdph_PfxCertificatePassword = Get-Secret -Name 'PfxPW' # Do not use -AsPlainText
        Cdph_ClientIPAddress = Invoke-RestMethod -Uri 'https://api.ipify.org' # See note above about this parameter
        DatabaseForMySql_AdministratorLoginPassword = Get-Secret -Name 'MySqlPW' # Do not use -AsPlainText
        ProjectRedcap_CommunityPassword = Get-Secret -Name 'REDCapPW' # Do not use -AsPlainText
        Smtp_UserPassword = Get-Secret -Name 'SmtpPW' # Do not use -AsPlainText
    }
    .\Deploy-REDCap.ps1 @deployArgs
    ```
    
    Then, you can just run `.\deploy.ps1` to deploy the resources. An entry in the `.gitignore` file has already been made for `deploy.ps1`, so you can safely add it to your local workspace.

    -----

    This will deploy the resources to Azure. It may take a while. The first run may take longer than subsequent runs, as the script will download the latest version of the REDCap application and upload it to the storage account. About 20 minutes is a reasonable estimate for the first run, but it could take longer.

    Since the secure values are in variables, you can re-run this as many times as you need to without having to re-enter the passwords.

    The resources will use the CDPH default naming convention, which includes an instance number. By default, that instance number is 1, so all resources will have names that end with `01`. To use a different instance number, add the `-CdphResourceInstance` parameter to the command line, like this:

    ```powershell
    $instance = 2 # Change this to the instance number you want to use

    .\Deploy-REDCap.ps1 `
        -Cdph_PfxCertificatePath $pfxPath `
        -Cdph_PfxCertificatePassword $pfxPW `
        -Cdph_ResourceInstance $instance `
        -Cdph_ClientIPAddress $clientIP `
        -DatabaseForMySql_AdministratorLoginPassword $mySqlPW `
        -ProjectRedcap_CommunityPassword $redCapPW `
        -Smtp_UserPassword $smtpPW
    ```

    ... where `$instance` is a value between 1 and 99, inclusive.


---

## Deploying automatically

_ ToDo: Write this section

*This section will show how to configure both Azure DevOps and GitHub Actions to automatically deploy the resources to Azure.*

---
---

# Going deeper

The script `Deploy-REDCap.ps1` is a wrapper around two scripts: `Deploy-REDCapKeyVault.ps1` and `Deploy-REDCapMain.ps1`. The wrapper script is responsible for prompting for secure and volatile parameters and validating them.

The `Deploy-REDCapKeyVault.ps1` script is responsible for creating the Azure Key Vault and storing some secrets in it. It does this by deploying the `redcapAzureDeployKeyVault.bicep` template.

The `Deploy-REDCapMain.ps1` script is responsible for creating the rest of the resources in Azure. This includes:
* an Azure Database for MySQL Flexible Server
* an Azure Database for MySQL Flexible Server database
* an Azure App Service Plan
* an Azure App Service
* an Azure Storage Account
* Azure Application Insights (optional but recommended)

It does this by deploying the `redcapAzureDeployMain.bicep` template. This template requires the Key Vault to be created first, so it is a dependency of that template.

It is also responsible for configuring Azure App Service Certificate and storing the certificate in the Key Vault.

## Resource naming conventions
The names of the created resources adhere to CDPH naming conventions. The values that compose the segments of the resource names are supplied through parameters which can override the default values in the file `redcapAzureDeploy.parameters.json`.

Assuming that following segment values are used as their default values or as parameters:
| Segment                    | Default value |
| -------                    | ------------- |
| `Cdph_Organization`        | `ITSD`        |
| `Cdph_BusinessUnit`        | `ESS`         |
| `Cdph_BusinessUnitProgram` | `RedCap`      |
| `Cdph_Environment`         | `Dev`         |
| `Cdph_ResourceInstance`    | `1`           |

Then the resources will be named as follows:
| Resource                                 | Name                           |
| --------                                 | ----                           |
| Azure Key Vault                          | `kv-ITSD-ESS-RedCap-Dev-01`    |
| Azure Database for MySQL Flexible Server | `mysql-itsd-ess-redcap-dev-01` |
| Azure Storage Account                    | `stitsdessredcapdev01`         |
| Azure App Service Plan                   | `asp-ITSD-ESS-RedCap-Dev-01`   |
| Azure App Service                        | `app-ITSD-ESS-RedCap-Dev-01`   |
| Azure App Service Certificate            | `cert-ITSD-ESS-RedCap-Dev-01`  |
| Azure Application Insights               | `appi-ITSD-ESS-RedCap-Dev-01`  |
