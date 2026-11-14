#!/usr/bin/env bash
# Erstellt alle Betriebssystem-Releases, unabhängig vom ausführenden System.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$ROOT_DIR/release"

fail() { echo "[FEHLER] $*" >&2; exit 1; }
copy_required() { [[ -e "$1" ]] || fail "Fehlt: $1"; mkdir -p "$(dirname "$2")"; cp -R "$1" "$2"; }

create_release() {
  local os_name="$1" launcher_dir="$2" stage_dir archive_name archive_path document work_dir
  stage_dir="$(mktemp -d)"
  trap 'rm -rf "$stage_dir"' RETURN

  for document in README.md README.txt LICENSE; do copy_required "$ROOT_DIR/$document" "$stage_dir/$document"; done
  copy_required "$ROOT_DIR/Formatierung" "$stage_dir/Formatierung"
  copy_required "$ROOT_DIR/$launcher_dir" "$stage_dir/$launcher_dir"
  copy_required "$ROOT_DIR/pandoc/$os_name" "$stage_dir/pandoc/$os_name"
  copy_required "$ROOT_DIR/tectonic/$os_name" "$stage_dir/tectonic/$os_name"

  # Der macOS-Starter verwendet die gemeinsame Konvertierungslogik aus Linux/.
  if [[ "$os_name" == "macos" ]]; then
    mkdir -p "$stage_dir/Linux"
    copy_required "$ROOT_DIR/Linux/pandoc-tool.sh" "$stage_dir/Linux/pandoc-tool.sh"
  fi

  for work_dir in input merge out; do mkdir -p "$stage_dir/$work_dir"; : > "$stage_dir/$work_dir/.gitkeep"; done

  archive_name="pandoc-pdf-toolkit-${os_name}.zip"
  archive_path="$RELEASE_DIR/$archive_name"
  rm -f "$archive_path" "$archive_path.sha256"
  (cd "$stage_dir" && zip -q -r "$archive_path" .)
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$RELEASE_DIR" && sha256sum "$archive_name" > "$archive_name.sha256")
  else
    (cd "$RELEASE_DIR" && shasum -a 256 "$archive_name" > "$archive_name.sha256")
  fi
  echo "[OK] $archive_name"
}

command -v zip >/dev/null 2>&1 || fail "Das Programm 'zip' ist nicht installiert."
mkdir -p "$RELEASE_DIR"
create_release windows Windows
create_release linux Linux
create_release macos Mac
echo "[OK] Alle Release-Archive und SHA-256-Dateien liegen in: $RELEASE_DIR"
