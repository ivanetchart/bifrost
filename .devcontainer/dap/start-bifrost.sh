#!/usr/bin/env bash
# Dap service "bifrost": the gateway API + embedded web UI on :8080.
# Rebuilds the embedded UI only if ui/ changed, then builds and runs the
# current source (same flags as `make dev`, without air hot reload).
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ensure_ui_build
cd "$REPO_ROOT/transports/bifrost-http"
[ -f "$REPO_ROOT/.env" ] && { set -a; . "$REPO_ROOT/.env"; set +a; }
go build -tags dev -o tmp/main .
APP_DIR="${BIFROST_APP_DIR:-/tmp/bifrost-app}"
mkdir -p "$APP_DIR"
exec ./tmp/main -host 0.0.0.0 -port 8080 -log-style pretty -log-level info -app-dir "$APP_DIR"
