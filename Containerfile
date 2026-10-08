# syntax=docker/dockerfile:1

# ----------------------------------------------------------
# Stage 1: Warm-boot AEM
# ----------------------------------------------------------
FROM eclipse-temurin:11-jdk-jammy AS builder

ARG RUN_MODE=author
ARG PORT=4502
ARG CONTENT=nosamplecontent

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 aem && \
    useradd -u 10001 -g 10001 \
      -d /opt/aem -s /bin/bash aem

WORKDIR /opt/aem

COPY --chown=aem:aem AEM_6.5_Quickstart.jar /opt/aem/aem.jar
COPY --chown=aem:aem license.properties /opt/aem/license.properties
COPY --chown=aem:aem password.properties /opt/aem/password.properties

COPY --chown=aem:aem warmboot.sh /opt/aem/warmboot.sh

RUN chmod +x /opt/aem/warmboot.sh && \
    mkdir -p /opt/aem/crx-quickstart && \
    chown -R aem:aem /opt/aem

USER aem

RUN /opt/aem/warmboot.sh \
    "${RUN_MODE}" "${PORT}" "${CONTENT}"


# ----------------------------------------------------------
# Stage 2: Runtime
# ----------------------------------------------------------
FROM eclipse-temurin:11-jre-jammy

ARG RUN_MODE=author
ARG PORT=4502
ARG CONTENT=nosamplecontent

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 aem && \
    useradd -u 10001 -g 10001 \
      -d /opt/aem -s /bin/bash aem

WORKDIR /opt/aem

COPY --chown=aem:aem --from=builder \
    /opt/aem/aem.jar /opt/aem/aem.jar

COPY --chown=aem:aem --from=builder \
    /opt/aem/license.properties /opt/aem/license.properties

COPY --chown=aem:aem --from=builder \
    /opt/aem/password.properties /opt/aem/password.properties

COPY --chown=aem:aem --from=builder \
    /opt/aem/crx-quickstart /opt/aem/crx-quickstart

COPY --chown=aem:aem entrypoint.sh /opt/aem/entrypoint.sh

RUN chmod +x /opt/aem/entrypoint.sh

USER aem

ENV AEM_RUN_MODE=${RUN_MODE} \
    AEM_CONTENT_TYPE=${CONTENT} \
    AEM_PORT=${PORT}

EXPOSE 4502 4503

ENTRYPOINT ["/opt/aem/entrypoint.sh"]