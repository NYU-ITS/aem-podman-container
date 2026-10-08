#!/usr/bin/env bash
set -euo pipefail

RUN_MODE="${1:?Run mode required}"
PORT="${2:?Port required}"
CONTENT="${3:?Content mode required}"

AEM_HOME="/opt/aem"
QUICKSTART_DIR="${AEM_HOME}/crx-quickstart"
LOG_FILE="${QUICKSTART_DIR}/logs/stdout.log"

MAX_WAIT=1800
INTERVAL=10
ELAPSED=0

cd "${AEM_HOME}"

echo "Warm-booting AEM"
echo "Run mode: ${RUN_MODE}"
echo "Port: ${PORT}"
echo "Content: ${CONTENT}"

java -Xmx4096m \
    -Djava.awt.headless=true \
    -Dsling.run.modes="${RUN_MODE},${CONTENT}" \
    -jar "${AEM_HOME}/aem.jar" \
    -p "${PORT}" \
    -nofork &

AEM_PID=$!

cleanup() {
    if kill -0 "${AEM_PID}" 2>/dev/null; then
        echo "Stopping warm-boot AEM process..."
        kill -TERM "${AEM_PID}" || true
        wait "${AEM_PID}" || true
    fi
}

trap cleanup EXIT

READY=false

while [ "${ELAPSED}" -lt "${MAX_WAIT}" ]; do

    if ! kill -0 "${AEM_PID}" 2>/dev/null; then
        echo "ERROR: AEM exited during warm-boot."
        exit 1
    fi

    HTTP_CODE=$(curl -s \
        -o /dev/null \
        -w "%{http_code}" \
        "http://localhost:${PORT}/libs/granite/core/content/login.html" \
        || true)

    STARTUP_COMPLETE=false

    if grep -q "Startup completed" \
        "${QUICKSTART_DIR}/logs/stdout.log" 2>/dev/null; then

        STARTUP_COMPLETE=true
    fi

    if [ "${HTTP_CODE}" = "200" ] && \
       [ "${STARTUP_COMPLETE}" = true ]; then
        READY=true
        break
    fi

    echo "AEM initializing: ${ELAPSED}s (HTTP ${HTTP_CODE}, startup complete: ${STARTUP_COMPLETE})"

    sleep "${INTERVAL}"
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ "${READY}" != true ]; then
    echo "ERROR: AEM did not complete startup."
    if [ -f "${LOG_FILE}" ]; then
        tail -100 "${LOG_FILE}"
    fi
    exit 1
fi

echo "AEM startup completed."

# Stop AEM and wait for shutdown to finish.
kill -TERM "${AEM_PID}"
wait "${AEM_PID}" || true

trap - EXIT

# Remove transient logs, but retain repository and OSGi state.
# if [ -d "${QUICKSTART_DIR}/logs" ]; then
#     find "${QUICKSTART_DIR}/logs" \
#         -maxdepth 1 -type f -delete
# fi

echo "Warm-boot completed successfully."