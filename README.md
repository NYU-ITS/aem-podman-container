# aem-podman-container
Project investigating containerizing AEM utilizing Podman and Podman-Compose


## Installation

- Install Podman Desktop and Podman compose: follow instructions at https://podman-desktop.io/docs/installation/macos-install
- copy `example.license.properties` to `license.properties` and update it with your licensing information
- copy `example.password.properties` to `password.properties` and update it to a new admin password
- Download a copy of `AEM_6.5_Quickstart.jar` and place it in the project root.
- Download the most recent copy of the dispatcher module for aarch64 (assuming MacOS) from https://experienceleague.adobe.com/en/docs/experience-manager-dispatcher/using/getting-started/release-notes#apache
- Untar the archive and copy the `.so` file into `dispatcher/modules/`

### Recommended Podman VM Allocation

- CPUs: 4 cores
- Memory: 10-12 GB
- Disk: 50 GB+


## Run

### `author`-only

To spin up only an instance of the author, the default `compose.yml` file is used by default. In the terminal run

`podman compose build` to build the images, then

`podman compose up` or `podman compose up -d` to run it in a detached state.


### `author`, `publish`, and `dispatcher` cluster

To spin up the entire cluster, composed of `author`, `publish`, and `dispatch` services, run:

`podman compose -f compose.cluster.yml build` 

`podman compose -f compose.cluster.yml up`



## TODOs

### Podman Secrets

For production, we do not want to bake `license.properties` or `password.properties` into the container image. Need to investigate mounting both at runtime as Podman Secret Mounts.

### Externalize Binary Storage (S3/Azure Blob)

In production, running heavy DAM assets on local persistent volumes degrades disk I/O and makes scaling difficult. Need to configure S3 DataStore or other via OSGi configuration files in the AEM codebase. This will keep persistent volumes small (only storing Oak metadata) and makes backing up and cloning environments fast.



