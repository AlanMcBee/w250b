<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
Deploy-REDCapMain.ps1
 #>
#requires -Modules Az.Resources
#requires -Version 7.1

param (
    # Optional Azure resource group name. If not specified, a default name will be used based on the parameters.json file and the instance number.
    [Parameter()]
    [string]
    $Arm_ResourceGroupName,

    # Azure region for the main site. 
    # Basic options: eastus, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, eastus2
    # Full list of regions can be found here: https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies
    # Not all resources are available in all regions.
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'centralus',
        'eastus',
        'eastus2',
        'northcentralus',
        'southcentralus',
        'westcentralus',
        'westus',
        'westus2',
        'westus3'
    )]
    [string]
    $Arm_MainSiteResourceLocation,

    # Azure region for the storage account. 
    # Basic options: eastus, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, eastus2
    # Full list of regions can be found here: https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies
    # Not all resources are available in all regions.
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'centralus',
        'eastus',
        'eastus2',
        'northcentralus',
        'southcentralus',
        'westcentralus',
        'westus',
        'westus2',
        'westus3'
    )]
    [string]
    $Arm_StorageResourceLocation,

    # Optional CDPH resource instance number to allow multiple deployments to the same subscription. If not specified, the default value of 1 will be used.
    [Parameter()]
    [int]
    $Cdph_ResourceInstance = 1,

    # Password for MySQL administrator account
    # Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $DatabaseForMySql_AdministratorLoginPassword,

    # Password for the REDCap Community site account
    # Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $ProjectRedcap_CommunityPassword,

    # Password for the SMTP server account
    # Recommended: Use Get-Secret to retrieve the password from a secure store.
    [Parameter(Mandatory = $true)]
    [securestring]
    $Smtp_UserPassword
)

Import-Module .\ErrorRecord.psm1

