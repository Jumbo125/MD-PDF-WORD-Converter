#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Linux) exec bash "$ROOT_DIR/Linux/pandoc-tool.sh" linux makepdf ;;
  Darwin) exec bash "$ROOT_DIR/Linux/pandoc-tool.sh" macos makepdf ;;
  *) echo "[FEHLER] Nicht unterstuetztes Betriebssystem: $(uname -s)" >&2; exit 1 ;;
esac
