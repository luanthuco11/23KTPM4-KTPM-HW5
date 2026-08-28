[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$dataDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'data'
New-Item -ItemType Directory -Force -Path $dataDirectory | Out-Null

$searchTerms = @('iPhone', 'Samsung', 'MacBook', 'AirPods', 'Keychron')

function Write-ScenarioCsv {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateRange(1, 1000)]
        [int]$Count
    )

    $rows = for ($index = 1; $index -le $Count; $index++) {
        $suffix = $index.ToString('000')
        [PSCustomObject]@{
            name            = "HW5 $Name User $suffix"
            email           = "$($Name.ToLowerInvariant())$suffix@perf.local"
            password        = 'PerfTest123!'
            searchTerm      = $searchTerms[($index - 1) % $searchTerms.Count]
            quantity        = (($index - 1) % 2) + 1
            shippingAddress = "HW5 $Name address $suffix, Ho Chi Minh City"
        }
    }

    $path = Join-Path $dataDirectory "users-$($Name.ToLowerInvariant()).csv"
    $rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding utf8
    Write-Host "Generated $Count rows: $path"
}

Write-ScenarioCsv -Name 'Load' -Count 40
Write-ScenarioCsv -Name 'Stress' -Count 250
Write-ScenarioCsv -Name 'Spike-Baseline' -Count 20
Write-ScenarioCsv -Name 'Spike-Burst' -Count 150

