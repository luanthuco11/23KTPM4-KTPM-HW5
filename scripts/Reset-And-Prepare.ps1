[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot 'Stop-Sut.ps1')
& (Join-Path $PSScriptRoot 'Start-Sut.ps1')
& (Join-Path $PSScriptRoot 'Prepare-TestAccounts.ps1')

Write-Host 'Clean SUT and account pool are ready for a test run.'

