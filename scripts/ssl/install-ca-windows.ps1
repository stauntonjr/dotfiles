# Install certificate chain on Windows (requires admin for LocalMachine stores)
[CmdletBinding()]
param(
    [string]$ChainPath = "$env:USERPROFILE\dotfiles\ssl\ca.crt",
    [switch]$CurrentUser
)

Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ChainPath)) {
    Write-Error "Certificate chain file not found at $ChainPath."
    exit 1
}

$pemContent = Get-Content -LiteralPath $ChainPath -Raw
$pattern = '-----BEGIN CERTIFICATE-----(?<body>.*?)-----END CERTIFICATE-----'
$matches = [System.Text.RegularExpressions.Regex]::Matches(
    $pemContent,
    $pattern,
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

if ($matches.Count -eq 0) {
    Write-Error "No certificates were found in $ChainPath."
    exit 1
}

$storeLocation = if ($CurrentUser) {
    [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
} else {
    [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
}

$stores = @{}
$imported = @()

foreach ($match in $matches) {
    $body = $match.Groups['body'].Value -replace '\s', ''
    if (-not $body) {
        continue
    }

    $bytes = [Convert]::FromBase64String($body)
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($bytes)
    $isRoot = $cert.Subject -eq $cert.Issuer
    $storeName = if ($isRoot) { 'Root' } else { 'CA' }

    if (-not $stores.ContainsKey($storeName)) {
        $store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
            $storeName,
            $storeLocation
        )
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $stores[$storeName] = $store
    }

    $store = $stores[$storeName]
    $alreadyPresent = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    if ($alreadyPresent) {
        Write-Host "Skipping existing certificate: $($cert.Subject) ($($cert.Thumbprint)) in $storeName store."
        continue
    }

    $store.Add($cert)
    $imported += "$($cert.Subject) -> $storeName"
    Write-Host "Imported $($cert.Subject) into $storeName store."
}

foreach ($store in $stores.Values) {
    $store.Close()
    $store.Dispose()
}

if ($imported.Count -eq 0) {
    Write-Host "No new certificates were imported."
} else {
    Write-Host "Imported certificates:"
    foreach ($entry in $imported) {
        Write-Host " - $entry"
    }

    if ($storeLocation -eq [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine) {
        Write-Host "Restart applications to ensure they pick up the new trust chain."
    }
}
