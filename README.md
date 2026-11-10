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

## The chart

`charts/redis-cluster/` is the source of the Helm chart published as
`oci://registry-1.docker.io/kahanit/redis-cluster`. The folder is the unpacked
`1.0.1` package (published 2026-01-16), `charts/common/` included.

It is Bitnami's `redis-cluster` chart `13.0.5`, the last one Bitnami released
(`github.com/bitnami/charts`, no template change since August 2025). Compared
on 2026-11-10: all 22 files in `templates/` are identical to Bitnami's. The
differences are:

- `Chart.yaml`: `version` 1.0.1, `appVersion` 8.4.0, the three images under
  `kahanit/`, and the `common` dependency from `oci://registry-1.docker.io/kahanit`
  pinned at 2.31.7
- `values.yaml`: the image repositories and tags (`kahanit/redis-cluster`,
  `kahanit/redis-exporter`, `kahanit/os-shell`)
- `charts/common`: 2.31.7; its `_labels.tpl` replaces `+` with `_` in the
  version label
- README wording

The chart's default image tags are older than the images built here; an
installation sets the current tags in its own values.

To release a change: edit the chart, raise `version` in `Chart.yaml`, then
`helm package charts/redis-cluster` and
`helm push redis-cluster-<version>.tgz oci://registry-1.docker.io/kahanit`.

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
