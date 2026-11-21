# Shared helpers for the Dap devcontainer scripts. Sourced, not executed.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAMP_DIR="${REPO_ROOT}/.devcontainer/dap/.stamps"   # untracked, see .gitignore
mkdir -p "$STAMP_DIR"
export PATH="$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin:$PATH"

log() { printf '[dap] %s\n' "$*"; }

# Create go.work with every local module (same set as `make setup-workspace`,
# without the slow `go work sync` / listing that target also does).
ensure_go_work() {
  cd "$REPO_ROOT"
  local want have
  want="$(printf '%s\n' ./cli ./core ./framework ./transports $(ls -d ./plugins/*/ 2>/dev/null | sed 's:/$::' | while read -r d; do [ -f "$d/go.mod" ] && echo "$d"; done) | sort)"
  have="$(cat "$STAMP_DIR/go-work-modules" 2>/dev/null || true)"
  if [ -f go.work ] && [ "$want" = "$have" ]; then
    log "go.work up to date"; return
  fi
  log "creating go.work"
  rm -f go.work go.work.sum
  # shellcheck disable=SC2086
  go work init $want
  printf '%s\n' "$want" > "$STAMP_DIR/go-work-modules"
}

# npm ci in a directory only when its package-lock.json changed since last install.
ensure_npm() {
  local dir="$REPO_ROOT/$1" key
  key="$(echo "$1" | tr '/' '_')"
  [ -f "$dir/package-lock.json" ] || return 0
  local sum; sum="$(sha256sum "$dir/package-lock.json" | cut -d' ' -f1)"
  if [ -d "$dir/node_modules" ] && [ "$(cat "$STAMP_DIR/npm-$key" 2>/dev/null)" = "$sum" ]; then
    log "npm deps in $1 up to date"; return
  fi
  log "npm ci in $1"
  (cd "$dir" && npm ci --no-audit --no-fund)
  echo "$sum" > "$STAMP_DIR/npm-$key"
}

# Build the static UI into transports/bifrost-http/ui (embedded by the Go server)
# only when ui/ differs from what was last built.
ensure_ui_build() {
  cd "$REPO_ROOT"
  local sum
  sum="$( (git ls-files -s ui; git diff --no-ext-diff -- ui; git ls-files --others --exclude-standard ui | xargs -r sha256sum) 2>/dev/null | sha256sum | cut -d' ' -f1)"
  if [ -f transports/bifrost-http/ui/index.html ] && [ "$(cat "$STAMP_DIR/ui-build" 2>/dev/null)" = "$sum" ]; then
    log "embedded UI up to date"; return
  fi
  log "building UI (next build -> transports/bifrost-http/ui)"
  rm -rf ui/app/enterprise
  (cd ui && npm run build)
  echo "$sum" > "$STAMP_DIR/ui-build"
}

# uv + Python for tests/integrations/python (`make test-integrations-py`).
# Installed from GitHub releases (astral.sh is not on Dap's Trusted list).
UV_VERSION="0.13.9"
ensure_uv() {
  if command -v uv >/dev/null && [ "$(uv --version | cut -d' ' -f2)" = "$UV_VERSION" ]; then
    log "uv $UV_VERSION present"
  else
    log "installing uv $UV_VERSION"
    local arch; arch="$(uname -m)"
    curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${arch}-unknown-linux-gnu.tar.gz" \
      | tar xz -C /usr/local/bin --strip-components=1
  fi
  # 3.11 matches CI; the test project's .python-version (3.12) becomes the default python3.
  uv python install 3.11
  uv python install "$(cat "$REPO_ROOT/tests/integrations/python/.python-version")" --default --preview-features python-install-default
}

# uv sync in tests/integrations/python only when uv.lock changed.
ensure_uv_sync() {
  local dir="$REPO_ROOT/tests/integrations/python" sum
  [ -f "$dir/uv.lock" ] || return 0
  sum="$(sha256sum "$dir/uv.lock" | cut -d' ' -f1)"
  if [ -d "$dir/.venv" ] && [ "$(cat "$STAMP_DIR/uv-sync" 2>/dev/null)" = "$sum" ]; then
    log "python deps up to date"; return
  fi
  log "uv sync in tests/integrations/python"
  (cd "$dir" && uv sync)
  echo "$sum" > "$STAMP_DIR/uv-sync"
}
