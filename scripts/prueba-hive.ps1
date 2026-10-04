param(
    [string]$ComposeDir = (Join-Path $env:USERPROFILE "source\docker-hive")
)

$ErrorActionPreference = "Stop"
Set-Location $ComposeDir

$scriptPath = Join-Path $PSScriptRoot "prueba-hive.sh"
$lf = [System.IO.File]::ReadAllText($scriptPath).Replace("`r`n", "`n").Replace("`r", "")
$temp = Join-Path $env:TEMP "prueba-hive.sh"
[System.IO.File]::WriteAllText($temp, $lf)

docker compose cp $temp hive-server:/tmp/prueba-hive.sh
docker compose exec -T hive-server bash /tmp/prueba-hive.sh
