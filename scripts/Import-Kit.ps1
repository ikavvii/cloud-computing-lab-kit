$ErrorActionPreference = 'Stop'
$kitRoot = Split-Path $PSScriptRoot -Parent
$tar = Join-Path $kitRoot 'images.tar'
if (!(Test-Path -LiteralPath $tar)) { throw 'Run import from the exported exam-pack folder containing images.tar.' }
$expected = ((Get-Content -LiteralPath "$tar.sha256" -Raw).Trim() -split '\s+')[0]
$actual = (Get-FileHash -LiteralPath $tar -Algorithm SHA256).Hash
if ($actual -ne $expected) { throw 'Image archive checksum mismatch: copy the package again.' }
& docker load --input $tar
if ($LASTEXITCODE -ne 0) { throw 'docker load failed' }
Write-Host 'Images imported. Run ./lab.ps1 smoke before the exam, or open docs/EXAM-CHEATSHEET.md.'
