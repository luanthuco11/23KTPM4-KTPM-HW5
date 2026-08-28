[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Load', 'Stress', 'Spike')]
    [string]$Scenario,

    [string]$ExecutionDate = (Get-Date -Format 'yyyyMMdd'),
    [string]$HostName = 'localhost',
    [ValidateRange(1, 65535)]
    [int]$Port = 3000
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$jmeter = Join-Path $projectRoot '.tools\apache-jmeter-5.6.3\bin\jmeter.bat'
$plan = Join-Path $projectRoot "test-plans\23127414_$($Scenario)_$ExecutionDate.jmx"
$scenarioSlug = $Scenario.ToLowerInvariant()
$resultDirectory = Join-Path $projectRoot "results\$scenarioSlug\$ExecutionDate"
$jtl = Join-Path $resultDirectory "23127414_$($Scenario)_$ExecutionDate.jtl"
$jmeterLog = Join-Path $resultDirectory 'jmeter.log'
$htmlDirectory = Join-Path $resultDirectory 'html-report'
$resourceCsv = Join-Path $resultDirectory 'backend-resource-usage.csv'
$summaryCsv = Join-Path $resultDirectory 'metric-summary.csv'
$pidFile = Join-Path $projectRoot 'runtime\backend.pid'

foreach ($requiredFile in @($jmeter, $plan, $pidFile)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file is missing: $requiredFile"
    }
}

if (Test-Path -LiteralPath $resultDirectory) {
    throw "Result directory already exists. Refusing to overwrite official evidence: $resultDirectory"
}

$health = Invoke-WebRequest -Uri "http://$HostName`:$Port/api/products" -TimeoutSec 5
if ($health.StatusCode -ne 200) {
    throw "SUT health check failed with HTTP $($health.StatusCode)."
}

$backendPid = [int](Get-Content -LiteralPath $pidFile -Raw)
$backendProcess = Get-Process -Id $backendPid -ErrorAction Stop
if ($backendProcess.ProcessName -ne 'node') {
    throw "Recorded backend PID $backendPid is not Node.js."
}

New-Item -ItemType Directory -Path $resultDirectory | Out-Null

$monitorJob = Start-Job -ArgumentList $backendPid -ScriptBlock {
    param($MonitoredPid)
    while ($true) {
        $sample = Get-Process -Id $MonitoredPid -ErrorAction SilentlyContinue
        if ($null -eq $sample) {
            break
        }
        [PSCustomObject]@{
            Timestamp       = (Get-Date).ToString('o')
            WorkingSetMB    = [math]::Round($sample.WorkingSet64 / 1MB, 3)
            PrivateMemoryMB = [math]::Round($sample.PrivateMemorySize64 / 1MB, 3)
            CpuSeconds      = [math]::Round($sample.CPU, 3)
            Threads         = $sample.Threads.Count
            Handles         = $sample.HandleCount
        }
        Start-Sleep -Seconds 1
    }
}

try {
    Write-Host "Starting official $Scenario scenario."
    Write-Host 'Keep Task Manager visible beside this terminal and capture the required screenshot/video evidence now.'
    & $jmeter -n -t $plan "-Jhost=$HostName" "-Jport=$Port" -l $jtl -j $jmeterLog -e -o $htmlDirectory
    if ($LASTEXITCODE -ne 0) {
        throw "JMeter exited with code $LASTEXITCODE."
    }
} finally {
    Stop-Job -Job $monitorJob -ErrorAction SilentlyContinue
    $resourceSamples = @(Receive-Job -Job $monitorJob -ErrorAction SilentlyContinue)
    Remove-Job -Job $monitorJob -Force -ErrorAction SilentlyContinue
    if ($resourceSamples.Count -gt 0) {
        $resourceSamples | Select-Object Timestamp, WorkingSetMB, PrivateMemoryMB, CpuSeconds, Threads, Handles |
            Export-Csv -LiteralPath $resourceCsv -NoTypeInformation -Encoding utf8
    }
}

& (Join-Path $PSScriptRoot 'Analyze-Jtl.ps1') -JtlPath $jtl -OutputCsv $summaryCsv
Write-Host "Official $Scenario artifacts created in $resultDirectory"

