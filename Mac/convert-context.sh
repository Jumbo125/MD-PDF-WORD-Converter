#!/usr/bin/env bash
set -euo pipefail

FORMAT="${1:-}"
shift || true
USE_STANDARD_FORMATTING="${1:-no}"
shift || true
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

[[ "$FORMAT" == "pdf" || "$FORMAT" == "docx" ]] || { echo "[FEHLER] Format muss pdf oder docx sein." >&2; exit 1; }

case "$(uname -m)" in
  x86_64) PANDOC="$ROOT_DIR/pandoc/macos/bin/pandoc"; TECTONIC="$ROOT_DIR/tectonic/macos/x86_64/tectonic" ;;
  arm64) PANDOC="$ROOT_DIR/pandoc/macos/arm64/bin/pandoc"; TECTONIC="$ROOT_DIR/tectonic/macos/aarch/tectonic" ;;
  *) echo "[FEHLER] Nicht unterstuetzte macOS-Architektur." >&2; exit 1 ;;
esac

[[ -f "$PANDOC" ]] || { echo "[FEHLER] Pandoc fehlt: $PANDOC" >&2; exit 1; }
[[ "$FORMAT" != "pdf" || -f "$TECTONIC" ]] || { echo "[FEHLER] Tectonic fehlt: $TECTONIC" >&2; exit 1; }

for input_file in "$@"; do
  [[ -f "$input_file" ]] || continue
  source_dir="$(dirname "$input_file")"
  filename="$(basename "$input_file")"
  base_name="${filename%.*}"
  timestamp="$(date '+%Y%m%d-%H%M%S')"
  output_file="$source_dir/${base_name}_${timestamp}.${FORMAT}"
  counter=1
  while [[ -e "$output_file" ]]; do output_file="$source_dir/${base_name}_${timestamp}_${counter}.${FORMAT}"; counter=$((counter + 1)); done

  args=("$input_file" -o "$output_file" --syntax-highlighting=tango "--resource-path=$source_dir")
  if [[ "$FORMAT" == "pdf" ]]; then
    args+=("--pdf-engine=$TECTONIC")
    if [[ "$USE_STANDARD_FORMATTING" == "yes" ]]; then
      [[ -f "$ROOT_DIR/Formatierung/header.tex" ]] || { echo "[FEHLER] Standardformatierung fehlt: $ROOT_DIR/Formatierung/header.tex" >&2; exit 1; }
      args+=(-H "$ROOT_DIR/Formatierung/header.tex")
    fi
  fi
  "$PANDOC" "${args[@]}"
done
