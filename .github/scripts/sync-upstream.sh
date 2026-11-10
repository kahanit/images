#!/usr/bin/env bash
# Copies the newest upstream folders from github.com/bitnami/containers over
# the local image folders and reports how long ago each was last released.
#
# Usage: sync-upstream.sh [max quiet days, default 60]
# Writes: the image folders and UPSTREAM_COMMIT (only when a folder changed)
# Output: one line per image; "quiet=<names>" in $GITHUB_OUTPUT when an
#         upstream folder has had no commit for more than the given days,
#         or no longer exists.
set -euo pipefail

MAX_QUIET_DAYS="${1:-60}"
UPSTREAM=bitnami/containers
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

api() {
  local auth=()
  if [ -n "${GH_TOKEN:-}" ]; then auth=(-H "Authorization: Bearer $GH_TOKEN"); fi
  curl -sSf "${auth[@]}" -H "Accept: application/vnd.github+json" "https://api.github.com/$1"
}

# A shallow clone with only the three image folders checked out.
git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$UPSTREAM.git" "$WORK/up"
git -C "$WORK/up" sparse-checkout set bitnami/redis-cluster bitnami/redis-exporter bitnami/os-shell
upstream_commit="$(git -C "$WORK/up" rev-parse HEAD)"

# The upstream folder for each image. Redis: the highest 8.x branch that
# still has a Dockerfile (retired branches keep only a README).
redis_branch="$(cd "$WORK/up/bitnami/redis-cluster" && ls -d 8.*/debian-12 2>/dev/null \
  | while read -r d; do [ -f "$d/Dockerfile" ] && echo "${d%%/*}"; done | sort -V | tail -1)"
declare -A SOURCE=(
  [redis-cluster]="bitnami/redis-cluster/${redis_branch:-missing}/debian-12"
  [redis-exporter]="bitnami/redis-exporter/1/debian-12"
  [os-shell]="bitnami/os-shell/12/debian-12"
)

changed=0
quiet=()
now="$(date -u +%s)"
for image in redis-cluster redis-exporter os-shell; do
  src="${SOURCE[$image]}"
  if [ ! -f "$WORK/up/$src/Dockerfile" ]; then
    echo "$image: upstream folder $src has no Dockerfile any more"
    quiet+=("$image")
    continue
  fi

  # Verbatim copy of the three things an image is built from.
  rsync -a --delete "$WORK/up/$src/Dockerfile" "$ROOT/$image/Dockerfile"
  for dir in prebuildfs rootfs; do
    if [ -d "$WORK/up/$src/$dir" ]; then
      rsync -a --delete "$WORK/up/$src/$dir/" "$ROOT/$image/$dir/"
    else
      rm -rf "${ROOT:?}/$image/$dir"
    fi
  done
  if [ -n "$(git -C "$ROOT" status --porcelain -- "$image")" ]; then changed=1; state="changed"; else state="unchanged"; fi

  last="$(api "repos/$UPSTREAM/commits?path=$src&per_page=1" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["commit"]["committer"]["date"])')"
  age=$(( (now - $(date -u -d "$last" +%s)) / 86400 ))
  version="$(grep -oP 'APP_VERSION="\K[^"]+' "$ROOT/$image/Dockerfile")"
  revision="$(grep -oP 'IMAGE_REVISION="\K[^"]+' "$ROOT/$image/Dockerfile")"
  echo "$image: $src, $version revision $revision, last upstream release ${last%%T*} ($age days ago), $state"
  if [ "$age" -gt "$MAX_QUIET_DAYS" ]; then quiet+=("$image"); fi
done

if [ "$changed" = 1 ]; then echo "$upstream_commit" > "$ROOT/UPSTREAM_COMMIT"; fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "changed=$changed" >> "$GITHUB_OUTPUT"
  echo "quiet=${quiet[*]:-}" >> "$GITHUB_OUTPUT"
fi
if [ "${#quiet[@]}" -gt 0 ]; then
  echo "No upstream release for more than $MAX_QUIET_DAYS days (or folder gone): ${quiet[*]}"
fi
