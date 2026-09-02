#Requires -Version 5.1
<#
.SYNOPSIS
  Bootstrap Flutter Android tooling for apps/web (Windows-native).

.EXAMPLE
  .\scripts\setup-android.ps1
#>
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "apps\web"

function Assert-Flutter {
  if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error @"
flutter is not on PATH.

Install Flutter stable (SDK ^3.12.2), Android Studio + SDK API 34, JDK 17, then:
  flutter doctor
  flutter doctor --android-licenses
"@
  }
}

Push-Location $appDir
try {
  Assert-Flutter

  Write-Host "==> flutter doctor -v"
  flutter doctor -v
  if ($LASTEXITCODE -ne 0) { Write-Host "warning: flutter doctor reported issues (continuing)" }

  if (-not (Test-Path "android") -or -not (Test-Path "android\gradlew.bat")) {
    Write-Host "==> flutter create --platforms=android --org com.hando ."
    flutter create --platforms=android --org com.hando .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }

  Write-Host "==> flutter pub get"
  flutter pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host "==> dart run build_runner build --delete-conflicting-outputs"
  dart run build_runner build --delete-conflicting-outputs
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  exit 0
}
finally {
  Pop-Location
}
