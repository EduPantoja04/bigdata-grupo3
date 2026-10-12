# 6. Comparación entre los experimentos

En ambos experimentos se utilizó el mismo clúster Hadoop, con un NameNode, tres DataNodes y un factor de replicación de 2. Se detuvo `datanode2` para observar el efecto sobre los bloques almacenados y la recuperación automática de HDFS.

| Característica | Dataset 1 GB | Dataset 10 GB |
|---|---|---|
| **Tamaño** | 1 GiB (1.073.741.824 bytes) | 10 GiB (10.737.418.240 bytes) |
| **Número de bloques** | 8 bloques de 128 MiB | 80 bloques de 128 MiB |
| **Factor de replicación** | 2 (16 réplicas de bloques en total antes de la falla) | 2 (160 réplicas de bloques en total antes de la falla) |
| **DataNode afectado** | `datanode2` (`172.21.0.4`) | `datanode2` (`172.21.0.4`) |
| **Bloques afectados** | 6 de 8 bloques (75 %) tenían una réplica en `datanode2` | 56 de 80 bloques (70 %) tenían una réplica en `datanode2` |
| **Bloques disponibles después de la falla** | 8 de 8; no hubo bloques perdidos | 80 de 80; no hubo bloques perdidos |
| **¿El archivo continuó accesible?** | Sí. Se leyó completo y el MD5 coincidió con el valor de referencia; la lectura tomó 7 s | Sí. Se leyó completo y el MD5 coincidió con el valor de referencia; la lectura tomó entre 38 y 45 s |
| **¿Existieron bloques subreplicados?** | Sí. El monitoreo registró hasta 7 bloques subreplicados mientras HDFS reconocía la caída y recuperaba las copias | Sí. El monitoreo registró hasta 77 bloques subreplicados; otra captura observó 50 de 80 (62,5 %) durante la recuperación |
| **Tiempo de recuperación registrado** | El DataNode fue declarado muerto a los 93 s y el monitoreo terminó al llegar a cero bloques subreplicados a los 270 s | El DataNode fue declarado muerto a los 93 s y el monitoreo terminó al llegar a cero bloques subreplicados a los 270 s |
| **Nuevas réplicas** | 6: 2 en `datanode1` y 4 en `datanode3` | 56: 32 en `datanode1` y 24 en `datanode3` |

## Análisis

Los dos archivos permanecieron disponibles porque cada bloque que perdió una réplica conservó otra copia en un DataNode activo. La caída redujo temporalmente el número de réplicas de algunos bloques, pero no eliminó la última copia de ninguno. Por eso los registros muestran cero bloques perdidos y las lecturas completas conservaron el mismo MD5 que antes de la falla.

El dataset de 10 GiB permite observar el comportamiento distribuido con mayor claridad: contiene 80 bloques, frente a los 8 del dataset de 1 GiB, y la falla afectó a 56 bloques en lugar de 6. En sus registros se ve cómo la cantidad de bloques subreplicados disminuye gradualmente mientras HDFS crea nuevas réplicas. En el dataset de 1 GiB hay menos bloques y la recuperación es menos visible.

## Interpretación del tiempo

En los monitores de ambos datasets, `datanode2` fue declarado muerto a los 93 s y se registró la recuperación completa a los 270 s desde el inicio del monitoreo. Estos tiempos no representan dos pruebas aisladas: durante el experimento, ambos datasets compartieron la cola de re-replicación del NameNode. Por ello, los 270 s describen el tiempo observado en ese escenario combinado y no permiten afirmar cuánto habría tardado cada dataset por separado.

## Conclusión

HDFS mantuvo disponibles ambos archivos y restauró automáticamente el factor de replicación después de la caída de `datanode2`. El experimento de 10 GiB mostró mejor el proceso de recuperación porque involucró diez veces más bloques. En los dos casos, la disponibilidad del archivo se mantuvo mientras existía al menos una copia viva de cada bloque; durante la recuperación, algunos bloques todavía no cumplían temporalmente el factor de replicación configurado.

## Evidencias

- Dataset de 1 GiB: [`1GB_01_antes_report.txt`](../evidencias/lg15/1GB_01_antes_report.txt), [`1GB_02_antes_fsck.txt`](../evidencias/lg15/1GB_02_antes_fsck.txt), [`1GB_03_antes_replicas_por_nodo.txt`](../evidencias/lg15/1GB_03_antes_replicas_por_nodo.txt), [`1GB_06_durante_md5.txt`](../evidencias/lg15/1GB_06_durante_md5.txt), [`1GB_despues.txt`](../evidencias/lg15/1GB_despues.txt) y [`1GB_esperar.txt`](../evidencias/lg15/1GB_esperar.txt).
- Dataset de 10 GiB: [`10GB_antes.txt`](../evidencias/lg15/10GB_antes.txt), [`10GB_durante_recuperacion.txt`](../evidencias/lg15/10GB_durante_recuperacion.txt), [`10GB_despues.txt`](../evidencias/lg15/10GB_despues.txt) y [`10GB_esperar.txt`](../evidencias/lg15/10GB_esperar.txt).
