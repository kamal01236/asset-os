#Requires -Version 5.1
<#
.SYNOPSIS
  Run Hando WSL scripts from Windows PowerShell (Flutter web).

.EXAMPLE
  .\scripts\wsl.ps1 setup
  .\scripts\wsl.ps1 localrun
  .\scripts\wsl.ps1 test
  .\scripts\wsl.ps1 test unit
  .\scripts\wsl.ps1 test orders
  .\scripts\wsl.ps1 wsldeploy
  .\scripts\wsl.ps1 servelocal
  .\scripts\wsl.ps1 doctor
#>
param(
  [Parameter(Position = 0)]
  [ValidateSet("setup", "localrun", "test", "wsldeploy", "servelocal", "doctor", "help")]
  [string]$Command = "help",

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = "Stop"

function Convert-ToWslPath {
  param([string]$WindowsPath)
  $resolved = (Resolve-Path $WindowsPath).Path
  if ($resolved -match '^([A-Za-z]):\\(.*)$') {
    $drive = $Matches[1].ToLowerInvariant()
    $tail = ($Matches[2] -replace '\\', '/')
    return "/mnt/$drive/$tail"
  }
  throw "Unable to convert path to WSL: $WindowsPath"
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$wslRoot = Convert-ToWslPath $repoRoot.Path

if ($Command -eq "help") {
  Write-Host @"
Usage: .\scripts\wsl.ps1 <command> [args...]

Commands:
  setup       Bootstrap Flutter web tooling and pub get
  localrun    Run the app on Chrome or web-server
  test        flutter analyze + flutter test [suite]
              Suites: all|unit|widget|integration|orders|pricing|returns|
                      inventory|customers|deposit|search|shell|reports|notes|labels
              Examples: .\scripts\wsl.ps1 test unit
                        .\scripts\wsl.ps1 test orders
              Docs: docs/engineering/test-suites.md
  wsldeploy   Build web artifacts (build/web)
  servelocal  Serve build/web locally and print the open URL
  doctor      flutter doctor -v

Flutter web client only (apps/web). Android/Linux desktop doctor failures are expected.
"@
  exit 0
}

$extra = ""
if ($Rest -and $Rest.Count -gt 0) {
  $extra = ($Rest | ForEach-Object { $_ }) -join " "
}

$bashCmd = "cd '$wslRoot' && bash ./scripts/dev.sh $Command $extra"
Write-Host "==> wsl bash -lc `"$bashCmd`""
wsl -e bash -lc $bashCmd
exit $LASTEXITCODE
