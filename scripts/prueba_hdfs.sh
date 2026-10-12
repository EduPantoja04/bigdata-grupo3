#!/bin/bash
# Prueba funcional de HDFS - Grupo 03 (LG14)
# Uso desde PowerShell, en la raíz de bigdata-grupo3:
#   docker cp scripts/prueba_hdfs.sh namenode:/tmp/prueba_hdfs.sh
#   docker exec namenode bash /tmp/prueba_hdfs.sh

set -e

ARCHIVO_LOCAL=/hadoop-data/input/registro_grupo03.txt
DIR_HDFS=/grupo03/lg14

echo "== 1. Crear directorio $DIR_HDFS"
hdfs dfs -mkdir -p "$DIR_HDFS"

echo "== 2. Cargar $ARCHIVO_LOCAL"
hdfs dfs -put -f "$ARCHIVO_LOCAL" "$DIR_HDFS/"

echo "== 3. Listar el directorio"
hdfs dfs -ls "$DIR_HDFS"

echo "== 4. Leer el archivo desde HDFS"
hdfs dfs -cat "$DIR_HDFS/registro_grupo03.txt"

echo "== 5. Bloques y ubicación de las réplicas"
hdfs fsck "$DIR_HDFS/registro_grupo03.txt" -files -blocks -locations
