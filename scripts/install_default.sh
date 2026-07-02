#!/usr/bin/env bash
# install_default.sh — install common tools safely, with clear logging.
# Default: apt install docker.io docker-compose-v2 htop iftop fzf, then bottom via snap (observe-only).

set -u -o pipefail  # don't use -e; we want to continue on individual failures

# --- Colors ---
COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;36m"    # Bold Cyan
COLOR_ERROR="\033[1;31m"   # Bold Red
COLOR_SUCCESS="\033[1;32m" # Bold Green
COLOR_WARN="\033[1;33m"    # Bold Yellow

APT_PKGS=(docker.io docker-compose-v2 htop iftop fzf)
DO_SNAP=1
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--no-snap] [--dry-run]

Options:
  --no-snap          Skip installing bottom via snap.
  --dry-run          Print what would be done, but do not execute.

Examples:
  $(basename "$0")
  $(basename "$0") --no-snap
  $(basename "$0") --dry-run
EOF
}

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-snap) DO_SNAP=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo -e "${COLOR_ERROR}>>> Unknown option:${COLOR_RESET} $1"; usage; exit 2 ;;
  esac
done

PKGS=("${APT_PKGS[@]}")

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "${COLOR_WARN}DRY-RUN:${COLOR_RESET} $*"
    return 0
  else
    eval "$@"
  fi
}

log()      { echo -e "${COLOR_INFO}>>>${COLOR_RESET} $*"; }
success()  { echo -e "${COLOR_SUCCESS}>>>${COLOR_RESET} $*"; }
warn()     { echo -e "${COLOR_WARN}>>>${COLOR_RESET} $*"; }
error()    { echo -e "${COLOR_ERROR}>>>${COLOR_RESET} $*"; }

# --- Track results for summary ---
APT_INSTALLED=()
APT_ALREADY=()
APT_FAILED=()
APT_SKIPPED=()     # track skipped with reason
SNAP_BOTTOM_STATUS="skipped"   # installed|already|failed|snapd_failed|skipped

# --- Pre-checks for known conflicts & skip with reasons ---
# If docker-compose-plugin exists, skip docker-compose-v2 (file conflict).
if dpkg -l 2>/dev/null | awk '{print $2}' | grep -qx 'docker-compose-plugin'; then
  APT_SKIPPED+=("docker-compose-v2 (skipped: docker-compose-plugin present)")
  PKGS=("${PKGS[@]/docker-compose-v2}")  # remove from list
fi

# If Docker Inc.'s containerd.io exists, skip Ubuntu's docker.io (Conflicts: containerd).
if dpkg -l 2>/dev/null | awk '{print $2}' | grep -qx 'containerd.io'; then
  APT_SKIPPED+=("docker.io (skipped: containerd.io installed; use docker-ce stack)")
  PKGS=("${PKGS[@]/docker.io}")  # remove from list
fi

# --- APT installs ---
if [[ ${#PKGS[@]} -gt 0 ]]; then
  log "Installing apt packages (individually): ${PKGS[*]}"
else
  log "No apt packages to install after conflict checks."
fi

for pkg in "${PKGS[@]}"; do
  [[ -z "$pkg" ]] && continue
  log "Installing ${pkg}..."
  # Detect “already newest version” by simulation first.
  if sudo apt-get -s install -y "$pkg" 2>/dev/null | grep -q "is already the newest version"; then
    warn "${pkg} is already the newest version"
    APT_ALREADY+=("$pkg")
    continue
  fi

  if run "sudo apt install -y '${pkg}'"; then
    APT_INSTALLED+=("$pkg")
  else
    APT_FAILED+=("$pkg")
  fi
done

# --- Snap / bottom ---
if [[ $DO_SNAP -eq 1 ]]; then
  log "Ensuring snapd is available..."
  if ! command -v snap >/dev/null 2>&1; then
    log "snap command not found; installing snapd..."
    if ! run "sudo apt install -y snapd"; then
      error "Failed to install snapd; skipping bottom via snap."
      SNAP_BOTTOM_STATUS="snapd_failed"
    fi
  fi

  if [[ "$SNAP_BOTTOM_STATUS" != "snapd_failed" ]]; then
    log "Installing bottom via snap..."
    if snap list 2>/dev/null | awk '{print $1}' | grep -qx "bottom"; then
      warn "bottom is already installed (snap)"
      run "sudo snap connect bottom:mount-observe"
      run "sudo snap connect bottom:hardware-observe"
      run "sudo snap connect bottom:system-observe"
      SNAP_BOTTOM_STATUS="already"
    else
      if run "sudo snap install bottom"; then
        run "sudo snap connect bottom:mount-observe"
        run "sudo snap connect bottom:hardware-observe"
        run "sudo snap connect bottom:system-observe"
        SNAP_BOTTOM_STATUS="installed"
        success "bottom installed; observe interfaces connected"
      else
        SNAP_BOTTOM_STATUS="failed"
        error "Failed to install bottom via snap"
      fi
    fi
  fi
else
  log "Skipping bottom (snap) as requested (--no-snap)."
  SNAP_BOTTOM_STATUS="skipped"
fi

# --- Per-step feedback ---
if [[ ${#APT_FAILED[@]} -gt 0 ]]; then
  error "The following apt packages failed to install: ${APT_FAILED[*]}"
else
  success "APT phase finished (no failures)."
fi

# --- Final Summary ---
echo
echo -e "${COLOR_INFO}==================== SUMMARY ====================${COLOR_RESET}"

if [[ ${#APT_INSTALLED[@]} -gt 0 ]]; then
  echo -e "${COLOR_SUCCESS}Installed (apt):${COLOR_RESET} ${APT_INSTALLED[*]}"
else
  echo -e "${COLOR_SUCCESS}Installed (apt):${COLOR_RESET} —"
fi

if [[ ${#APT_ALREADY[@]} -gt 0 ]]; then
  echo -e "${COLOR_WARN}Already present (apt):${COLOR_RESET} ${APT_ALREADY[*]}"
else
  echo -e "${COLOR_WARN}Already present (apt):${COLOR_RESET} —"
fi

if [[ ${#APT_SKIPPED[@]} -gt 0 ]]; then
  echo -e "${COLOR_WARN}Skipped (apt):${COLOR_RESET} ${APT_SKIPPED[*]}"
else
  echo -e "${COLOR_WARN}Skipped (apt):${COLOR_RESET} —"
fi

if [[ ${#APT_FAILED[@]} -gt 0 ]]; then
  echo -e "${COLOR_ERROR}Failed (apt):${COLOR_RESET} ${APT_FAILED[*]}"
else
  echo -e "${COLOR_ERROR}Failed (apt):${COLOR_RESET} —"
fi

case "$SNAP_BOTTOM_STATUS" in
  installed)
    echo -e "${COLOR_SUCCESS}bottom (snap):${COLOR_RESET} installed and observe interfaces connected"
    ;;
  already)
    echo -e "${COLOR_WARN}bottom (snap):${COLOR_RESET} already installed (interfaces ensured)"
    ;;
  failed)
    echo -e "${COLOR_ERROR}bottom (snap):${COLOR_RESET} install failed"
    ;;
  snapd_failed)
    echo -e "${COLOR_ERROR}bottom (snap):${COLOR_RESET} skipped (snapd installation failed)"
    ;;
  skipped|*)
    echo -e "${COLOR_WARN}bottom (snap):${COLOR_RESET} skipped"
    ;;
esac

echo -e "${COLOR_INFO}=================================================${COLOR_RESET}"
