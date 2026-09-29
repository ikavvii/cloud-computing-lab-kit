$ErrorActionPreference = 'Stop'
$kitRoot = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $kitRoot 'artifacts/exam-pack'
New-Item -ItemType Directory -Force $destination | Out-Null
$images = @('cloud-lab-bigdata:1.0','cloud-lab-cloudsim:1.0','cloud-lab-web:1.0','apache/hive:4.2.1','postgres:18.1-bookworm')
foreach ($image in $images) {
  & docker image inspect $image --format '{{.Id}}'
  if ($LASTEXITCODE -ne 0) { throw "Image missing: $image. Run ./lab.ps1 build first." }
}
$manifest = & docker image inspect @images | ConvertFrom-Json | ForEach-Object {
  [pscustomobject]@{tags=$_.RepoTags; id=$_.Id; os=$_.Os; architecture=$_.Architecture}
}
if ($LASTEXITCODE -ne 0) { throw 'Image metadata export failed' }
[IO.File]::WriteAllText((Join-Path $destination 'images-manifest.json'), ($manifest | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding $false))
$tar = Join-Path $destination 'images.tar'
& docker image save --output $tar @images
if ($LASTEXITCODE -ne 0) { throw 'Image export failed' }
$hash = (Get-FileHash -LiteralPath $tar -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $destination 'images.tar.sha256'), "$hash  images.tar`n")
foreach ($name in @('compose.yaml','lab.ps1','README.md','docs','labs','scripts','docker','.gitattributes','.dockerignore','.gitignore','.env.example')) {
  $source = Get-Item -LiteralPath (Join-Path $kitRoot $name) -Force
  $files = if ($source.PSIsContainer) { Get-ChildItem -LiteralPath $source.FullName -File -Recurse -Force } else { @($source) }
  foreach ($file in $files) {
    if ($file.FullName -match '[\\/]__pycache__[\\/]' -or $file.Extension -in @('.log','.pyc','.class','.jar')) { continue }
    $relative = $file.FullName.Substring($kitRoot.Length + 1)
    $target = Join-Path $destination $relative
    New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
  }
}
New-Item -ItemType Directory -Force (Join-Path $destination 'artifacts') | Out-Null
Write-Host "Offline package: $destination"
Write-Host 'Copy the WHOLE exam-pack folder to the lab PC. Run ./lab.ps1 import there.'
Write-Host 'Images do not contain your HDFS/database volumes or .env. Exercises recreate sample data.'
