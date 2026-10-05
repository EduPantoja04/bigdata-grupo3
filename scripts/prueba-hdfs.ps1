param(
    [string]$ComposeDir = (Join-Path $env:USERPROFILE "source\docker-hive")
)

$ErrorActionPreference = "Stop"
Set-Location $ComposeDir

$scriptPath = Join-Path $PSScriptRoot "prueba-hdfs.sh"
$lf = [System.IO.File]::ReadAllText($scriptPath).Replace("`r`n", "`n").Replace("`r", "")
$temp = Join-Path $env:TEMP "prueba-hdfs.sh"
[System.IO.File]::WriteAllText($temp, $lf)

docker compose cp $temp namenode:/tmp/prueba-hdfs.sh
docker compose exec -T namenode bash /tmp/prueba-hdfs.sh
