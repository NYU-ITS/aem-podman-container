#!/bin/bash
set -e

REPO_DIR="/opt/aem/crx-quickstart/repository"
SEED_DIR="/opt/aem/repository-seed"

# If the mounted volume repository directory is empty, copy the warm seed data over
if [ -d "$SEED_DIR" ] && [ -z "$(ls -A $REPO_DIR 2>/dev/null)" ]; then
  echo "Empty repository volume detected. Seeding pre-built AEM repository state..."
  cp -r $SEED_DIR/* $REPO_DIR/
  echo "Seeding complete!"
fi

# If arguments were passed (e.g., from podman-compose), forward them to Java
if [ $# -gt 0 ]; then
    exec java $JAVA_OPTS -jar /opt/aem/crx-quickstart/app/*.jar "$@"
else
    # Default to Author mode
    exec java $JAVA_OPTS -jar /opt/aem/crx-quickstart/app/*.jar -p 4502 -r author -nofork
fi