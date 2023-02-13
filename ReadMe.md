# REDCap Deployment

## Deploying manually

1. Preconditions

    1. Install PowerShell 7.1 or later

    1. Install Azure PowerShell modules (2.11 was tested)

    1. Connect to Azure using Az PowerShell:

        `Connect-AzAccount`

    1. Select correct Azure subscription using Az PowerShell:

        `Select-AzContext -Subscription <`*subscription name or id*`>`

1. Clone this git repository locally

1. In PowerShell, run

    `.\startDeploy.ps1`

    This will deploy the resources to Azure. It may take a while.

    The resources will use the default naming convention, which includes an instance number. By default, that instance number is 1, so all resources will have names that end with `01`. To use a different instance number, run

    `.\startDeploy.ps1 -CdphResourceInstance <`*instance number*`>`

    where *instance number* is a value between 1 and 99, inclusive.

## Deploying automatically

ToDo