#!/usr/bin/env bash
# Interactive docker compose logs selector
# Usage: dcl_select.sh [path-to-compose-dir]
# Works only if a docker-compose.yml/.yaml exists in the target directory.
# Uses fzf if available, otherwise a bash select menu.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

compose_dir="${1:-.}"

# Ensure we have a compose file
if [[ ! -f "$compose_dir/docker-compose.yml" && ! -f "$compose_dir/docker-compose.yaml" ]]; then
  echo "Error: docker-compose.yml or docker-compose.yaml not found in: $compose_dir" >&2
  exit 1
fi

# Helper: check for docker_compose() wrapper
have_docker_compose_func=false
if declare -F docker_compose >/dev/null 2>&1; then
  have_docker_compose_func=true
fi

# Collect services from compose
services=()
if $have_docker_compose_func; then
  mapfile -t services < <( (cd "$compose_dir" && docker_compose ps --services) 2>/dev/null || true )
else
  mapfile -t services < <( (cd "$compose_dir" && (docker compose ps --services 2>/dev/null || docker-compose ps --services 2>/dev/null)) || true )
fi

if [[ ${#services[@]} -eq 0 ]]; then
  echo "No compose services found (is the project up?)." >&2
  exit 1
fi

# Let user pick a service
chosen=""
if command -v fzf >/dev/null 2>&1; then
  chosen=$(printf "%s\n" "${services[@]}" | fzf --ansi --prompt="Select service> " --height=40)
else
  PS3="Select service (or Ctrl-C to quit): "
  select opt in "${services[@]}"; do
    if [[ -z "${opt:-}" ]]; then
      echo "Invalid selection." >&2
      continue
    fi
    chosen="$opt"
    break
  done
fi

if [[ -z "$chosen" ]]; then
  echo "No selection made." >&2
  exit 1
fi

# Stream logs for the chosen compose service
if $have_docker_compose_func; then
  (cd "$compose_dir" && docker_compose logs -f -n 500 "$chosen")
else
  (cd "$compose_dir" && (docker compose logs -f -n 500 "$chosen" 2>/dev/null || docker-compose logs -f -n 500 "$chosen"))
fi
