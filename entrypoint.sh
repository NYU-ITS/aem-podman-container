#!/usr/bin/env bash
set -euo pipefail

AEM_HOME="/opt/aem"
QUICKSTART_DIR="${AEM_HOME}/crx-quickstart"

echo "Starting AEM"
echo "Run mode: ${AEM_RUN_MODE}"
echo "Port: ${AEM_PORT}"
echo "Quickstart: ${QUICKSTART_DIR}"

if [ ! -d "${QUICKSTART_DIR}/repository" ]; then
    echo "ERROR: Warmed AEM repository is missing."
    exit 1
fi

if [ ! -d "${QUICKSTART_DIR}/launchpad" ]; then
    echo "ERROR: Warmed AEM launchpad is missing."
    exit 1
fi

cd "${AEM_HOME}"

exec java ${JAVA_OPTS:-} \
    -Dsling.run.modes="${AEM_RUN_MODE},${AEM_CONTENT_TYPE}" \
    -jar "${AEM_HOME}/aem.jar" \
    -p "${AEM_PORT}" \
    -nofork