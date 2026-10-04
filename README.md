# LG14 — Investigación y despliegue de un repositorio Big Data con Docker

Grupo 3. Cuenta de entrega: [EduPantoja04](https://github.com/EduPantoja04).

Este repositorio documenta el análisis, el despliegue y la prueba funcional de un proyecto público de Big Data. No es un fork ni una copia renombrada de ese proyecto: el código que se ejecuta sigue viviendo en el repositorio original.

## Registro del repositorio analizado

| Campo | Valor |
| --- | --- |
| Estudiantes | Grupo 3 (completar nombres completos antes de enviarlo por Teams) |
| Repositorio | docker-hive |
| URL | https://github.com/big-data-europe/docker-hive |
| Autor / organización | Big Data Europe |
| Descripción | Entorno Docker Compose para Apache Hive 2.3.2 sobre HDFS, con metastore en PostgreSQL. |

Texto listo para pegar en el registro del curso:

```text
Nombre de los estudiantes: Grupo 3
Nombre del repositorio: docker-hive
URL: https://github.com/big-data-europe/docker-hive
Autor/organización: Big Data Europe
Descripción en una línea: Entorno Docker Compose para Apache Hive 2.3.2 sobre HDFS, con metastore en PostgreSQL.
```

## Por qué este repositorio y no Trino

[bitsondatadev/trino-getting-started](https://github.com/bitsondatadev/trino-getting-started) sí es Big Data y sí usa Docker Compose, pero no encaja bien con esta guía:

- No hay un único `docker-compose.yml` en la raíz. Son varios tutoriales y hay que entrar a un subdirectorio.
- La prueba obligatoria de la guía pide operaciones de HDFS: crear un directorio, cargar un archivo y consultarlo. Trino no almacena los datos; los consulta en otra fuente.
- Parte de los tutoriales se movió a `community-tutorials/` y el propio README advierte que pueden estar desactualizados.

`docker-hive` cumple las condiciones y deja una comparación real con [big-data-europe/docker-hadoop](https://github.com/big-data-europe/docker-hadoop). Son repositorios distintos: Hive reutiliza las imágenes Hadoop de esa organización, pero despliega un almacén SQL (HiveServer2, metastore y PostgreSQL) y no el clúster YARN del repositorio de referencia.

## 1. Información general

Datos tomados de la API de GitHub y del commit clonado para la práctica (`502fa269fe1913737ecfa0ef6ea05adb48b33868`, 6 de mayo de 2019).

| Campo | docker-hive |
| --- | --- |
| Nombre | docker-hive |
| Autor / organización | Big Data Europe |
| URL | https://github.com/big-data-europe/docker-hive |
| Fecha de creación | 20 de mayo de 2016 |
| Último commit en `master` | 6 de mayo de 2019 |
| Última actividad visible en GitHub | 29 de septiembre de 2026 (metadatos; el código de `master` no cambió en ese commit) |
| Estrellas | 1081 |
| Forks | 564 |
| Licencia | No declarada en el repositorio |
| Objetivo | Levantar Apache Hive 2.3.2 con HiveServer2 y un metastore respaldado por PostgreSQL, usando HDFS como sistema de archivos. |

## 2. Tecnologías

| Tecnología | Versión / detalle |
| --- | --- |
| Tecnología Big Data principal | Apache Hive, sobre HDFS |
| Hive | 2.3.2 |
| Hadoop | 2.7.4 (imágenes `bde2020/hadoop-namenode` y `bde2020/hadoop-datanode`, etiqueta `2.0.0-hadoop2.7.4-java8`) |
| Docker | Sí. La imagen de Hive parte de `bde2020/hadoop-base:2.0.0-hadoop2.7.4-java8` |
| Docker Compose | Sí. Archivo `docker-compose.yml` en la raíz, `version: "3"` |
| Sistema operativo base | Familia Debian: el `Dockerfile` instala paquetes con `apt-get` sobre la imagen Hadoop base, con Java 8 |
| Base de datos | PostgreSQL para el metastore (`bde2020/hive-metastore-postgresql:2.3.0`). El driver JDBC incluido es PostgreSQL 9.4.1212 |
| Frameworks adicionales | PrestoDB 0.181 (`shawnzhu/prestodb:0.181`), como coordinador opcional de consulta SQL |
| Lenguajes del repositorio | Shell (entrypoint, arranque y Makefile), Dockerfile, XML y properties de configuración. Hive y Hadoop son Java |

Hive no trae un clúster YARN propio. El archivo `hadoop-hive.env` incluye variables `YARN_CONF_*`, pero `docker-compose.yml` no define ResourceManager, NodeManager ni HistoryServer. Esas variables vienen del estilo de configuración de docker-hadoop y en este despliegue no tienen un proceso que las use.
