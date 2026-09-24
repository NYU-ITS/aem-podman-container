# --- Stage 1: Build, Unpack & Warm-Boot Stage ---
FROM eclipse-temurin:11-jdk-jammy AS builder

# 1. Declare build arguments with Author defaults
ARG RUN_MODE=author
ARG PORT=4502

RUN apt-get update && apt-get install -y curl --no-install-recommends && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/aem

COPY AEM_6.5_Quickstart.jar /opt/aem/aem.jar
COPY license.properties /opt/aem/license.properties
COPY password.properties /opt/aem/password.properties

# Unpack AEM
RUN java -jar /opt/aem/aem.jar -unpack -nointeractive && \
    rm -f /opt/aem/aem.jar

# 2. Warm-Boot using parameterized RUN_MODE and PORT
RUN java -Xmx4096m -Djava.awt.headless=true -Dsling.run.modes=${RUN_MODE},nosamplecontent \
    -jar /opt/aem/crx-quickstart/app/*.jar -p ${PORT} -nofork & \
    PID=$! && \
    echo "Waiting for AEM (${RUN_MODE}) to complete initial setup on port ${PORT}..." && \
    COUNTER=0 && \
    until STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/libs/granite/core/content/login.html) && [ "$STATUS" = "200" ]; do \
      COUNTER=$((COUNTER+10)) && \
      echo "AEM (${RUN_MODE}) initializing... ($COUNTER sec elapsed) - Current HTTP Status: $STATUS" && \
      sleep 10; \
    done && \
    echo "AEM (${RUN_MODE}) is fully initialized (HTTP 200 received). Shutting down cleanly..." && \
    kill -TERM $PID && \
    (wait $PID || true) && \
    rm -rf /opt/aem/crx-quickstart/logs/*

# Save mode-specific seed repository
RUN cp -r /opt/aem/crx-quickstart/repository /opt/aem/repository-seed


# --- Stage 2: Runtime Stage ---
FROM eclipse-temurin:11-jre-jammy

RUN groupadd -g 10001 aem && \
    useradd -u 10001 -g aem -d /opt/aem -s /bin/bash aem

WORKDIR /opt/aem

COPY --chown=aem:aem --from=builder /opt/aem /opt/aem
COPY --chown=aem:aem entrypoint.sh /opt/aem/entrypoint.sh
RUN chmod +x /opt/aem/entrypoint.sh

USER aem
EXPOSE 4502 4503

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.awt.headless=true -XX:+HeapDumpOnOutOfMemoryError"

ENTRYPOINT ["/opt/aem/entrypoint.sh"]