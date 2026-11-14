#!/usr/bin/env bash
# Installiert die mitgelieferten Linux-Binaries ohne Administratorrechte.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${HOME}/.local/bin"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[FEHLER] install.sh ist nur fuer Linux bestimmt." >&2
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  LINUX_ID="${ID:-unbekannt}"
else
  LINUX_ID="unbekannt"
fi

case "$(uname -m)" in
  x86_64|amd64)
    PANDOC_SOURCE="$ROOT_DIR/pandoc/linux/amd64/bin/pandoc"
    if [[ "$LINUX_ID" == "alpine" ]]; then
      TECTONIC_SOURCE="$ROOT_DIR/tectonic/linux/musl/tectonic"
    else
      TECTONIC_SOURCE="$ROOT_DIR/tectonic/linux/gnu/tectonic"
    fi
    ;;
  aarch64|arm64)
    PANDOC_SOURCE="$ROOT_DIR/pandoc/linux/arm64/bin/pandoc"
    TECTONIC_SOURCE="$ROOT_DIR/tectonic/linux/aarch/tectonic"
    ;;
  armv7l|armv6l|armhf)
    echo "[FEHLER] Fuer 32-Bit-ARM ist keine passende Pandoc-Binaerdatei enthalten." >&2
    echo "Bitte verwende ein 64-Bit-Raspberry-Pi-OS oder installiere Pandoc ueber die Paketverwaltung." >&2
    exit 1
    ;;
  *)
    echo "[FEHLER] Nicht unterstuetzte Linux-Architektur: $(uname -m)" >&2
    exit 1
    ;;
esac

for source_file in "$PANDOC_SOURCE" "$TECTONIC_SOURCE"; do
  if [[ ! -f "$source_file" ]]; then
    echo "[FEHLER] Benoetigte Datei fehlt: $source_file" >&2
    exit 1
  fi
done

mkdir -p "$INSTALL_DIR"
install -m 0755 "$PANDOC_SOURCE" "$INSTALL_DIR/pandoc"
install -m 0755 "$TECTONIC_SOURCE" "$INSTALL_DIR/tectonic"

echo "[OK] Linux erkannt: $LINUX_ID / $(uname -m)"
echo "[OK] Pandoc und Tectonic installiert nach: $INSTALL_DIR"
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "[HINWEIS] Fuege diese Zeile zu ~/.bashrc oder ~/.zshrc hinzu:"
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
