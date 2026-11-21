#!/usr/bin/env bash
# Dap service "ui-dev": Next.js dev server with hot reload on :3000.
# In dev mode the browser calls http://localhost:8080 directly, so use it from
# inside the workspace (agent-browser), not through a tunnel; the tunneled
# "bifrost" service serves the built UI instead.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO_ROOT/ui"
rm -rf app/enterprise
exec npx next dev -H 0.0.0.0 -p 3000
