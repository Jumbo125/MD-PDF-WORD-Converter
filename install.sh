#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[FEHLER] install.sh ist nur fuer Linux bestimmt." >&2
  exit 1
fi

exec bash "$ROOT_DIR/Linux/install.sh"
