#!/usr/bin/env bash
# Runs once per Dap workspace template build (no secrets, public hosts only).
# Everything here is cached into the template so sessions start warm.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO_ROOT"

log "toolchain: $(go version), node $(node -v)"

# Dev tools used by the Makefile (pinned instead of @latest).
go install gotest.tools/gotestsum@v1.13.0
go install github.com/air-verse/air@v1.67.4

ensure_go_work
log "downloading Go modules"
go mod download -C core && go mod download -C framework && go mod download -C transports && go mod download -C cli
for d in plugins/*/; do [ -f "$d/go.mod" ] && go mod download -C "$d"; done

ensure_npm ui
ensure_npm tests/e2e

ensure_uv
ensure_uv_sync

# Warm the Go build cache for the gateway binary and the core library.
ensure_ui_build
log "warming Go build cache"
(cd transports/bifrost-http && go build -tags dev -o tmp/main .)
go build ./core/... ./framework/...

log "post-cache-build done"
