#requires -Modules Az.Resources

param (
    # Parameter help description
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,

    # Parameter help description
    [Parameter()]
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
    $Arm_ResourceLocation = 'westus2',
    
    [Parameter(Mandatory = $true)]
    [securestring]
    $DatabaseForMySql_AdministratorLoginPassword,

    # Parameter help descriptions
    [Parameter(Mandatory = $true)]
    [securestring]
    $ProjectRedcap_CommunityPassword,

    # Parameter help description
    [Parameter(Mandatory = $true)]
    [securestring]
    $Smtp_UserPassword
)

$startTime = Get-Date
"Beginning deployment at $starttime"

#DEPLOYMENT OPTIONS
#Please review the azuredeploy.json file for available options
# $RGName        = "<YOUR RESOURCE GROUP>"
# $DeployRegion  = "<SELECT AZURE REGION>"
# $AssetLocation = "https://github.com/vanderbilt-redcap/redcap-azure/blob/master/azuredeploy.json"

<# 
$parms = @{

    #Alternative to the zip file above, you can use REDCap Community credentials to download the zip file.
    "redcapCommunityUsername"     = "<REDCap Community site username>";
    "redcapCommunityPassword"     = "<REDCap Community site password>";
    "redcapAppZipVersion"         = "<REDCap version";

    #Mail settings
    "fromEmailAddress"            = "<email address listed as sender for outbound emails>";
    "smtpFQDN"                    = "<what it says>"
    "smtpUser"                    = "<login name for smtp auth>"
    "smtpPassword"                = "<password for smtp auth>"

    #Azure Web App
    "siteName"                    = "<WEB SITE NAME, like 'redcap'>";
    "skuName"                     = "S1";
    "skuCapacity"                 = 1;

    #MySQL
    "administratorLogin"          = "<MySQL admin account name>";
    "administratorLoginPassword"  = "<MySQL admin login password>";

    "databaseForMySqlCores"       = 2;
    "databaseForMySqlFamily"      = "Gen5";
    "databaseSkuSizeMB"           = 5120;
    "databaseForMySqlTier"        = "GeneralPurpose";
    "mysqlVersion"                = "5.7";
    
    #Azure Storage
    "storageType"                 = "Standard_LRS";
    "storageContainerName"        = "redcap";

    #GitHub
    "repoURL"                     = "https://github.com/vanderbilt-redcap/redcap-azure.git";
    "branch"                      = "master";
}
 #>
#END DEPLOYMENT OPTIONS

#Dot-sourced variable override (optional, comment out if not using)
<# 
$dotsourceSettings = "$($env:PSH_Settings_Files)redcap-azure.ps1"
if (Test-Path $dotsourceSettings) {
    . $dotsourceSettings
}
 #>

#ensure we're logged in
Get-AzContext -ErrorAction Stop

#deploy
# $TemplateFile = "$($AssetLocation)?x=$version"
$bicepPath = 'redcapAzureDeploy.bicep'

try
{
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    "Resource group $ResourceGroupName exists, updating deployment"
}
catch
{
    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Arm_ResourceLocation
    "Created new resource group $ResourceGroupName."
}
$version = (Get-Date).ToShortDateString()
# $deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -TemplateParameterObject $parms -TemplateFile $TemplateFile -Name "RedCAPDeploy$version"  -Force -Verbose
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $bicepPath -Name "RedCAPDeploy$version" -TemplateParameter @{"administratorLoginPassword"=$DatabaseForMySql_AdministratorLoginPassword; "communityPassword"=$ProjectRedcap_CommunityPassword; "smtpUserPassword"=$Smtp_UserPassword} -Force -Verbose

if ($deployment.ProvisioningState -eq "Succeeded")
{
    $siteName = $deployment.Outputs.webSiteFQDN.Value
    start "https://$($siteName)/AzDeployStatus.php"
    Write-Host "---------"
    $deployment.Outputs | ConvertTo-Json

}
else
{
    $deperr = Get-AzureRmResourceGroupDeploymentOperation -DeploymentName "RedCAPDeploy$version" -ResourceGroupName $RGName
    $deperr | ConvertTo-Json
}

$endTime = Get-Date

Write-Host ""
Write-Host "Total Deployment time:"
New-TimeSpan -Start $startTime -End $endTime | Select Hours, Minutes, Seconds
