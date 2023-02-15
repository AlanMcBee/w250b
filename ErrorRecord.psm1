<#
// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************
 #>

using namespace System.Management.Automation

Set-StrictMode -Version Latest

function Write-CaughtErrorRecord
{
    [CmdletBinding()]
    param (
        # ErrorRecord object
        [Parameter(Mandatory = $true, Position = 0)]
        [ErrorRecord]
        $CaughtError,

        # Error Level
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Warning', 'Error', 'Info')]
        [string]
        $ErrorLevel = 'Error',

        # Message
        [Parameter(Mandatory = $false, Position = 2)]
        [string]
        $Message,

        # Include StackTrace
        [Parameter(Mandatory = $false, Position = 3)]
        [switch]
        $IncludeStackTrace
    )

    if ($IncludeStackTrace)
    {
        $stackTrace = "`n`t" + $CaughtError.ScriptStackTrace -replace "`n", "`n`u{259F}`t"
    }
    else
    {
        $stackTrace = [string]::Empty
    }
    if ($PSBoundParameters.ContainsKey('Message'))
    {
        $errorLine = "$Message`:`n`t$($CaughtError.ErrorDetails)`n`t$($CaughtError.Exception)$stackTrace"
    }
    else
    {
        $errorLine = "$($CaughtError.ErrorDetails)`n`t$($CaughtError.Exception)$stackTrace"
    }

    switch ($ErrorLevel)
    {
        'Warning'
        {
            Write-Warning -Message $errorLine
        }
        'Error'
        {
            Write-Debug 'writing error'
            if ($null -eq $CaughtError.ErrorDetails)
            {
                Write-Debug 'error, no recommended action'
                if ($stackTrace.Length -gt 0)
                {
                    Write-Verbose $stackTrace
                }
                Write-Error `
                    -Exception $CaughtError.Exception `
                    -Message $errorLine `
                    -Category $CaughtError.CategoryInfo.Category `
                    -ErrorId $CaughtError.FullyQualifiedErrorId `
                    -TargetObject $CaughtError.TargetObject `
                    -CategoryActivity $CaughtError.CategoryInfo.Activity `
                    -CategoryReason $CaughtError.CategoryInfo.Reason `
                    -CategoryTargetName $CaughtError.CategoryInfo.TargetName `
                    -CategoryTargetType $CaughtError.CategoryInfo.TargetType
            }
            else
            {
                Write-Debug 'error, recommended action'
                if ($stackTrace.Length -gt 0)
                {
                    Write-Verbose $stackTrace
                }
                Write-Error `
                    -RecommendedAction $CaughtError.ErrorDetails.RecommendedAction `
                    -Exception $CaughtError.Exception `
                    -Message $errorLine `
                    -Category $CaughtError.CategoryInfo.Category `
                    -ErrorId $CaughtError.FullyQualifiedErrorId `
                    -TargetObject $CaughtError.TargetObject `
                    -CategoryActivity $CaughtError.CategoryInfo.Activity `
                    -CategoryReason $CaughtError.CategoryInfo.Reason `
                    -CategoryTargetName $CaughtError.CategoryInfo.TargetName `
                    -CategoryTargetType $CaughtError.CategoryInfo.TargetType

            }
        }
        'Info'
        {
            Write-Information -MessageData $errorLine
        }
        Default {}
    }
}
Export-ModuleMember -Function Write-CaughtErrorRecord
