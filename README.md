# kahanit/images

Container images for the `kahanit/redis-cluster` Helm chart (its source:
[kahanit/charts](https://github.com/kahanit/charts)), built from Bitnami's
Dockerfiles and pushed to Docker Hub under `kahanit/`.

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

`.github/workflows/build.yml` builds the three images for `linux/amd64`,
scans them and pushes them:

- every Monday at 02:00 UTC, from the same sources: the Dockerfiles run
  `apt-get upgrade`, so a weekly rebuild carries Debian's package fixes
- on a push to `main` that touches an image folder
- by hand: Actions → Build and push → Run workflow

Each build pushes two tags, taken from the Dockerfile (`APP_VERSION`,
`IMAGE_REVISION`):

| Tag | Example | Behaviour |
|---|---|---|
| dated | `8.10.3-r1-20261116` | never moved; pin this one in an installation |
| plain | `8.10.3-r1` | moved to the newest build |

A build is not pushed when [Trivy](https://trivy.dev) finds a critical
vulnerability that has a fix. Vulnerabilities without a fix are listed in
the run's log and do not block.

## Following upstream

`.github/workflows/upstream.yml` runs every Monday at 01:00 UTC
(`.github/scripts/sync-upstream.sh`):

- When Bitnami has released newer sources (for Redis: the highest `8.x`
  branch), it opens the pull request `upstream-sync` with the changed
  folders. Read the Dockerfile diff and merge; the merge builds and pushes.
  Then set the new dated tags in the cluster's `values/redis.yaml`.
- When an upstream folder has had no release for more than 60 days, or is
  gone, the workflow fails. Bitnami already stopped publishing its
  `redis-cluster` image on Docker Hub; if the sources stop too, the images
  have to be built another way (for example on the official `redis` image).

## Setup

Repository secrets (Settings → Secrets and variables → Actions):

- `DOCKERHUB_USERNAME`: the Docker Hub account that owns the `kahanit` namespace
- `DOCKERHUB_TOKEN`: a Docker Hub access token with read/write permission
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`: where a failed build or upstream
  check is reported. Without them a failure only shows in GitHub.

Repository setting (Settings → Actions → General → Workflow permissions):
"Allow GitHub Actions to create and approve pull requests" must be on for
the upstream pull request.

GitHub switches off scheduled workflows in a public repository after 60 days
without a commit, and sends an e-mail first. Re-enable them under Actions if
that happens; a merged upstream pull request resets the clock.

## Updating an image by hand

Run `.github/scripts/sync-upstream.sh` in a clone: it copies the upstream
`Dockerfile`, `prebuildfs/` and `rootfs/` over each folder and updates
`UPSTREAM_COMMIT`. Commit, push to `main`, and the workflow builds.
