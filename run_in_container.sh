#!/bin/bash
# Run a Spark Python script in a Docker container
# This ensures the driver runs in the same environment as the workers
# with access to the Hive metastore and Spark cluster.
#
# Usage: ./run_in_container.sh <script_file> [script_args...]
# Example: ./run_in_container.sh test_spark.py --start-date 2024-01-01 --end-date 2024-01-02

set -e

if [ $# -eq 0 ]; then
    echo "Error: No script file provided"
    echo ""
    echo "Usage: $0 <script_file> [script_args...]"
    echo ""
    echo "Examples:"
    echo "  $0 test_spark.py"
    echo "  $0 test_spark.py --start-date 2024-01-01 --end-date 2024-01-02"
    echo ""
    echo "Options:"
    echo "  Set SPARK_LOG_LEVEL=DEBUG for verbose Spark logging"
    echo "  Set PYSPARK_PYTHON=/usr/bin/python3 to change Python version"
    exit 1
fi

SCRIPT_FILE="$1"
shift  # Remove script file from args, remaining are script arguments
SCRIPT_ARGS="$@"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_FILE}"

# Check if script file exists
if [ ! -f "${SCRIPT_PATH}" ]; then
    echo "Error: Script file '${SCRIPT_FILE}' not found in ${SCRIPT_DIR}"
    exit 1
fi

# Default log level (can be overridden: SPARK_LOG_LEVEL=DEBUG ./run_in_container.sh ...)
SPARK_LOG_LEVEL="${SPARK_LOG_LEVEL:-WARN}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Running: ${SCRIPT_FILE}"
echo "📂 Script args: ${SCRIPT_ARGS:-<none>}"
echo "📊 Log level: ${SPARK_LOG_LEVEL}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker-compose run --rm \
  --entrypoint="" \
  -v "${SCRIPT_DIR}:/workspace" \
  -w /workspace \
  -e SPARK_LOG_LEVEL="${SPARK_LOG_LEVEL}" \
  -e SPARK_CONF_DIR=/opt/spark/conf \
  -e HADOOP_CONF_DIR=/opt/spark/conf \
  -e PYTHONUNBUFFERED=1 \
  spark-master \
  /opt/spark/bin/spark-submit \
    --properties-file /opt/spark/conf/spark-defaults.conf \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    "/workspace/${SCRIPT_FILE}" ${SCRIPT_ARGS}

EXIT_CODE=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Script completed successfully"
else
    echo "❌ Script failed with exit code: ${EXIT_CODE}"
fi
echo "📈 View Spark History UI: http://localhost:18080"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $EXIT_CODE
