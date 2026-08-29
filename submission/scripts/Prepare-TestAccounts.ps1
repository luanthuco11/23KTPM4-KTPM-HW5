[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://localhost:3000'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$dataDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'data'
$csvFiles = @(
    'users-load.csv',
    'users-stress.csv',
    'users-spike-baseline.csv',
    'users-spike-burst.csv'
)

$accounts = foreach ($fileName in $csvFiles) {
    $path = Join-Path $dataDirectory $fileName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing CSV file: $path. Run New-TestData.ps1 first."
    }
    Import-Csv -LiteralPath $path
}

$uniqueAccounts = $accounts | Sort-Object email -Unique
$registered = 0

foreach ($account in $uniqueAccounts) {
    $body = @{
        name     = $account.name
        email    = $account.email
        password = $account.password
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Method Post `
        -Uri "$BaseUrl/api/register" `
        -ContentType 'application/json' `
        -Body $body

    if (-not $response.id) {
        throw "Registration did not return an ID for $($account.email)."
    }
    $registered++
}

Write-Host "Registered $registered unique performance-test accounts."
Write-Host 'Account preparation is complete. Do not run this script twice without restarting the SUT.'

