# Despliegue del clúster hadoop-environment - Grupo 03 (LG14)
# Uso (PowerShell, desde la raíz de bigdata-grupo3):  .\scripts\despliegue.ps1

Set-Location (Join-Path $PSScriptRoot "..\hadoop-environment")

docker network inspect hadoop_network *> $null
if ($LASTEXITCODE -ne 0) {
    docker network create hadoop_network
}

docker build -t hadoop-base:3.3.6 .
docker compose up -d --build
docker ps --filter network=hadoop_network --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