$measured = Measure-Command {
    & {
        Write-Information "Beginning deployment at $((Get-Date).ToString())"

        $requiredParameters = @(
            'Cdph_Organization',
            'Cdph_BusinessUnit',
            'Cdph_BusinessUnitProgram',
            'Cdph_SslCertificateThumbprint',
            'AppService_WebHost_SourceControl_GitHubRepositoryUri',
            'ProjectRedcap_CommunityUsername',
            'ProjectRedcap_DownloadAppZipUri',
            'Smtp_FQDN',
            'Smtp_UserLogin',
            'Smtp_FromEmailAddress'
        )
        $deployParametersPath = 'redcapAzureDeployMain.parameters.json'
        $deployParameters = Get-Content $deployParametersPath | ConvertFrom-Json -Depth 8 -AsHashtable
        if ($null -eq $deployParameters)
        {
            Write-Error "Unable to load deployment parameters from $deployParametersPath"
        }
        if (-not $deployParameters.ContainsKey('parameters'))
        {
            Write-Error "Deployment parameters from $deployParametersPath do not contain a 'parameters' property"
        }
        $parametersEntry = $deployParameters.parameters
        foreach ($requiredParameter in $requiredParameters)
        {
            if (-not $parametersEntry.ContainsKey($requiredParameter))
            {
                Write-Error "Deployment parameters from $deployParametersPath do not contain a required '$requiredParameter' property"
            }
            if (0 -eq $parametersEntry[$requiredParameter].value.Length)
            {
                Write-Error "Deployment parameters from $deployParametersPath do not contain a required value for the '$requiredParameter' property"
            }
        }

        # Create hashtable from parametersEntry moving the value sub-property to the top level
        $flattenedParameters = @{}
        foreach ($parameterName in $parametersEntry.Keys)
        {
            $flattenedParameters[$parameterName] = $parametersEntry[$parameterName].value
        }

        # Override parameters with values from the command line
        if ($PSBoundParameters.ContainsKey('Cdph_ResourceInstance'))
        {
            $flattenedParameters['Cdph_ResourceInstance'] = $Cdph_ResourceInstance
        }
        if ($PSBoundParameters.ContainsKey('Arm_MainSiteResourceLocation'))
        {
            $flattenedParameters['Arm_MainSiteResourceLocation'] = $Arm_MainSiteResourceLocation
        }
        if ($PSBoundParameters.ContainsKey('Arm_StorageResourceLocation'))
        {
            $flattenedParameters['Arm_StorageResourceLocation'] = $Arm_StorageResourceLocation
        }

        # Merge parameters
        $templateParameters = $flattenedParameters + @{
            DatabaseForMySql_AdministratorLoginPassword = $DatabaseForMySql_AdministratorLoginPassword
            ProjectRedcap_CommunityPassword             = $ProjectRedcap_CommunityPassword
            Smtp_UserPassword                           = $Smtp_UserPassword
        }
        $organization = $templateParameters['Cdph_Organization']
        $businessUnit = $templateParameters['Cdph_BusinessUnit']
        $program = $templateParameters['Cdph_BusinessUnitProgram']
        $environment = $templateParameters['Cdph_Environment']
        $instance = $templateParameters['Cdph_ResourceInstance'].ToString().PadLeft(2, '0')

        if (($PSBoundParameters.ContainsKey('Arm_ResourceGroupName')) -and (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['Arm_ResourceGroupName'])))
        {
            $resourceGroupName = $Arm_ResourceGroupName
        }
        else
        {
            $resourceGroupName = "rg-$organization-$businessUnit-$program-$environment-$instance"
        }
        Write-Information "Using resource group name $resourceGroupName"

        # Make sure we're logged in. Use Connect-AzAccount if not.
        Get-AzContext -ErrorAction Stop

        # Start deployment
        $bicepPath = 'redcapAzureDeployMain.bicep'

        try
        {
            Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Stop
            Write-Information "Resource group $resourceGroupName exists. Updating deployment"
        }
        catch
        {
            $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $Arm_MainSiteResourceLocation
            Write-Information "Created new resource group $resourceGroupName."
        }

        $version = (Get-Date).ToString('yyyyMMddHHmmss')
        $deploymentName = "REDCapDeployMain.$version"
        $deployArgs = @{
            ResourceGroupName       = $resourceGroupName
            TemplateFile            = $bicepPath
            Name                    = $deploymentName
            TemplateParameterObject = $templateParameters
        }
        # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroupDeployment]
        $armDeployment = $null
        try
        {
            $armDeployment = New-AzResourceGroupDeployment @deployArgs -Force -Verbose -DeploymentDebugLogLevel ResponseContent | Select-Object -First 1
            if ($null -eq $armDeployment)
            {
                Write-Error 'New-AzResourceGroupDeployment returned $null'
            }
            else
            {
                Write-Information "Provisioning State = $($armDeployment.ProvisioningState)"
            }
        }
        catch
        {
            Write-CaughtErrorRecord $_ Error -IncludeStackTrace
        }

        while (($null -ne $armDeployment) -and ($armDeployment.ProvisioningState -eq 'Running'))
        {
            Write-Information "State = $($armDeployment.ProvisioningState); Check again at $([datetime]::Now.AddSeconds(5).ToLongTimeString())"
            Start-Sleep 5
        }

        if ($null -ne $armDeployment && $armDeployment.ProvisioningState -eq 'Succeeded')
        {
            $armDeployment.Outputs | ConvertTo-Json -Depth 8
            try
            {
                $siteName = $armDeployment.Outputs['out_WebSiteFQDN'].Value
                Start-Process "https://$($siteName)/AzDeployStatus.php"
            }
            catch
            {
                Write-Information 'Unable to open AzDeployStatus.php in browser.'
            }
        }
        else
        {
            # [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSDeploymentOperation]
            $deploymentErrors = $null
            try
            {
                $deploymentErrors = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
                $deploymentErrors | ConvertTo-Json -Depth 8
            }
            catch
            {
                Write-CaughtErrorRecord $_ Error -IncludeStackTrace
            }
        }

    } | Out-Default
}
Write-Information "Total Deployment time: $($measured.ToString())"
