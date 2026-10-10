#!/usr/bin/env bash
# Dry-run Renovate (container) against one GitHub repo. Nothing is written to the target.
# usage: scripts/dry-run.sh <owner/repo> [config-file]
#   config-file: optional Renovate global config mounted as /config.js (.json or .json5)
set -euo pipefail

repo="${1:?usage: $0 <owner/repo> [config.json]}"
config="${2:-}"
image="${RENOVATE_IMAGE:-ghcr.io/renovatebot/renovate:44.149.2}"
name="${repo//\//__}"
out="$(cd "$(dirname "$0")/.." && pwd)/out"
tag="${RUN_TAG:-}"
mkdir -p "$out"

# Read-only token comes from the gh keyring. It is passed by name only, never echoed.
RENOVATE_TOKEN="$(gh auth token)"
export RENOVATE_TOKEN

args=(
  --rm
  -e RENOVATE_TOKEN
  -e RENOVATE_PLATFORM=github
  -e RENOVATE_REPOSITORIES="$repo"
  -e RENOVATE_DRY_RUN=full
  -e RENOVATE_ONBOARDING=false
  -e RENOVATE_REQUIRE_CONFIG=optional
  -e LOG_LEVEL=debug
  -e LOG_FORMAT=json
)
if [[ -n "$config" ]]; then
  args+=(-v "$(cd "$(dirname "$config")" && pwd)/$(basename "$config"):/config.json5:ro" -e RENOVATE_CONFIG_FILE=/config.json5)
fi

docker run "${args[@]}" "$image" renovate > "$out/${tag}${name}.jsonl" 2> "$out/${tag}${name}.err" || true
echo "log: $out/${tag}${name}.jsonl ($(wc -l < "$out/${tag}${name}.jsonl") lines)"
