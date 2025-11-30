#!/bin/bash

SPARK_WORKLOAD=$1

echo "Starting Spark: $SPARK_WORKLOAD"

if [ "$SPARK_WORKLOAD" == "master" ]; then
    /opt/spark/sbin/start-master.sh 
elif [ "$SPARK_WORKLOAD" == "worker" ]; then
    /opt/spark/sbin/start-worker.sh "$2"
elif [ "$SPARK_WORKLOAD" == "history-server" ]; then
    /opt/spark/sbin/start-history-server.sh 
else
    exit 1
fi