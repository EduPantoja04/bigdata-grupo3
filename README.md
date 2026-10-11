# bigdata-grupo3 — LG14: Despliegue de un repositorio Big Data con Docker

**Universidad del Valle — Grupo 03**
**Integrantes:** Pantoja, Antezana, Escalera

Investigación, despliegue y prueba funcional del repositorio
[spraharaj-projects/hadoop-environment](https://github.com/spraharaj-projects/hadoop-environment):
un clúster **Apache Hadoop 3.3.6** multinodo (1 NameNode, 3 DataNodes, YARN e History Server)
orquestado con **Docker Compose**. Se compara con el proyecto de referencia
[big-data-europe/docker-hadoop](https://github.com/big-data-europe/docker-hadoop).

## Contenido del repositorio

| Ruta | Contenido |
|---|---|
| [`REGISTRO.txt`](REGISTRO.txt) | Registro del repositorio seleccionado |
| [`hadoop-environment/`](hadoop-environment/) | Archivos de configuración usados: `docker-compose.yml`, `Dockerfile` base (con correcciones), `conf/*.xml` y `Dockerfile` + `run.sh` de cada servicio |
| [`hadoop-environment/data/`](hadoop-environment/data/) | Archivo de prueba cargado a HDFS (`registro_grupo03.txt`) |
| [`scripts/`](scripts/) | Scripts de despliegue, prueba HDFS y captura de evidencias |
| [`docs/arquitectura.md`](docs/arquitectura.md) | Diagrama y análisis detallado de la arquitectura |
| [`docs/manual-comandos.md`](docs/manual-comandos.md) | Manual paso a paso de todos los comandos, indicando dónde se ejecuta cada uno |
| [`evidencias/salidas/`](evidencias/salidas/) | Salidas reales de los comandos ejecutados |
| [`evidencias/capturas/`](evidencias/capturas/) | Capturas de las interfaces web y de la terminal |

---

## 1. Información general del repositorio seleccionado

| Campo | Valor |
|---|---|
| Nombre | `hadoop-environment` |
| Autor / organización | [spraharaj-projects](https://github.com/spraharaj-projects) |
| URL | https://github.com/spraharaj-projects/hadoop-environment |
| Fecha de creación | 11/06/2024 |
| Última actualización del código | 11/06/2024 (3 commits, todos ese día) |
| Estrellas | 5 |
| Forks | 0 |
| Licencia | El README declara **Apache 2.0**, pero el repositorio no incluye archivo `LICENSE` y GitHub no detecta ninguna licencia |
| Lenguajes (GitHub) | Python 44.8 %, Dockerfile 34.6 %, Shell 20.5 % |

**Objetivo del proyecto:** ofrecer una guía paso a paso para montar, en una sola máquina con WSL2 y
Docker, un clúster Hadoop 3.3.6 multinodo que se parezca a uno real: un contenedor por cada demonio de
Hadoop, tres DataNodes y los servicios de YARN necesarios para ejecutar trabajos MapReduce.

## 2. Tecnologías

| Elemento | Detalle |
|---|---|
| Tecnología Big Data principal | Apache Hadoop: **HDFS** (almacenamiento) y **YARN + MapReduce** (procesamiento) |
| Versión | Hadoop **3.3.6** (verificado con `hadoop version`) |
| Docker | Docker Engine **29.6.1** (Docker Desktop en Windows 11) |
| Docker Compose | Compose **v5.3.0**; el archivo declara `version: "2.4"` (Compose lo ignora y avisa que es obsoleto) |
| Sistema operativo base | **Debian 12 (bookworm)**, desde la imagen `python:3.11-bookworm` |
| Java | **Eclipse Temurin OpenJDK 11.0.32** (copiado desde `eclipse-temurin:11-jdk`) |
| Bases de datos | No usa bases de datos externas. El estado del ResourceManager se guarda en HDFS (`/rmstate`) y el historial de aplicaciones en un almacén local LevelDB del History Server |
| Frameworks adicionales | YARN Timeline / Application History Server. Python 3.11 viene en la imagen base, pero Hadoop no lo usa |
| Lenguajes | Dockerfile, Bash (`run.sh`), XML (configuración de Hadoop), YAML (Compose) y Python (`project_init.py` y `project_init_2.py` solo crean la estructura de carpetas vacía a partir de `project_structure.yml`) |

## 3. Arquitectura

El diagrama completo y el análisis de cada contenedor, puerto, red, volumen, dependencia, variable de
entorno y archivo de configuración están en **[`docs/arquitectura.md`](docs/arquitectura.md)**.

Resumen:

| Contenedor | Función | Puerto en el host | Volumen |
|---|---|---|---|
| `namenode` | Maestro de HDFS (metadatos y ubicación de bloques) | 9870 (web), 8020 (RPC) | `hadoop_namenode` |
| `datanode1` | Almacena bloques de HDFS | — | `hadoop_datanode1` |
| `datanode2` | Almacena bloques de HDFS | — | `hadoop_datanode2` |
| `datanode3` | Almacena bloques de HDFS | — | `hadoop_datanode3` |
| `resourcemanager` | Maestro de YARN (asigna recursos a los trabajos) | 8089 → 8088 (web) | — |
| `nodemanager1` | Ejecuta las tareas de YARN | 8042 (web) | — |
| `historyserver` | Historial de aplicaciones YARN | 8188 (web) | `hadoop_historyserver` |

- **Contenedores:** 7, uno por demonio de Hadoop, todos con imágenes construidas localmente.
- **Red:** `hadoop_network` (bridge **externa**: hay que crearla antes de `docker compose up`).
- **Configuración:** archivos XML en `conf/`, copiados dentro de la imagen base.
- **Replicación:** no está configurada, por lo que HDFS usa el valor por defecto (**3**) con bloques de **128 MB**.

---

## 4. Instalación y ejecución

### Requisitos

- Docker Desktop con Docker Compose v2 o superior.
- Unos 6 GB libres para las imágenes y conexión a internet para el primer build (descarga Hadoop, ~700 MB).

### Paso 1 — Clonar el repositorio

Se clona con `core.autocrlf=false`. Git para Windows convierte por defecto los finales de línea a CRLF,
y los `run.sh` con CRLF hacen que los contenedores se detengan con `/bin/bash^M: bad interpreter`.

```powershell
git clone -c core.autocrlf=false https://github.com/spraharaj-projects/hadoop-environment.git
```

### Paso 2 — Ingresar al directorio

```powershell
cd hadoop-environment
```

### Paso 3 — Identificar los archivos principales

```powershell
Get-ChildItem -Force        # equivalente a: ls -la
```

| Archivo / carpeta | Rol |
|---|---|
| `docker-compose.yml` | Define los 7 servicios |
| `Dockerfile` | Imagen base `hadoop-base:3.3.6` (Java + Hadoop + configuración) |
| `conf/` | `core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`, `mapred-site.xml` |
| `namenode/`, `datanode/`, `resourcemanager/`, `nodemanager/`, `historyserver/` | `Dockerfile` y `run.sh` de cada servicio |
| `start-cluster.sh` | Script original de arranque (usa el comando antiguo `docker-compose`) |
| `project_init.py`, `project_init_2.py`, `project_structure.yml` | Generan la estructura de carpetas vacía; no intervienen en el despliegue |

### Paso 4 — Analizar el archivo de Docker Compose

```powershell
Get-Content docker-compose.yml   # equivalente a: cat docker-compose.yml
```

El análisis completo del archivo está en [`docs/arquitectura.md`](docs/arquitectura.md).

### Correcciones necesarias antes de construir

El repositorio **no compila tal como está publicado**, porque dos imágenes base cambiaron desde 2024.
El grupo aplicó tres cambios al `Dockerfile` de la raíz (la versión corregida está en
[`hadoop-environment/Dockerfile`](hadoop-environment/Dockerfile)):

| Original | Corregido | Motivo |
|---|---|---|
| `FROM openjdk:11-jdk AS jdk` | `FROM eclipse-temurin:11-jdk AS jdk` | La imagen oficial `openjdk` fue retirada de Docker Hub |
| `FROM python:3.11` | `FROM python:3.11-bookworm` | `python:3.11` ahora usa Debian 13 (trixie), que ya no tiene el paquete `software-properties-common` que instala el `Dockerfile` |
| `COPY --from=jdk $JAVA_HOME $JAVA_HOME` | `COPY --from=jdk /opt/java/openjdk $JAVA_HOME` | En la imagen Temurin, Java está en `/opt/java/openjdk` y no en `/usr/local/openjdk-11` |

### Paso 5 — Construir y ejecutar

```powershell
docker network create hadoop_network
docker build -t hadoop-base:3.3.6 .
docker compose up -d --build
```

La red se crea a mano porque el Compose la declara como externa. Los mismos pasos, usando los archivos
de este repositorio, están en [`scripts/despliegue.ps1`](scripts/despliegue.ps1).

### Paso 6 — Verificar los contenedores

```powershell
docker ps
```

Resultado ([`02_docker_ps.txt`](evidencias/salidas/02_docker_ps.txt), sin las líneas de puertos IPv6):
los 7 contenedores en estado `Up (healthy)`.

```text
NAMES             IMAGE                                STATUS                    PORTS
historyserver     hadoop-environment-historyserver     Up 59 minutes (healthy)   0.0.0.0:8188->8188/tcp
nodemanager1      hadoop-environment-nodemanager1      Up 59 minutes (healthy)   0.0.0.0:8042->8042/tcp
resourcemanager   hadoop-environment-resourcemanager   Up 59 minutes (healthy)   0.0.0.0:8089->8088/tcp
datanode2         hadoop-environment-datanode2         Up 59 minutes (healthy)   9864/tcp
datanode3         hadoop-environment-datanode3         Up 59 minutes (healthy)   9864/tcp
datanode1         hadoop-environment-datanode1         Up 59 minutes (healthy)   9864/tcp
namenode          hadoop-environment-namenode          Up 59 minutes (healthy)   0.0.0.0:8020->8020/tcp, 0.0.0.0:9870->9870/tcp
```

### Paso 7 — Prueba funcional en HDFS

El archivo [`registro_grupo03.txt`](hadoop-environment/data/registro_grupo03.txt) se colocó en la
carpeta local `data/`, que el `namenode` monta en `/hadoop-data/input`.

```bash
docker exec -it namenode bash
hdfs dfs -mkdir -p /grupo03/lg14                                          # crear directorio
hdfs dfs -put /hadoop-data/input/registro_grupo03.txt /grupo03/lg14/      # cargar archivo
hdfs dfs -ls /grupo03/lg14                                                # consultar
hdfs dfs -cat /grupo03/lg14/registro_grupo03.txt                          # leer
hdfs fsck /grupo03/lg14/registro_grupo03.txt -files -blocks -locations    # bloques y réplicas
```

Los mismos comandos están en [`scripts/prueba_hdfs.sh`](scripts/prueba_hdfs.sh).

---

## 5. Resultados

### Estado del clúster

`hdfs dfsadmin -report` ([`08_hdfs_dfsadmin_report.txt`](evidencias/salidas/08_hdfs_dfsadmin_report.txt))
muestra **3 DataNodes vivos** (`Live datanodes (3)`), sin bloques perdidos, corruptos ni subreplicados.
La interfaz web del NameNode lo confirma:

![Overview del NameNode](evidencias/capturas/01_namenode_overview.png)

![DataNodes en operación](evidencias/capturas/02_namenode_datanodes.png)

### Prueba funcional HDFS

**Directorio y archivo creados** ([`09_hdfs_ls_grupo03.txt`](evidencias/salidas/09_hdfs_ls_grupo03.txt)):

```text
drwxr-xr-x   - root supergroup          0 2026-10-11 17:29 /grupo03/lg14
-rw-r--r--   3 root supergroup        106 2026-10-11 17:29 /grupo03/lg14/registro_grupo03.txt
```

**Lectura desde HDFS** ([`10_hdfs_cat_registro.txt`](evidencias/salidas/10_hdfs_cat_registro.txt)):

```text
Grupo 03 - LG14
Prueba funcional de HDFS con hadoop-environment
Integrantes: Pantoja, Antezana, Escalera
```

**Bloques y réplicas** ([`11_hdfs_fsck_registro.txt`](evidencias/salidas/11_hdfs_fsck_registro.txt), resumido y con el DataNode de cada IP anotado):

```text
/grupo03/lg14/registro_grupo03.txt 106 bytes, replicated: replication=3, 1 block(s):  OK
0. BP-1669953691-172.21.0.2-1791738892917:blk_1073741832_1008 len=106 Live_repl=3
   [DatanodeInfoWithStorage[172.21.0.3:9866,...,DISK],   <- datanode1
    DatanodeInfoWithStorage[172.21.0.5:9866,...,DISK],   <- datanode3
    DatanodeInfoWithStorage[172.21.0.4:9866,...,DISK]]   <- datanode2
Status: HEALTHY
```

![Archivo en el explorador de HDFS](evidencias/capturas/03_hdfs_explorer_grupo03.png)

### Interpretación

- El archivo de 106 bytes ocupa **1 bloque**, porque es mucho más chico que el tamaño de bloque (128 MB).
- El bloque tiene **3 réplicas vivas**, una en cada DataNode (las IPs coinciden con
  [`04_red_hadoop_network.txt`](evidencias/salidas/04_red_hadoop_network.txt)). Así se comprueba que el
  almacenamiento está distribuido.
- El factor de replicación es 3 porque `hdfs-site.xml` no lo define y Hadoop usa su valor por defecto.
- El NameNode solo guarda los metadatos (nombre, bloque, ubicaciones); el contenido está en los DataNodes.
- YARN tiene **1 NodeManager** activo ([`12_yarn_nodos.txt`](evidencias/salidas/12_yarn_nodos.txt)),
  con los 16 GB y 8 vCores que declara `yarn-site.xml`:

![Nodos de YARN](evidencias/capturas/04_yarn_resourcemanager_nodes.png)

---

## 6. Comparación con big-data-europe/docker-hadoop

| Característica | docker-hadoop | hadoop-environment (seleccionado) |
|---|---|---|
| Tecnología principal | Hadoop 3.2.1 (HDFS + YARN + MapReduce) | Hadoop 3.3.6 (HDFS + YARN + MapReduce) |
| Docker | Sí, imágenes ya publicadas en Docker Hub (`bde2020/hadoop-*`, Java 8) | Sí, imágenes **construidas localmente** desde una base propia (`hadoop-base:3.3.6`, Java 11) |
| Docker Compose | Sí (`docker-compose.yml`; además `docker-compose-v3.yml` para Docker Swarm) | Sí (`docker-compose.yml` con `build:` por servicio) |
| Número de contenedores | 5: namenode, datanode, resourcemanager, nodemanager, historyserver | 7: namenode, 3 datanodes, resourcemanager, nodemanager1, historyserver |
| Almacenamiento distribuido | HDFS con **1 DataNode**: los datos no se reparten entre nodos | HDFS con **3 DataNodes**: cada bloque se replica en los tres |
| Procesamiento distribuido | YARN con 1 NodeManager | YARN con 1 NodeManager |
| Interfaces web | NameNode 9870 publicado en el host; el resto (8088, 8042, 8188, 9864) se accede por la IP del contenedor | NameNode 9870, ResourceManager 8089, NodeManager 8042 e History Server 8188 publicados en `localhost` |
| Persistencia | 3 volúmenes con nombre (namenode, datanode, historyserver) | 5 volúmenes con nombre (namenode, 3 datanodes, historyserver) + bind mounts `./data` y `./map_reduce` |
| Configuración | Variables de entorno en `hadoop.env` (`CORE_CONF_*`, `HDFS_CONF_*`), que un script convierte en XML | Archivos XML en `conf/` copiados a la imagen |
| Orden de arranque | `SERVICE_PRECONDITION`: cada servicio espera a que respondan los puertos de los que depende | `depends_on` (solo orden de arranque) + `restart: on-failure` en el ResourceManager + `HEALTHCHECK` |
| Complejidad de instalación | Baja: `docker compose up` descarga imágenes listas | Media: crear la red externa, construir la imagen base y luego el Compose. Además hubo que **corregir el `Dockerfile`** porque sus imágenes base cambiaron |
| Documentación | README breve: arranque, URLs de las interfaces y cómo configurar con variables de entorno | README tipo tutorial que repite el `Dockerfile` y el Compose, sin explicar pruebas ni configuración. Sin archivo `LICENSE` |
| Popularidad | ~2 300 estrellas, ~1 400 forks | 5 estrellas, 0 forks |
| Caso de uso | Imágenes base reutilizables: la organización las usa como base de otros proyectos (por ejemplo, `docker-hive`) | Laboratorio local para aprender cómo se reparte un clúster multinodo y ejecutar MapReduce |

**Diferencias principales.** Los dos siguen el mismo modelo, un demonio de Hadoop por contenedor, pero
con propósitos distintos. `docker-hadoop` prioriza la facilidad: imágenes listas y configuración
mediante variables, aunque con un solo DataNode, que no permite ver la replicación real. `hadoop-environment`
prioriza parecerse a un clúster real: tres DataNodes, versión más nueva de Hadoop y todas las interfaces
web publicadas. A cambio, exige construir las imágenes y depende de imágenes base externas que cambian
con el tiempo, como se vio al tener que corregir el `Dockerfile`.

---

## 7. Problemas encontrados y soluciones

| Problema | Causa | Solución |
|---|---|---|
| El build no puede descargar `openjdk:11-jdk` | La imagen `openjdk` fue retirada de Docker Hub | Usar `eclipse-temurin:11-jdk` y copiar Java desde `/opt/java/openjdk` |
| `apt-get` no encuentra el paquete `software-properties-common` | `python:3.11` pasó a Debian 13 (trixie), que ya no lo incluye | Fijar `python:3.11-bookworm` (Debian 12) |
| Riesgo de `/bin/bash^M: bad interpreter` en los `run.sh` | Git para Windows convierte los finales de línea a CRLF | Clonar con `-c core.autocrlf=false`; en este repo, `.gitattributes` fuerza LF en `*.sh` |
| `failed to read dockerfile: open Dockerfile` | `docker build` se ejecutó fuera de la carpeta del repositorio clonado | Ejecutar los comandos de Docker dentro de `hadoop-environment` |
| Aviso `the attribute version is obsolete` | Compose v2+ ya no usa el campo `version` | Solo es una advertencia; no afecta el despliegue |
| Aviso `HADOOP_PREFIX has been replaced by HADOOP_HOME` | El `Dockerfile` define la variable antigua `HADOOP_PREFIX` | Solo es una advertencia; Hadoop usa el mismo valor |
| `java: command not found` dentro del contenedor | El `Dockerfile` define `JAVA_HOME`, pero no agrega `$JAVA_HOME/bin` al `PATH` | Hadoop usa `JAVA_HOME` y funciona igual; para ver la versión se usa `$JAVA_HOME/bin/java -version` |
