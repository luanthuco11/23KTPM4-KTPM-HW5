[CmdletBinding()]
param(
    [string]$SutRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'eshop-sut'),
    [ValidateRange(1, 65535)]
    [int]$Port = 3000
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$backendDirectory = Join-Path $SutRoot 'backend'
$serverScript = Join-Path $backendDirectory 'server.js'
if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
    throw "SUT backend not found: $serverScript"
}

$runtimeDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'runtime'
New-Item -ItemType Directory -Force -Path $runtimeDirectory | Out-Null
$pidFile = Join-Path $runtimeDirectory 'backend.pid'
$stdoutFile = Join-Path $runtimeDirectory 'backend.stdout.log'
$stderrFile = Join-Path $runtimeDirectory 'backend.stderr.log'

if (Test-Path -LiteralPath $pidFile) {
    $existingPid = [int](Get-Content -LiteralPath $pidFile -Raw)
    if (Get-Process -Id $existingPid -ErrorAction SilentlyContinue) {
        throw "A recorded backend process is already running with PID $existingPid. Run Stop-Sut.ps1 first."
    }
}

$process = Start-Process `
    -FilePath 'node.exe' `
    -ArgumentList 'server.js' `
    -WorkingDirectory $backendDirectory `
    -RedirectStandardOutput $stdoutFile `
    -RedirectStandardError $stderrFile `
    -WindowStyle Hidden `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ascii

$ready = $false
for ($attempt = 1; $attempt -le 30; $attempt++) {
    if ($process.HasExited) {
        break
    }

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port/api/products" -TimeoutSec 2 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        Start-Sleep -Milliseconds 500
    }
}

if (-not $ready) {
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
    }
    throw "Backend did not become ready. Inspect $stdoutFile and $stderrFile."
}

Write-Host "SUT backend ready at http://localhost:$Port (PID $($process.Id))."
Write-Host 'The SQLite database has been recreated from the lecturer seed.'
