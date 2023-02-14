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
        Register-SecretVault -Name Azure -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
        ```

    1. Add passwords required by the script to the vault. The names here are examples only:

        ```powershell
        Set-Secret -Name 'MySqlPW' -Secret (Read-Host -AsSecureString 'Enter REDCap MySQL database administrator password')
        Set-Secret -Name 'REDCapPW' -Secret (Read-Host -AsSecureString 'Enter REDCap community user password')
        Set-Secret -Name 'SmtpPW' -Secret (Read-Host -AsSecureString 'Enter SMTP login password')
        Set-Secret -Name 'PfxPW' -Secret (Read-Host -AsSecureString 'Enter PFX certificate password')
        ```

1. If you plan to override any of the default values in `redcapAzureDeploy.parameters.json`, make your changes to that file now. Some values you may want to change:

| Parameter                                                   | Default value       | Effective value                          |
| ---------                                                   | -------------       | ---------------                          |
| Cdph_Organization                                           | `ITSD`              | `ITSD`                                   |
| Cdph_BusinessUnit                                           | `ESS`               | `ESS`                                    |
| Cdph_BusinessUnitProgram                                    | `RedCap`            | `RedCap`                                 |
| Cdph_Environment                                            | `Dev`               | `Dev`                                    |
| Cdph_ResourceInstance                                       | `1`                 | `01`                                     |
| Cdph_SslCertificateThumbprint                               | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| 
| Arm_MainSiteResourceLocation                                | `eastus`            | `eastus`                                 |
| Arm_StorageResourceLocation                                 | `westus`            | `westus`                                 |
| Arm_DeploymentCreationDateTime                              | *(empty)*           | Current UTC date/time                    |
| 
| AppServicePlan_SkuName                                      | `S1`                | `S1`                                     |
| AppServicePlan_Capacity                                     | `1`                 | `1` instance                             |
| 
| AppService_LinuxFxVersion                                   | `php\               |8.2`                                      | `php\|8.2` |
| AppService_WebApp_Subdomain                                 | *(empty)*           | `redcap-dev-01.cdph.ca.gov`              |
| AppService_WebApp_CustomDomainDnsTxtRecordVerificationValue | *(empty)*           | A random value (shared in output)        |
| AppService_WebHost_SourceControl_GitHubRepositoryUri        | *(empty)*           | `https://github.com/AlanMcBee/w250b.git` |
| 
| DatabaseForMySql_Tier                                       | `GeneralPurpose`    | `GeneralPurpose`                         |
| DatabaseForMySql_Sku                                        | `Standard_D4ads_v5` | `Standard_D4ads_v5`                      |
| DatabaseForMySql_ServerName                                 | *(empty)*           | `REDCap-Dev-01.mysql.database.azure.com` |
| DatabaseForMySql_AdministratorLoginName                     | `redcap_app`        | `redcap_app`                             |
| <del>*DatabaseForMySql_AdministratorLoginPassword*</del>    |                     | *DO NOT SET IN THIS FILE*                |
| DatabaseForMySql_StorageGB                                  | `20`                | `20` GiB                                 |
| DatabaseForMySql_BackupRetentionDays                        | `7`                 | `7` days                                 |
| DatabaseForMySql_DbName                                     | `redcap`            | `redcap_db`                              |
| 
| StorageAccount_Redundancy                                   | `Standard_LRS`      | `Standard_LRS`                           |
| 
| ProjectRedcap_CommunityUsername                             | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| <del>*ProjectRedcap_CommunityPassword*</del>                |                     | *DO NOT SET IN THIS FILE*                |
| ProjectRedcap_DownloadAppZipUri                             | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| ProjectRedcap_DownloadAppZipVersion                         | `latest`            | `latest`                                 |
| 
| Smtp_FQDN                                                   | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| Smtp_Port                                                   | `587`               | `587`                                    |
| Smtp_UserLogin                                              | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
| <del>*Smtp_UserPassword*</del>                              |                     | *DO NOT SET IN THIS FILE*                |
| Smtp_FromEmailAddress                                       | *(empty)*           | *OVERRIDE IS REQUIRED*                   |
|
| Monitor_ApplicationInsights                                 | `true`              | `true`                                   |

For any parameters that are marked as *OVERRIDE IS REQUIRED*, you must provide a value, either by saving it in the `redcapAzureDeploy.parameters.json` file or by passing it in on the command line (which can include modifying the `redcapAzureDeployKeyVault.ps1` or `redcapAzureDeployMain.ps1` files).
Note that no passwords should be saved in the `redcapAzureDeploy.parameters.json` file. Instead, use the PowerShell SecretStore module to store them in the vault, or else provide them from the command line.
See the []

Consult the files `redcapAzureDeployMain.bicep` and `redcapAzureDeployKeyVault.bicep` for more information about the parameters.

--------------------------------------------------------------------------------

## Invoking the deployment script

1. In PowerShell, initialize the secure password variables (if you chose to use the PowerShell SecretStore module recommended earlier):

    ```powershell
    $mySqlPW = Get-Secret -Name 'MySqlPW' # Do not use -AsPlainText
    $redCapPW = Get-Secret -Name 'REDCapPW' # Do not use -AsPlainText
    $smtpPW = Get-Secret -Name 'SmtpPW' # Do not use -AsPlainText
    $pfxPW = Get-Secret -Name 'PfxPW' # Do not use -AsPlainText
    ```

1. In PowerShell, run the `startDeploy.ps1` script:

    ```powershell
    .\startDeploy.ps1 `
        -MySqlAdminPassword $mySqlPW `
        -RedCapCommunityPassword $redCapPW `
        -SmtpPassword $smtpPW `
        -PfxCertificatePassword $pfxPW
    ```

    This will deploy the resources to Azure. It may take a while. The first run may take longer than subsequent runs, as the script will download the latest version of the REDCap application and upload it to the storage account. About 20 minutes is a reasonable estimate for the first run, but it could take longer.

    Since the secure values are in variables, you can re-run this as many times as you need to without having to re-enter the passwords.

    The resources will use the CDPH default naming convention, which includes an instance number. By default, that instance number is 1, so all resources will have names that end with `01`. To use a different instance number, add the `-CdphResourceInstance` parameter to the command line, like this:

    ```powershell
    $instance = 2 # Change this to the instance number you want to use
    .\startDeploy.ps1 `
        -MySqlAdminPassword $mySqlPW `
        -RedCapCommunityPassword $redCapPW `
        -SmtpPassword $smtpPW `
        -PfxCertificatePassword $pfxPW `
        -CdphResourceInstance $instance 
    ```

    ... where `$instance` is a value between 1 and 99, inclusive.

---

## Deploying automatically

_ ToDo: Write this section

*This section will show how to configure both Azure DevOps and GitHub Actions to automatically deploy the resources to Azure.*

---
---

# Going deeper

The script `startDeploy.ps1` is a wrapper around two scripts: `redcapAzureDeployKeyVault.ps1` and `redcapAzureDeployMain.ps1`. The wrapper script is responsible for prompting for secure and very volatile parameters and validating them.

The `redcapAzureDeployKeyVault.ps1` script is responsible for creating the Azure Key Vault and storing some secrets in it. It does this by deploying the `redcapAzureDeployKeyVault.bicep` template.

The `redcapAzureDeployMain.ps1` script is responsible for creating the rest of the resources in Azure. This includes:
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
