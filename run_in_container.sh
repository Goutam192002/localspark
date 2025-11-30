#!/bin/bash
# Run a Spark Python script in a Docker container
# This ensures the driver runs in the same environment as the workers.
#
# Usage: ./run_in_container.sh <script_file>
# Example: ./run_in_container.sh test_spark.py

if [ $# -eq 0 ]; then
    echo "Error: No script file provided"
    echo "Usage: $0 <script_file>"
    echo "Example: $0 test_spark.py"
    exit 1
fi

SCRIPT_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_FILE}"

# Check if script file exists
if [ ! -f "${SCRIPT_PATH}" ]; then
    echo "Error: Script file '${SCRIPT_FILE}' not found in ${SCRIPT_DIR}"
    exit 1
fi

docker-compose run --rm \
  --entrypoint="" \
  -v "${SCRIPT_DIR}:/workspace" \
  -w /workspace \
  spark-master \
  /opt/spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    "/workspace/${SCRIPT_FILE}"

