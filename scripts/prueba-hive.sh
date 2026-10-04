#!/bin/bash
set -eu
/opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -n root --silent=true --showHeader=true --outputformat=table -e "
CREATE EXTERNAL TABLE IF NOT EXISTS ventas_grupo3 (
  id INT,
  producto STRING,
  cantidad INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/grupo3/prueba'
TBLPROPERTIES ('skip.header.line.count'='1');
SELECT * FROM ventas_grupo3;
"
