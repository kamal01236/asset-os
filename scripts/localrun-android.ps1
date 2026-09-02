#Requires -Version 5.1
<#
.SYNOPSIS
  Run Hando on a connected Android device or emulator (Windows-native).

.EXAMPLE
  .\scripts\localrun-android.ps1
#>
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "apps\web"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "flutter is not on PATH. Run .\scripts\setup-android.ps1 after installing Flutter."
}

Push-Location $appDir
try {
  Write-Host "==> flutter run -d android"
  flutter run -d android
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
