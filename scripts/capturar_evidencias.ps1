# Guarda en evidencias\salidas las salidas reales del clúster - Grupo 03 (LG14)
# Uso (PowerShell, con el clúster levantado):  .\scripts\capturar_evidencias.ps1

$salidas = Join-Path $PSScriptRoot "..\evidencias\salidas"
New-Item -ItemType Directory -Force $salidas | Out-Null
# Windows PowerShell 5.1 escribe UTF-16 con ">"; se fuerza UTF-8 sin BOM para que GitHub lo muestre bien.
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Guardar($archivo, $titulo, $comando) {
    $salida = cmd /c "$comando 2>&1" | Where-Object { $_ -notmatch "HADOOP_PREFIX has been replaced" }
    $texto = "Grupo 03 - LG14`nEvidencia: $titulo`nComando: $comando`nFecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" +
             ("-" * 70) + "`n" + ($salida -join "`n") + "`n"
    [IO.File]::WriteAllText((Join-Path $salidas $archivo), $texto, $utf8)
    Write-Output "$archivo ($($salida.Count) líneas)"
}

Set-Location (Join-Path $PSScriptRoot "..\hadoop-environment")

Guardar "01_docker_version.txt" "Versiones de Docker y Docker Compose" 'docker version --format "Docker {{.Server.Version}}" && docker compose version'
Guardar "02_docker_ps.txt" "Contenedores del clúster en ejecución" 'docker ps --filter network=hadoop_network --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
Guardar "03_docker_compose_ps.txt" "Servicios según Docker Compose" 'docker compose ps'
Guardar "04_red_hadoop_network.txt" "Red hadoop_network y direcciones IP" 'docker network inspect hadoop_network --format "{{range .Containers}}{{.Name}}  {{.IPv4Address}}{{println}}{{end}}"'
Guardar "05_volumenes.txt" "Volúmenes Docker del clúster" 'docker volume ls --filter name=hadoop'
Guardar "06_imagenes.txt" "Imágenes construidas localmente" 'docker images --filter reference=hadoop-base --filter reference=hadoop-environment*'
Guardar "07_versiones_hadoop_java_so.txt" "Versión de Hadoop, Java y sistema operativo base" 'docker exec namenode bash -c "hadoop version | head -n 1; echo; echo JAVA_HOME=$JAVA_HOME; $JAVA_HOME/bin/java -version 2>&1; echo; grep PRETTY_NAME /etc/os-release; python3 --version"'
Guardar "08_hdfs_dfsadmin_report.txt" "Estado de HDFS: NameNode y DataNodes" 'docker exec namenode hdfs dfsadmin -report'
Guardar "09_hdfs_ls_grupo03.txt" "Prueba funcional: directorio y archivo en HDFS" 'docker exec namenode hdfs dfs -ls -R /grupo03'
Guardar "10_hdfs_cat_registro.txt" "Prueba funcional: lectura del archivo desde HDFS" 'docker exec namenode hdfs dfs -cat /grupo03/lg14/registro_grupo03.txt'
Guardar "11_hdfs_fsck_registro.txt" "Bloques y ubicación de las réplicas del archivo" 'docker exec namenode hdfs fsck /grupo03/lg14/registro_grupo03.txt -files -blocks -locations'
Guardar "12_yarn_nodos.txt" "Nodos registrados en YARN" 'docker exec resourcemanager yarn node -list -all'
