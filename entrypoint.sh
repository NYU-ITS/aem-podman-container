#!/bin/bash
set -e

REPO_DIR="/opt/aem/crx-quickstart/repository"
SEED_DIR="/opt/aem/repository-seed"

# If the mounted volume repository directory is empty, copy the mode-specific seed data over
if [ -d "$SEED_DIR" ] && [ -z "$(ls -A $REPO_DIR 2>/dev/null)" ]; then
  echo "Empty repository volume detected. Seeding pre-built AEM repository state..."
  cp -r $SEED_DIR/* $REPO_DIR/
  echo "Seeding complete!"
fi

# Hand off execution to Java process, forwarding any runtime arguments passed from Compose
exec java $JAVA_OPTS -jar /opt/aem/crx-quickstart/app/*.jar "$@"