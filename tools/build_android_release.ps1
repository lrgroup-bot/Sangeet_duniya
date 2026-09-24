# LRS Sangeet_Duniya release builder for Windows.
# Run from the repository or with:
#   powershell -ExecutionPolicy Bypass -File .\tools\build_android_release.ps1

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== LR's Sangeet_Duniya v1.0 Alpha =="
Write-Host "Repository: $root"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter SDK was not found in PATH. Install Flutter on this PC first."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git was not found in PATH."
}

git fetch origin
git checkout tailscale-admin
git pull --ff-only origin tailscale-admin

flutter pub get
flutter analyze

$releaseDir = Join-Path $root 'releases'
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

flutter build apk --release

$apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $apk)) {
    throw "Flutter completed without producing app-release.apk."
}

$out = Join-Path $releaseDir "LRS_Sangeet_Duniya_v1.0_Alpha.apk"
Copy-Item -Force $apk $out

Write-Host ""
Write-Host "BUILD SUCCESS"
Write-Host "APK: $out"
