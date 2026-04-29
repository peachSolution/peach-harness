#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
VENV_PY="$PROJECT_ROOT/.venv/bin/python"
PIPX_VENV_PY="${HOME}/.local/pipx/venvs/markitdown/bin/python"

echo "[1/4] project root: $PROJECT_ROOT"

if ! command -v markitdown >/dev/null 2>&1; then
  if command -v pipx >/dev/null 2>&1; then
    echo "[2/4] markitdown not found. installing with pipx..."
    pipx install "markitdown[all]"
  else
    echo "markitdown이 없고 pipx도 없습니다. pipx 설치 후 다시 실행하세요." >&2
    exit 1
  fi
else
  echo "[2/4] markitdown already available: $(command -v markitdown)"
fi

if [ ! -x "$VENV_PY" ]; then
  echo "[3/4] creating local venv..."
  uv venv "$PROJECT_ROOT/.venv"
else
  echo "[3/4] local venv already exists"
fi

if ! "$VENV_PY" - <<'PY' >/dev/null 2>&1
import importlib.util
mods = ["hwpx", "lxml"]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
raise SystemExit(0 if not missing else 1)
PY
then
  echo "[4/4] installing python-hwpx and lxml..."
  uv pip install --python "$VENV_PY" python-hwpx lxml
else
  echo "[4/4] python-hwpx and lxml already available"
fi

echo "bootstrap complete"
