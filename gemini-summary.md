# AEM 6.5 Podman Containerization Summary
## Overview
This document summarizes the containerization setup for AEM 6.5 using Podman Desktop on macOS. The implementation uses a warm-booted, multi-stage pipeline designed for fast local development and scalable deployment.

## Accomplishments & Final State
- Sub-30-Second Startup Times (Repository Baking): The build process initializes AEM once during image creation using -Dsling.run.modes=author,nosamplecontent, waits for HTTP 200, and cleanly terminates to capture a pre-built repository into /opt/aem/repository-seed.

- Volume Persistence Without Data Overwrite: A custom entrypoint.sh checks for empty persistent volumes at container launch and populates them from the seed directory. Storage is isolated in Podman named volumes to bypass macOS hypervisor filesystem I/O bottlenecks.

- Data Corruption Prevention (PID 1 Signal Handling): Executing Java directly (exec java) with the -nofork flag binds the container lifecycle directly to the JVM (PID 1). This allows SIGTERM signals from podman stop to trigger clean Oak SegmentNodeStore shutdowns without corrupting data.

- Run Mode & Launchpad Isolation: Standardized on -Dsling.run.modes to assign run modes cleanly without overriding the root HTTP context path in Sling Launchpad.

- Security Hardening: Enforces execution under a dedicated non-root user (aem, UID/GID 10001), extracts intermediate installer binaries during build to prevent layer bloat, and utilizes dynamic JVM memory scaling via -XX:MaxRAMPercentage=75.0.

- Developer Tooling: Provides a structured docker-compose.yml for running simultaneous Author (4502) and Publish (4503) instances, exposing remote JPDA debugging ports (30333/30334), and using .dockerignore to optimize build context transfers.

## Potential Issues & Current Limitations
- Large Container Image Size: Pre-baking the initialized Oak repository increases the base container image size from ~2 GB to roughly 8–12 GB, requiring sufficient storage allocated to the Podman Machine.

- Default Credentials in Baked Image: Omitting -Dadmin.password.file during image creation avoids first-time JCR race conditions, but leaves the seed repository with default admin/admin credentials. Passwords should be changed post-launch via HTTP API or package deployment.

- OpenShift Security Policy Compatibility: Deploying to Red Hat OpenShift requires adjusting directory group permissions (chgrp -R 0 /opt/aem && chmod -R g+rwX /opt/aem) to accommodate arbitrary runtime UIDs.

- Volume Disk Growth: As OSGi bundles or content packages are deployed locally via the ./install directory mount, local named volumes will expand indefinitely unless pruned (podman volume prune).

## Recommended Next Steps
- Bake Service Packs / Cumulative Fix Packs: Copy AEM Service Packs (e.g., AEM 6.5.20+) into the build context during Stage 1 so they are installed and indexed during the warm-boot phase.

- Automate Maven Package Deployment: Configure local Maven POM files or vault-cli to output built OSGi bundles and content package .zip files directly into ./install/author or ./install/publish for hot-reloading.

- Externalize Pipeline Secrets: Remove sensitive configuration files (license.properties, password.properties) from Git repositories and supply them dynamically using Kubernetes/OpenShift Secret mounts or Podman secret flags.

- Offload Binary Storage for Production: Add OSGi configurations for Amazon S3 or Azure Blob DataStore to offload heavy DAM assets, keeping local container storage dedicated strictly to Oak metadata.