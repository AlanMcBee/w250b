$proxyAddress = "http://127.0.0.1:9000"
$proxyUri = [System.Uri]::new($proxyAddress)

[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebProxy]::new($proxyUri, $true)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
