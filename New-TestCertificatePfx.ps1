param (
    [Parameter(Mandatory = $true)]
    [securestring]
    $Cdph_PfxCertificatePassword,

    [Parameter(Mandatory = $true)]
    [string]
    $Cdph_PfxCertificatePath
)
    
Set-StrictMode -Version Latest

$cert = New-SelfSignedCertificate `
    -DnsName 'overthinker.blog' `
    -CertStoreLocation 'cert:\LocalMachine\My'

$cert | Export-PfxCertificate -FilePath $Cdph_PfxCertificatePath -Password $Cdph_PfxCertificatePassword
