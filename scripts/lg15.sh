#!/bin/bash
# Grupo 03 - LG15: captura el estado de HDFS para un dataset en un momento del experimento.
# Uso: bash lg15.sh <1GB|10GB> <antes|durante|despues|restaurado> [leer]
#      bash lg15.sh <1GB|10GB> esperar
set -o pipefail

DATASET=$1
MOMENTO=$2
OPCION=${3:-}
DIR=/grupo03/dataset_${DATASET}
ARCHIVO=${DIR}/dataset_grupo03_${DATASET}
SALIDA=/hadoop-data/input/lg15/${DATASET}_${MOMENTO}.txt
FSCK=/tmp/fsck_lg15_${DATASET}_$$.txt
ERRORES=/tmp/lectura_lg15_${DATASET}_$$.err
trap 'rm -f "$FSCK" "$ERRORES"' EXIT

nombre_nodo() {
    local n
    n=$(getent hosts "$1" | awk '{print $2}' | cut -d. -f1)
    echo "${n:-nodo detenido}"
}

estado() {
    echo "== DataNodes (hdfs dfsadmin -report)"
    hdfs dfsadmin -report 2>/dev/null | grep -E '^(Live|Dead) datanodes|^Name:|^Last contact:|Under replicated'
    echo

    hdfs fsck "$DIR" -files -blocks -locations 2>/dev/null > "$FSCK"
    echo "== Archivo y bloques (hdfs fsck)"
    sed '/Erasure Coded Block Groups/q' "$FSCK" \
        | grep -E 'Status:|Total size|Total blocks|Under-replicated|Over-replicated|Missing blocks|Corrupt blocks|Average block replication|Number of data-nodes'
    echo

    echo "== Replicas por DataNode"
    grep -oE '[0-9]+(\.[0-9]+){3}:9866' "$FSCK" | sort | uniq -c | while read -r cantidad direccion; do
        ip=${direccion%:9866}
        echo "  ${cantidad} replicas en ${ip} ($(nombre_nodo "$ip"))"
    done
    echo

    echo "== Detalle de bloques"
    grep -E '^[0-9]+\. BP' "$FSCK" \
        | sed -E 's/BP-[^:]*://; s/DatanodeInfoWithStorage\[([0-9.:]+),[^]]*\]/\1/g'
}

leer() {
    echo
    echo "== Lectura completa del archivo (hdfs dfs -cat | md5sum)"
    local inicio md5
    inicio=$(date +%s)
    if md5=$(hdfs dfs -cat "$ARCHIVO" 2>"$ERRORES" | md5sum | cut -d' ' -f1); then
        echo "  LECTURA OK - md5: ${md5} ($(( $(date +%s) - inicio )) s)"
    else
        echo "  LECTURA FALLIDA"
    fi
    grep -E 'Failed to connect' "$ERRORES" | sed -E 's/ for block.*//' | cut -c1-160
}

esperar() {
    echo "Monitoreo cada 5 s hasta que no queden bloques subreplicados (Ctrl+C para cortar)"
    local inicio reporte vivos muertos ip_muerto sub en_caido detectado=""
    inicio=$(date +%s)
    while true; do
        reporte=$(hdfs dfsadmin -report 2>/dev/null)
        vivos=$(grep -oP '^Live datanodes \(\K[0-9]+' <<<"$reporte")
        muertos=$(grep -oP '^Dead datanodes \(\K[0-9]+' <<<"$reporte")
        muertos=${muertos:-0}
        ip_muerto=$(awk '/^Dead datanodes/{f=1} f && /^Name:/{print $2; exit}' <<<"$reporte")

        hdfs fsck "$DIR" -files -blocks -locations 2>/dev/null > "$FSCK"
        sub=$(grep -oP 'Under-replicated blocks:\s*\K[0-9]+' "$FSCK" | head -1)
        en_caido=0
        [ -n "$ip_muerto" ] && en_caido=$(grep -o "$ip_muerto" "$FSCK" | wc -l)
        echo "$(date '+%T')  +$(( $(date +%s) - inicio ))s  vivos=${vivos} muertos=${muertos} subreplicados=${sub} replicas_en_nodo_caido=${en_caido}"

        if [ "$muertos" -ge 1 ] && [ -z "$detectado" ]; then
            detectado=$(( $(date +%s) - inicio ))
        fi
        # El nodo aparece como muerto unos segundos antes de que el NameNode quite sus replicas del mapa de bloques.
        if [ "$muertos" -ge 1 ] && [ "${sub:-1}" -eq 0 ] && [ "$en_caido" -eq 0 ]; then
            echo
            echo "DataNode declarado muerto a los ${detectado} s del inicio del monitoreo"
            echo "Recuperacion completa a los $(( $(date +%s) - inicio )) s del inicio del monitoreo"
            break
        fi
        sleep 5
    done
}

mkdir -p /hadoop-data/input/lg15
{
    echo "GRUPO 03 - LG15 - Dataset ${DATASET} - Momento: ${MOMENTO} - $(date '+%F %T')"
    echo
    if [ "$MOMENTO" = "esperar" ]; then
        esperar
    else
        estado
        [ "$OPCION" = "leer" ] && leer
    fi
} 2>&1 | tee "$SALIDA"

echo
echo "Guardado en ${SALIDA}"
