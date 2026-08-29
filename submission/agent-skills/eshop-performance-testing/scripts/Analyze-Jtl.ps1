[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$JtlPath,

    [string]$OutputCsv,

    [string]$ParentLabel = 'E2E Purchase Workflow',

    [ValidateRange(1, 1000)]
    [int]$ExpectedChildSamples = 7
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedJtl = (Resolve-Path -LiteralPath $JtlPath).Path
$rows = @(Import-Csv -LiteralPath $resolvedJtl)
if ($rows.Count -eq 0) {
    throw "JTL contains no samples: $resolvedJtl"
}

$requiredColumns = @('timeStamp', 'elapsed', 'label', 'success', 'responseMessage')
foreach ($column in $requiredColumns) {
    if ($rows[0].PSObject.Properties.Name -notcontains $column) {
        throw "JTL is missing required column: $column"
    }
}

function Get-Percentile {
    param(
        [long[]]$Values,
        [ValidateRange(0.0, 1.0)]
        [double]$Percentile
    )

    if ($Values.Count -eq 0) {
        return 0
    }

    [array]::Sort($Values)
    $index = [math]::Max(0, [math]::Ceiling($Percentile * $Values.Count) - 1)
    return $Values[$index]
}

$escapedChildCount = [regex]::Escape($ExpectedChildSamples.ToString())
$completeParentPattern = "Number of samples in transaction\s*:\s*$escapedChildCount(?:\D|$)"

$summary = foreach ($group in ($rows | Group-Object label | Sort-Object Name)) {
    $rawSamples = @($group.Group)
    if ($group.Name -eq $ParentLabel) {
        $analysisSamples = @($rawSamples | Where-Object { $_.responseMessage -match $completeParentPattern })
    } else {
        $analysisSamples = $rawSamples
    }

    if ($analysisSamples.Count -eq 0) {
        continue
    }

    [long[]]$elapsedValues = @($analysisSamples | ForEach-Object { [long]$_.elapsed })
    $start = ($analysisSamples | Measure-Object -Property timeStamp -Minimum).Minimum
    $end = ($analysisSamples | ForEach-Object { [long]$_.timeStamp + [long]$_.elapsed } | Measure-Object -Maximum).Maximum
    $wallSeconds = [math]::Max(0.001, ([double]$end - [double]$start) / 1000.0)
    $failures = @($analysisSamples | Where-Object { $_.success -ne 'true' }).Count

    [PSCustomObject]@{
        Label         = $group.Name
        RawSamples    = $rawSamples.Count
        Samples       = $analysisSamples.Count
        Interrupted   = $rawSamples.Count - $analysisSamples.Count
        Failures      = $failures
        ErrorRatePct  = [math]::Round(($failures * 100.0) / $analysisSamples.Count, 3)
        AverageMs     = [math]::Round(($elapsedValues | Measure-Object -Average).Average, 2)
        MinMs         = ($elapsedValues | Measure-Object -Minimum).Minimum
        P50Ms         = Get-Percentile -Values $elapsedValues.Clone() -Percentile 0.50
        P90Ms         = Get-Percentile -Values $elapsedValues.Clone() -Percentile 0.90
        P95Ms         = Get-Percentile -Values $elapsedValues.Clone() -Percentile 0.95
        P99Ms         = Get-Percentile -Values $elapsedValues.Clone() -Percentile 0.99
        MaxMs         = ($elapsedValues | Measure-Object -Maximum).Maximum
        ThroughputRps = [math]::Round($analysisSamples.Count / $wallSeconds, 3)
    }
}

$summary | Format-Table -AutoSize

if ($OutputCsv) {
    if (Test-Path -LiteralPath $OutputCsv) {
        throw "Refusing to overwrite existing analysis output: $OutputCsv"
    }
    $outputDirectory = Split-Path -Parent $OutputCsv
    if ($outputDirectory) {
        New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    }
    $summary | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding utf8
    Write-Host "Summary written to $OutputCsv"
}
