#!/usr/bin/env bash
# Serve current directory on port 8080 or the next free port.
# Usage: ./serve.sh [START_PORT]
# Options: -n|--dry-run  only print the chosen port and exit

set -euo pipefail

DRY_RUN=0
START_PORT=8080
# Allow calling: serve.sh -n  or serve.sh 8080 -n or serve.sh 9090
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -* )
      echo "Unknown option: $1" >&2
      exit 2
      ;;
    * )
      START_PORT="$1"
      shift
      ;;
  esac
done

# find a python interpreter
PYTHON=
if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "Python is required but not found in PATH. Please install Python 3." >&2
  exit 1
fi

# Use a short Python snippet to find the first free port starting at START_PORT
PORT=$($PYTHON - "$START_PORT" - <<PY
import sys, socket
p=int(sys.argv[1])
while True:
  s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
  try:
    s.bind(('0.0.0.0', p))
    s.close()
    print(p)
    sys.exit(0)
  except OSError:
    p += 1
PY
)

if [[ -z "${PORT}" ]]; then
  echo "Failed to find a free port starting at ${START_PORT}." >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "$PORT"
  exit 0
fi

echo "Serving directory: $(pwd)"
echo "Listening on: http://0.0.0.0:${PORT} and http://localhost:${PORT}"

# Start the server using the selected python interpreter
exec $PYTHON -m http.server "$PORT" --bind 0.0.0.0
