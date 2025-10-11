#!/usr/bin/env bash
# Interactive docker compose logs selector
# Usage: dcl_select.sh [path-to-compose-dir]
# If run inside a docker-compose project directory (or given a path), lists compose services.
# Otherwise lists running containers. Uses fzf if available, falls back to a bash select menu.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

compose_dir="${1:-.}"

services=()

# Try to list services from docker compose if there is a compose file
if [[ -f "$compose_dir/docker-compose.yml" || -f "$compose_dir/docker-compose.yaml" ]]; then
  # Use docker_compose wrapper if available
  if declare -F docker_compose >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    mapfile -t services < <( (cd "$compose_dir" && docker_compose ps --services) 2>/dev/null || true )
  else
    mapfile -t services < <( (cd "$compose_dir" && (docker compose ps --services 2>/dev/null || docker-compose ps --services 2>/dev/null)) || true )
  fi
fi

# If no services found from compose, list running containers
if [[ ${#services[@]} -eq 0 ]]; then
  # List container names
  if command -v docker >/dev/null 2>&1; then
    mapfile -t services < <(docker ps --format '{{.Names}}')
  fi
fi

if [[ ${#services[@]} -eq 0 ]]; then
  echo "No services or running containers found." >&2
  exit 1
fi

chosen=""

if command -v fzf >/dev/null 2>&1; then
  # Use fzf with header
  chosen=$(printf "%s\n" "${services[@]}" | fzf --ansi --prompt="Select service/container> " --height=40)
else
  # Fallback to a bash select menu
  PS3="Select service/container (or q to quit): "
  select opt in "${services[@]}"; do
    if [[ -z "$opt" ]]; then
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

# Run logs for the chosen service/container using docker_compose wrapper if available
if declare -F docker_compose >/dev/null 2>&1; then
  # If it looks like a compose service (no slash and not containing a dot with pidish), try compose logs
  if [[ -f "$compose_dir/docker-compose.yml" || -f "$compose_dir/docker-compose.yaml" ]] && printf "%s\n" "${services[@]}" | grep -Fxq -- "$chosen"; then
    (cd "$compose_dir" && docker_compose logs -f -n 500 "$chosen")
    exit $?
  fi
  # Otherwise, fallback to docker logs
  docker logs -f --tail 500 "$chosen"
  exit $?
else
  # No wrapper: try docker compose first, then docker logs
  if [[ -f "$compose_dir/docker-compose.yml" || -f "$compose_dir/docker-compose.yaml" ]] && printf "%s\n" "${services[@]}" | grep -Fxq -- "$chosen"; then
    (cd "$compose_dir" && (docker compose logs -f -n 500 "$chosen" 2>/dev/null || docker-compose logs -f -n 500 "$chosen"))
    exit $?
  fi
  docker logs -f --tail 500 "$chosen"
  exit $?
fi
