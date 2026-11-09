# kahanit/images

Container images for the `kahanit/redis-cluster` Helm chart, built from
Bitnami's Dockerfiles and pushed to Docker Hub under `kahanit/`.

| Folder | Upstream folder in `bitnami/containers` | Image |
|---|---|---|
| `redis-cluster/` | `bitnami/redis-cluster/8.10/debian-12` | `docker.io/kahanit/redis-cluster:8.10.3-r1` |
| `redis-exporter/` | `bitnami/redis-exporter/1/debian-12` | `docker.io/kahanit/redis-exporter:1.97.0` |
| `os-shell/` | `bitnami/os-shell/12/debian-12` | `docker.io/kahanit/os-shell:12` |

Each folder is a verbatim copy of the upstream folder (Dockerfile, `prebuildfs/`,
`rootfs/`); `UPSTREAM_COMMIT` holds the `bitnami/containers` commit they came from.
The Dockerfiles download Bitnami's prebuilt tarballs from
`downloads.bitnami.com/files/stacksmith` and verify them against the checksums
in `prebuildfs/opt/bitnami/checksums/`.

## Building

`.github/workflows/build.yml` builds the three images for `linux/amd64` and
pushes them on every push to `main` and on manual dispatch. It needs two
repository secrets:

- `DOCKERHUB_USERNAME` — the Docker Hub account that owns the `kahanit` namespace
- `DOCKERHUB_TOKEN` — a Docker Hub access token with read/write permission

## Updating an image

1. Copy the upstream folder over the local one, for example
   `bitnami/redis-cluster/8.10/debian-12` → `redis-cluster/`, and drop
   `docker-compose.yml`.
2. Update `UPSTREAM_COMMIT` and the `tag` for that image in the workflow matrix
   (`<redis version>-r<n>` for `redis-cluster`, the tool version for the others).
3. Push to `main`; the workflow builds and pushes.
4. Set the new tag in the cluster's `values/redis.yaml`.

Planned (not yet here): a weekly scheduled rebuild on the newest upstream
folders, a Trivy scan that fails on critical findings, and an alert on failure.
