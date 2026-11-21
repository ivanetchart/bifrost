#!/usr/bin/env bash
# Runs on every session start/resume. Must be idempotent and quick: it only
# redoes work when the session's branch changed modules or lockfiles.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ensure_go_work
ensure_npm ui
ensure_npm tests/e2e
ensure_uv_sync
log "post-session-start done"
