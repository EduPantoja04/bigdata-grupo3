# Manual de comandos — LG14 (Grupo 03)

Este manual recorre, en orden, **todos los comandos y acciones** que se realizaron en la práctica.
Para cada paso indica **dónde se ejecuta**, **qué hace** y **qué resultado se espera**, para poder
reproducirlo y explicarlo durante la defensa.

## Cómo leer este manual

Cada comando indica dónde se ejecuta con un prompt de ejemplo. Hay cuatro lugares posibles:

| Prompt | Dónde se ejecuta |
|---|---|
| `PS C:\Users\edupa\source>` | PowerShell en Windows (terminal de Cursor, `` Ctrl+` ``), en la carpeta indicada |
| `PS ...\hadoop-environment>` | PowerShell dentro del **repositorio investigado** (clonado de GitHub) |
| `PS ...\bigdata-grupo3>` | PowerShell dentro del **repositorio de entrega** del grupo |
| `root@<id>:/#` | Bash **dentro del contenedor `namenode`** (después de `docker exec -it namenode bash`) |

Se trabaja con **dos carpetas distintas**, y conviene no mezclarlas:

| Carpeta | Qué es | Para qué se usa |
|---|---|---|
| `C:\Users\edupa\source\hadoop-environment` | Clon del repositorio investigado | Construir y levantar el clúster: todos los comandos `docker` |
| `C:\Users\edupa\source\bigdata-grupo3` | Repositorio propio de entrega | Guardar configuración, evidencias y documentación; hacer commits |

> Si `docker build` responde `failed to read dockerfile: open Dockerfile: no such file or directory`,
> el comando se ejecutó en la carpeta equivocada. Debe correrse en `hadoop-environment`.

---

## Fase 0 — Requisitos previos

### 0.1 Verificar Docker y Docker Compose

```powershell
PS C:\Users\edupa\source> docker --version
PS C:\Users\edupa\source> docker compose version
```

- **Para qué:** confirmar que Docker Desktop está instalado y corriendo, y que hay Compose v2 o superior
  (comando `docker compose`, con espacio).
- **Resultado esperado:** `Docker version 29.6.1 ...` y `Docker Compose version v5.3.0`.

### 0.2 Verificar Git

```powershell
PS C:\Users\edupa\source> git --version
```

- **Para qué:** Git se usa para clonar el repositorio investigado y para versionar la entrega.

---

## Fase 1 — Preparar el repositorio de entrega (rama nueva desde cero)

### 1.1 Entrar al repositorio de entrega y traer los cambios remotos

```powershell
PS C:\Users\edupa\source> cd C:\Users\edupa\source\bigdata-grupo3
PS C:\Users\edupa\source\bigdata-grupo3> git fetch origin
```

- **Para qué:** `git fetch` descarga el estado actual de GitHub sin modificar los archivos locales.

### 1.2 Crear una rama huérfana

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> git switch --orphan lg14
PS C:\Users\edupa\source\bigdata-grupo3> Get-ChildItem -Force
```

- **Para qué:** `--orphan` crea una rama **sin historial previo**. Así el trabajo de LG14 empieza
  desde cero y no arrastra el intento anterior.
- **Resultado esperado:** la carpeta queda vacía, salvo `.git`.

### 1.3 Crear los archivos base y hacer el primer commit

Se crean con el editor `REGISTRO.txt` (registro del repositorio elegido), `README.md` y `.gitignore`.

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> git add .
PS C:\Users\edupa\source\bigdata-grupo3> git commit -m "Registrar hadoop-environment como repositorio del grupo 3"
```

- **Para qué:** dejar evidencia del primer avance. La guía exige al menos 3 commits.

---

## Fase 2 — Pasos 1 a 4 de la guía: clonar y analizar el repositorio

### 2.1 Paso 1 — Clonar el repositorio investigado

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> cd C:\Users\edupa\source
PS C:\Users\edupa\source> git clone -c core.autocrlf=false https://github.com/spraharaj-projects/hadoop-environment.git
```

- **Dónde:** en `C:\Users\edupa\source`, **fuera** del repositorio de entrega, para no meter un
  repositorio Git dentro de otro.
- **Por qué `-c core.autocrlf=false`:** Git para Windows convierte por defecto los saltos de línea a
  formato Windows (CRLF). Los `run.sh` se ejecutan dentro de contenedores Linux, y con CRLF fallan con
  `/bin/bash^M: bad interpreter`. Esta opción mantiene los archivos tal como están en GitHub (LF).

### 2.2 Paso 2 — Ingresar al directorio

```powershell
PS C:\Users\edupa\source> cd hadoop-environment
```

### 2.3 Paso 3 — Identificar los archivos principales

```powershell
PS C:\Users\edupa\source\hadoop-environment> Get-ChildItem -Force
```

- **Para qué:** es el equivalente en PowerShell de `ls -la`: lista todos los archivos, incluidos los
  ocultos como `.git`. En Git Bash se puede usar literalmente `ls -la`.
- **Qué se debe identificar:** `docker-compose.yml`, el `Dockerfile` base, la carpeta `conf/` con los
  XML de Hadoop y una carpeta por servicio (`namenode/`, `datanode/`, `resourcemanager/`,
  `nodemanager/`, `historyserver/`), cada una con su `Dockerfile` y su `run.sh`.

### 2.4 Paso 4 — Analizar el archivo de Docker Compose

```powershell
PS C:\Users\edupa\source\hadoop-environment> Get-Content docker-compose.yml
```

- **Para qué:** equivale a `cat docker-compose.yml`. Muestra los 7 servicios, sus puertos, volúmenes,
  la red `hadoop_network` y las dependencias (`depends_on`).
- **Puntos para explicar:** la red es `external: true` (hay que crearla a mano) y cada servicio usa
  `build:`, es decir, las imágenes se construyen localmente en lugar de descargarse.

Para revisar la configuración de Hadoop:

```powershell
PS C:\Users\edupa\source\hadoop-environment> Get-Content conf\core-site.xml
PS C:\Users\edupa\source\hadoop-environment> Get-Content conf\hdfs-site.xml
```

- **Qué se debe notar:** `fs.defaultFS = hdfs://namenode:8020` indica dónde está el NameNode.
  `hdfs-site.xml` **no define** `dfs.replication`, así que HDFS usa el valor por defecto, 3.

---

## Fase 3 — Corregir el `Dockerfile` base

El repositorio publicado **no compila**, porque dos imágenes base cambiaron desde 2024. Se edita el
archivo `C:\Users\edupa\source\hadoop-environment\Dockerfile` **con el editor** y se cambian tres líneas:

| Línea original | Línea corregida | Motivo |
|---|---|---|
| `FROM openjdk:11-jdk AS jdk` | `FROM eclipse-temurin:11-jdk AS jdk` | La imagen `openjdk` fue retirada de Docker Hub |
| `FROM python:3.11` | `FROM python:3.11-bookworm` | `python:3.11` pasó a Debian 13, que ya no tiene `software-properties-common` |
| `COPY --from=jdk $JAVA_HOME $JAVA_HOME` | `COPY --from=jdk /opt/java/openjdk $JAVA_HOME` | En la imagen Temurin, Java está en `/opt/java/openjdk` |

Para comprobar los cambios:

```powershell
PS C:\Users\edupa\source\hadoop-environment> git diff Dockerfile
```

- **Para qué:** `git diff` muestra exactamente qué líneas se cambiaron respecto al original. Es una
  buena evidencia para la defensa.

---

## Fase 4 — Pasos 5 y 6 de la guía: construir, ejecutar y verificar

### 4.1 Crear la red Docker

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker network create hadoop_network
```

- **Para qué:** el Compose declara la red como externa, así que no la crea; si no existe, `docker compose up`
  falla. Por esta red los contenedores se encuentran por nombre (`namenode`, `resourcemanager`).
- **Se ejecuta una sola vez.** Si se repite, responde `network with name hadoop_network already exists`,
  que no es un problema.

### 4.2 Construir la imagen base

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker build -t hadoop-base:3.3.6 .
```

- **Para qué:** construye la imagen `hadoop-base:3.3.6` con Debian 12, Java 11, Hadoop 3.3.6 y la
  configuración de `conf/`. El punto final (`.`) indica que el contexto de construcción es la carpeta
  actual, por eso tiene que ejecutarse en `hadoop-environment`.
- **Duración:** varios minutos la primera vez, porque descarga Hadoop (~700 MB).
- **Por qué se construye aparte:** los `Dockerfile` de cada servicio empiezan con
  `FROM hadoop-base:3.3.6`, así que esta imagen debe existir antes del Compose.

### 4.3 Levantar el clúster (Paso 5)

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker compose up -d --build
```

- **Para qué:** construye la imagen de cada servicio y crea los 7 contenedores, los volúmenes y los
  puertos. `-d` los deja corriendo en segundo plano.
- **Aviso esperado:** `the attribute version is obsolete`. Es solo una advertencia de Compose y no afecta.
- No se usa el `start-cluster.sh` del repositorio, porque llama a `docker-compose`, el comando antiguo
  de Compose v1.

### 4.4 Verificar los contenedores (Paso 6)

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker ps
PS C:\Users\edupa\source\hadoop-environment> docker compose ps
```

- **Resultado esperado:** 7 contenedores en estado `Up (healthy)`: `namenode`, `datanode1`,
  `datanode2`, `datanode3`, `resourcemanager`, `nodemanager1` e `historyserver`.
- **Qué significa `healthy`:** cada imagen tiene un `HEALTHCHECK` que consulta con `curl` su puerto web.
  Si responde, Docker marca el contenedor como sano.

### 4.5 Revisar la red, los volúmenes y los logs

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker network inspect hadoop_network
PS C:\Users\edupa\source\hadoop-environment> docker volume ls --filter name=hadoop
PS C:\Users\edupa\source\hadoop-environment> docker logs namenode
```

- `network inspect` muestra la IP de cada contenedor dentro de la red (172.21.0.x).
- `volume ls` muestra los 5 volúmenes donde se guardan los metadatos y los bloques de HDFS.
- `docker logs` sirve para diagnosticar si algún contenedor no arranca.

### 4.6 Verificar en el navegador

| URL | Qué muestra |
|---|---|
| http://localhost:9870 | NameNode. En la pestaña **Datanodes** deben aparecer 3 nodos *In service* |
| http://localhost:8089 | ResourceManager de YARN (el 8088 del contenedor se publica como 8089) |
| http://localhost:8042 | NodeManager |
| http://localhost:8188 | Historial de aplicaciones |

### 4.7 Verificar HDFS desde la línea de comandos

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker exec namenode hdfs dfsadmin -report
```

- **Para qué:** `docker exec` ejecuta un comando dentro de un contenedor que ya está corriendo, aquí el
  `namenode`. `dfsadmin -report` pide al NameNode el estado del sistema de archivos.
- **Resultado esperado:** `Live datanodes (3)`, y 0 en `Missing blocks` y `Under replicated blocks`.
- **Aviso esperado:** `WARNING: HADOOP_PREFIX has been replaced by HADOOP_HOME`. El `Dockerfile` usa
  el nombre antiguo de la variable; es solo una advertencia.

---

## Fase 5 — Paso 7 de la guía: prueba funcional en HDFS

### 5.1 Crear el archivo de prueba (en Windows)

Con el editor se crea `C:\Users\edupa\source\hadoop-environment\data\registro_grupo03.txt`:

```text
Grupo 03 - LG14
Prueba funcional de HDFS con hadoop-environment
Integrantes: Pantoja, Antezana, Escalera
```

- **Por qué en `data\`:** el Compose monta esa carpeta del host dentro del `namenode`, en
  `/hadoop-data/input` (*bind mount*). Lo que se guarda ahí en Windows aparece dentro del contenedor.

### 5.2 Entrar al contenedor `namenode`

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker exec -it namenode bash
```

- **Para qué:** abre una terminal Bash **dentro** del contenedor. `-it` la hace interactiva.
- **Resultado esperado:** el prompt cambia a `root@<id>:/#`. Desde aquí, los comandos se ejecutan en Linux.

### 5.3 Comprobar que el archivo local es visible

```bash
root@<id>:/# ls -l /hadoop-data/input
```

- **Para qué:** verificar que el *bind mount* funciona antes de cargar el archivo. Este `ls` mira el
  disco del contenedor; todavía **no** es HDFS.

### 5.4 Crear el directorio en HDFS

```bash
root@<id>:/# hdfs dfs -mkdir -p /grupo03/lg14
```

- **Para qué:** crea el directorio dentro de HDFS. `-p` crea también los directorios padre si no existen.
- **Resultado esperado:** ninguna salida. En HDFS, si no hay mensaje, el comando funcionó.
- **Qué ocurre por dentro:** solo interviene el NameNode, que registra el directorio en sus metadatos.
  Todavía no se escribe nada en los DataNodes.

### 5.5 Cargar el archivo a HDFS

```bash
root@<id>:/# hdfs dfs -put /hadoop-data/input/registro_grupo03.txt /grupo03/lg14/
```

- **Para qué:** copia el archivo del disco del contenedor a HDFS.
- **Qué ocurre por dentro:** el cliente pide al NameNode dónde escribir; el NameNode elige 3 DataNodes
  (factor de replicación 3); el cliente envía el bloque al primero, y este lo reenvía al segundo y al
  tercero (*pipeline* de replicación).
- **Resultado esperado:** ninguna salida, o una línea `INFO sasl.SaslDataTransferClient`, que es solo
  informativa.

### 5.6 Consultar el archivo almacenado

```bash
root@<id>:/# hdfs dfs -ls /grupo03/lg14
```

- **Resultado esperado:**

  ```text
  Found 1 items
  -rw-r--r--   3 root supergroup        106 2026-10-11 17:29 /grupo03/lg14/registro_grupo03.txt
  ```

- **Cómo leerlo:** el `3` después de los permisos es el factor de replicación; `106` es el tamaño en
  bytes. La hora está en UTC.

### 5.7 Leer el archivo desde HDFS

```bash
root@<id>:/# hdfs dfs -cat /grupo03/lg14/registro_grupo03.txt
```

- **Para qué:** demuestra que el archivo se puede recuperar. El NameNode indica dónde están los bloques
  y el cliente los lee directamente de un DataNode.
- **Resultado esperado:** el mismo texto del archivo original.

### 5.8 Ver bloques y ubicación de las réplicas

```bash
root@<id>:/# hdfs fsck /grupo03/lg14/registro_grupo03.txt -files -blocks -locations
```

- **Para qué:** `fsck` revisa la salud del archivo y muestra en qué DataNodes está cada bloque.
- **Resultado esperado:** `1 block(s)`, `Live_repl=3`, tres direcciones `DatanodeInfoWithStorage[172.21.0.x:9866...]`
  y `Status: HEALTHY`.
- **Cómo interpretarlo:** el archivo ocupa un solo bloque porque es mucho más chico que el tamaño de
  bloque (128 MB). Ese bloque tiene una copia en cada uno de los 3 DataNodes: eso es el almacenamiento
  distribuido.

### 5.9 Salir del contenedor

```bash
root@<id>:/# exit
```

- El prompt vuelve a `PS ...\hadoop-environment>`.

### 5.10 Verificar la prueba en la web

En http://localhost:9870 se abre **Utilities → Browse the file system** y se navega a `/grupo03/lg14`.
Debe aparecer `registro_grupo03.txt` con *Replication* 3 y *Block Size* 128 MB.

---

## Fase 6 — Guardar evidencias

### 6.1 Guardar salidas de comandos en archivos

```powershell
PS C:\Users\edupa\source\hadoop-environment> docker exec namenode hdfs dfsadmin -report | Out-File -Encoding utf8 C:\Users\edupa\source\bigdata-grupo3\evidencias\salidas\08_hdfs_dfsadmin_report.txt
```

- **Por qué `Out-File -Encoding utf8` y no `>`:** en Windows PowerShell 5.1, `>` guarda en UTF-16 y
  GitHub muestra el archivo con caracteres raros.
- Para generar las 12 evidencias de una vez se usa el script del grupo:

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> .\scripts\capturar_evidencias.ps1
```

- Si PowerShell bloquea el script por la política de ejecución, se puede correr con
  `powershell -ExecutionPolicy Bypass -File .\scripts\capturar_evidencias.ps1`.

### 6.2 Capturas de pantalla

Se guardan en `C:\Users\edupa\source\bigdata-grupo3\evidencias\capturas\`:

- Terminal con `git clone`, `Get-ChildItem -Force` y `Get-Content docker-compose.yml` (Pasos 1 a 4).
- Terminal con `docker ps` mostrando los 7 contenedores (Paso 6).
- Terminal con `mkdir`, `put`, `ls`, `cat` y `fsck` (Paso 7).
- Interfaz web del NameNode: *Overview*, *Datanodes* y el explorador en `/grupo03/lg14`.
- Interfaz web de YARN: nodos del clúster.

---

## Fase 7 — Llevar la configuración al repositorio de entrega

### 7.1 Copiar los archivos usados

```powershell
PS C:\Users\edupa\source> $src = "C:\Users\edupa\source\hadoop-environment"
PS C:\Users\edupa\source> $dst = "C:\Users\edupa\source\bigdata-grupo3\hadoop-environment"
PS C:\Users\edupa\source> New-Item -ItemType Directory -Force "$dst\conf", "$dst\data"
PS C:\Users\edupa\source> Copy-Item "$src\docker-compose.yml", "$src\Dockerfile" $dst
PS C:\Users\edupa\source> Copy-Item "$src\conf\*" "$dst\conf"
PS C:\Users\edupa\source> foreach ($s in "namenode","datanode","resourcemanager","nodemanager","historyserver") { New-Item -ItemType Directory -Force "$dst\$s"; Copy-Item "$src\$s\Dockerfile", "$src\$s\run.sh" "$dst\$s" }
PS C:\Users\edupa\source> Copy-Item "$src\data\registro_grupo03.txt" "$dst\data"
```

- **Para qué:** la guía pide que el repositorio de entrega contenga los archivos de configuración
  usados (`docker-compose.yml`, `Dockerfile`, etc.). Se copia la versión **corregida** del `Dockerfile`.
- El archivo `.gitattributes` de la raíz obliga a que los `.sh` se guarden con LF, para que funcionen
  aunque alguien clone el repositorio en Windows.

### 7.2 Desplegar desde el repositorio de entrega (alternativa)

Con los archivos ya copiados, el clúster también puede levantarse desde aquí:

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> .\scripts\despliegue.ps1
```

---

## Fase 8 — Commits y entrega

### 8.1 Revisar qué cambió

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> git status
```

### 8.2 Commits por etapa (mínimo 3 en total)

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> git add .gitattributes hadoop-environment scripts
PS C:\Users\edupa\source\bigdata-grupo3> git commit -m "Agregar configuración del clúster con correcciones de imagen base"

PS C:\Users\edupa\source\bigdata-grupo3> git add evidencias
PS C:\Users\edupa\source\bigdata-grupo3> git commit -m "Agregar evidencias del despliegue y prueba HDFS"

PS C:\Users\edupa\source\bigdata-grupo3> git add README.md docs REGISTRO.txt
PS C:\Users\edupa\source\bigdata-grupo3> git commit -m "Documentar arquitectura, manual y comparación con docker-hadoop"
```

- **Para qué:** cada commit muestra una etapa del trabajo. El docente revisa el historial para ver el avance.

### 8.3 Subir la rama a GitHub

```powershell
PS C:\Users\edupa\source\bigdata-grupo3> git push -u origin lg14
```

- `-u` vincula la rama local con la remota; después basta con `git push`.

### 8.4 Poner `lg14` como rama por defecto

En GitHub: **Settings → General → Default branch → `lg14`**.

- **Para qué:** el docente abre la URL del repositorio y ve la rama por defecto. Si sigue siendo `main`,
  verá el intento anterior.

---

## Fase 9 — Detener y limpiar el clúster

Todos estos comandos se ejecutan en `C:\Users\edupa\source\hadoop-environment`.

| Comando | Qué hace | ¿Se pierden los datos de HDFS? |
|---|---|---|
| `docker compose stop` | Detiene los contenedores sin borrarlos | No |
| `docker compose start` | Vuelve a arrancar los contenedores detenidos | No |
| `docker compose down` | Borra los contenedores (la red externa se mantiene) | No, quedan en los volúmenes |
| `docker compose down -v` | Borra los contenedores **y los volúmenes** | **Sí**, HDFS queda vacío |

> **No ejecutar `docker compose down -v` antes de la defensa ni antes de LG15**, porque borra los
> archivos cargados en HDFS.

---

## Resumen: qué comando va en qué lugar

| Acción | Dónde |
|---|---|
| `git switch --orphan`, `git add`, `git commit`, `git push` | PowerShell en `bigdata-grupo3` |
| `git clone` | PowerShell en `C:\Users\edupa\source` |
| `Get-ChildItem -Force`, `Get-Content docker-compose.yml`, editar `Dockerfile` | PowerShell / editor en `hadoop-environment` |
| `docker network create`, `docker build`, `docker compose up`, `docker ps` | PowerShell en `hadoop-environment` |
| `docker exec namenode hdfs ...` (comando suelto) | PowerShell en cualquier carpeta |
| `hdfs dfs -mkdir`, `-put`, `-ls`, `-cat`, `hdfs fsck` | Bash **dentro** del `namenode` |
| Crear `registro_grupo03.txt` | Editor, en `hadoop-environment\data\` |
| Copiar configuración y evidencias | PowerShell, de `hadoop-environment` a `bigdata-grupo3` |

---

## Preguntas frecuentes para la defensa

**¿Por qué hay que crear la red a mano?**
Porque el `docker-compose.yml` la declara como `external: true`. Compose espera que ya exista y no la crea.

**¿Por qué se construye `hadoop-base` antes del Compose?**
Porque los `Dockerfile` de cada servicio empiezan con `FROM hadoop-base:3.3.6`. Sin esa imagen, el build
de los servicios falla.

**¿Qué diferencia hay entre `docker exec namenode hdfs dfs -ls /` y entrar con `docker exec -it namenode bash`?**
El primero ejecuta un solo comando y vuelve a PowerShell. El segundo abre una terminal dentro del
contenedor para ejecutar varios comandos seguidos.

**¿Por qué el archivo tiene replicación 3?**
Porque `hdfs-site.xml` no define `dfs.replication` y Hadoop usa su valor por defecto, 3. Con 3 DataNodes,
cada bloque queda copiado en los tres.

**¿El archivo está guardado en el NameNode?**
No. El NameNode solo guarda los metadatos: nombre, bloques y en qué DataNodes está cada bloque. Los datos
están en los DataNodes, en los volúmenes `hadoop_datanode1`, `hadoop_datanode2` y `hadoop_datanode3`.

**¿Por qué el archivo ocupa un solo bloque?**
Porque mide 106 bytes y el tamaño de bloque por defecto es 128 MB. Un archivo se divide en bloques solo
cuando supera ese tamaño.

**¿Qué tuvieron que corregir y por qué?**
Tres líneas del `Dockerfile` base. La imagen `openjdk` fue retirada de Docker Hub, y `python:3.11` cambió
a Debian 13, que ya no tiene un paquete que el `Dockerfile` instala. Se reemplazaron por
`eclipse-temurin:11-jdk` y `python:3.11-bookworm`, y se ajustó la ruta desde donde se copia Java.

**¿Qué pasa con los datos si se apagan los contenedores?**
Se conservan, porque HDFS guarda metadatos y bloques en volúmenes Docker con nombre. Solo se pierden con
`docker compose down -v`.
