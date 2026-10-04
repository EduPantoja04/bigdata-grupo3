param(
    [string]$ComposeDir = (Join-Path $env:USERPROFILE "source\docker-hive")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $ComposeDir "docker-compose.yml"))) {
    Write-Host "No está el clon. Clonando big-data-europe/docker-hive en $ComposeDir"
    git clone https://github.com/big-data-europe/docker-hive.git $ComposeDir
}

Set-Location $ComposeDir
Write-Host "=== Archivos principales ==="
Get-ChildItem -Force | Select-Object Mode, Length, Name | Format-Table -AutoSize

Write-Host "=== docker compose up -d ==="
docker compose up -d

Write-Host "=== docker ps ==="
docker ps --filter "name=docker-hive" --format "table {{.Names}}`t{{.Image}}`t{{.Status}}`t{{.Ports}}"
