[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$runtimeDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'runtime'
$pidFile = Join-Path $runtimeDirectory 'backend.pid'
if (-not (Test-Path -LiteralPath $pidFile -PathType Leaf)) {
    Write-Host 'No recorded SUT backend process exists.'
    exit 0
}

$backendPid = [int](Get-Content -LiteralPath $pidFile -Raw)
$process = Get-Process -Id $backendPid -ErrorAction SilentlyContinue
if ($null -eq $process) {
    Remove-Item -LiteralPath $pidFile -Force
    Write-Host "Recorded process $backendPid is no longer running. Removed stale PID file."
    exit 0
}

if ($process.ProcessName -ne 'node') {
    throw "Refusing to stop PID $backendPid because it is $($process.Name), not Node.js."
}

$resolvedNodePath = (Resolve-Path -LiteralPath $process.Path).Path
$expectedNodePath = (Resolve-Path -LiteralPath (Get-Command node.exe -ErrorAction Stop).Source).Path
if ($resolvedNodePath -ne $expectedNodePath) {
    throw "Refusing to stop PID $backendPid because its executable path is unexpected: $resolvedNodePath"
}

Stop-Process -Id $backendPid -Force
Remove-Item -LiteralPath $pidFile -Force
Write-Host "Stopped SUT backend process $backendPid."
