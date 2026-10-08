FROM eclipse-temurin:11-jdk-jammy

ARG RUN_MODE=author
ARG PORT=4502
ARG CONTENT=nosamplecontent

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 aem && \
    useradd -u 10001 -g aem -d /opt/aem -s /bin/bash aem

WORKDIR /opt/aem

COPY AEM_6.5_Quickstart.jar /opt/aem/aem.jar
COPY license.properties /opt/aem/license.properties
COPY password.properties /opt/aem/password.properties

COPY entrypoint.sh /opt/aem/entrypoint.sh

RUN chmod +x /opt/aem/entrypoint.sh && \
    chown -R aem:aem /opt/aem

USER aem

ENV AEM_RUN_MODE=${RUN_MODE}
ENV AEM_CONTENT_TYPE=${CONTENT}
ENV AEM_PORT=${PORT}

EXPOSE 4502 4503

ENTRYPOINT ["/opt/aem/entrypoint.sh"]