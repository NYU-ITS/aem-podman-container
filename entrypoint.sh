#!/usr/bin/env bash
set -euo pipefail

AEM_HOME="/opt/aem"
QUICKSTART_JAR="${AEM_HOME}/aem.jar"

echo "Starting AEM"
echo "Run mode: ${AEM_RUN_MODE}"
echo "Content mode: ${AEM_CONTENT_TYPE}"
echo "Port: ${AEM_PORT}"

cd "${AEM_HOME}"

exec java ${JAVA_OPTS:-} \
    -Dsling.run.modes="${AEM_RUN_MODE},${AEM_CONTENT_TYPE}" \
    -jar "${QUICKSTART_JAR}" \
    -p "${AEM_PORT}" \
    -nofork