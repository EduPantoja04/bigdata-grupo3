#!/bin/bash
set -eu
cat > /tmp/ventas-grupo3.txt << 'EOF'
id,producto,cantidad
1,cafe,10
2,cacao,4
3,panela,7
EOF
hdfs dfs -mkdir -p /user/grupo3/prueba
hdfs dfs -put -f /tmp/ventas-grupo3.txt /user/grupo3/prueba/ventas-grupo3.txt
echo "=== ls ==="
hdfs dfs -ls /user/grupo3/prueba
echo "=== cat ==="
hdfs dfs -cat /user/grupo3/prueba/ventas-grupo3.txt
