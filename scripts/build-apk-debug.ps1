#Requires -Version 5.1
<#
.SYNOPSIS
  Build a debug APK for sideloading (Windows-native).

.EXAMPLE
  .\scripts\build-apk-debug.ps1
#>
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "apps\web"
$apkPath = Join-Path $appDir "build\app\outputs\flutter-apk\app-debug.apk"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "flutter is not on PATH. Run .\scripts\setup-android.ps1 after installing Flutter."
}

Push-Location $appDir
try {
  Write-Host "==> flutter build apk --debug"
  flutter build apk --debug
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host ""
  Write-Host "Debug APK: $apkPath"
  exit 0
}
finally {
  Pop-Location
}
