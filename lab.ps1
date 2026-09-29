param(
  [ValidateSet('build','start','shell','weather','pig','cloudsim','hive','web','smoke','export','import','stop','status')]
  [string]$Action = 'status',
  [string]$Value = ''
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
function Invoke-Docker {
  & docker @args
  if ($LASTEXITCODE -ne 0) { throw "Docker command failed (exit $LASTEXITCODE). Check the error above." }
}
function Start-BigData { Invoke-Docker compose up -d --no-build --pull never --wait --wait-timeout 300 bigdata }
function Run-Hive {
  Invoke-Docker compose up -d --no-build --pull never --wait --wait-timeout 420 hive
  Invoke-Docker compose exec -T hive bash /workspace/beeline.sh -u jdbc:hive2://localhost:10000/default -n hive --silent=true -f /workspace/sales.hql
  $output = & docker compose exec -T hive bash /workspace/beeline.sh -u jdbc:hive2://localhost:10000/default -n hive --silent=true --showHeader=false --outputformat=tsv2 -f /workspace/result.hql
  if ($LASTEXITCODE -ne 0) { throw 'Hive result export failed' }
  # Keep every five-column TSV row, including unexpected NULL ids, so validation
  # can detect a header accidentally read as data or any other extra records.
  $rows = @($output | Where-Object { ($_ -split "`t").Count -eq 5 })
  [IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'artifacts/hive-result.tsv'), [string[]]$rows, (New-Object Text.UTF8Encoding $false))
}
Invoke-Docker info --format '{{.OSType}}/{{.Architecture}}'
New-Item -ItemType Directory -Force artifacts | Out-Null
switch ($Action) {
  'build' {
    Invoke-Docker compose --profile '*' build
    Invoke-Docker compose --profile hive --profile web pull hive db
  }
  'start' { Start-BigData }
  'shell' { Start-BigData; Invoke-Docker compose exec bigdata bash }
  'weather' { Start-BigData; if (!$Value) {$Value='25'}; Invoke-Docker compose exec -T bigdata bash /workspace/labs/04-weather/run.sh $Value }
  'pig' { Start-BigData; if (!$Value) {$Value='Electronics'}; Invoke-Docker compose exec -T bigdata bash /workspace/labs/05-pig/run.sh $Value }
  'cloudsim' { if (!$Value) {$Value='minmin'}; Invoke-Docker compose run --rm --no-deps --pull never cloudsim $Value }
  'hive' { Run-Hive }
  'web' {
    Invoke-Docker compose up -d --no-build --pull never --wait --wait-timeout 120 db web
    Write-Host 'Open http://localhost:8000 | Local password: practice-only-change-me (unless overridden in .env)'
  }
  'smoke' {
    # Sequential services reduce RAM pressure. Existing containers are retained.
    Start-BigData
    Invoke-Docker compose exec -T bigdata bash /workspace/labs/04-weather/run.sh
    Invoke-Docker compose exec -T -e WEATHER_INPUT=weather-edge.csv bigdata bash /workspace/labs/04-weather/run.sh 25
    Copy-Item artifacts/weather-result.tsv artifacts/weather-edge-result.tsv
    Invoke-Docker compose exec -T bigdata bash /workspace/labs/04-weather/run.sh
    Invoke-Docker compose exec -T bigdata bash /workspace/labs/05-pig/run.sh
    Invoke-Docker compose stop bigdata
    Invoke-Docker compose run --rm --no-deps --pull never cloudsim minmin
    Invoke-Docker compose run --rm --no-deps --pull never cloudsim roundrobin
    Run-Hive
    Invoke-Docker compose stop hive
    Invoke-Docker compose up -d --no-build --pull never --wait --wait-timeout 120 db web
    Invoke-Docker compose exec -T web python test_app.py
    Invoke-Docker compose run --rm --no-deps --pull never --entrypoint python3 bigdata /workspace/labs/check-results.py
  }
  'export' { & (Join-Path $PSScriptRoot 'scripts/Export-Kit.ps1') }
  'import' { & (Join-Path $PSScriptRoot 'scripts/Import-Kit.ps1') }
  'stop' { Invoke-Docker compose --profile '*' stop }
  'status' { Invoke-Docker compose --profile '*' ps -a }
}
