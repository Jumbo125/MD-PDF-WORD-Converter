#!/usr/bin/env bash
set -euo pipefail

SERVICES_DIR="$HOME/Library/Services"
rm -rf "$SERVICES_DIR/Convert with Pandoc - PDF.workflow" "$SERVICES_DIR/Convert with Pandoc - Word.workflow"
killall Finder 2>/dev/null || true
echo '[OK] Finder-Schnellaktionen entfernt.'
