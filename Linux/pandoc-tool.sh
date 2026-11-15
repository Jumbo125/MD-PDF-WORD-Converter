#!/usr/bin/env bash
# Gemeinsamer Starter fuer Linux und macOS.
set -uo pipefail

PLATFORM="${1:-}"
ACTION="${2:-}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
INPUT_DIR="$ROOT_DIR/input"
OUT_DIR="$ROOT_DIR/out"
MERGE_DIR="$ROOT_DIR/merge"
HEADER="$ROOT_DIR/Formatierung/header.tex"

fail() { echo "[FEHLER] $*" >&2; exit 1; }

if [[ "$PLATFORM" == "linux" ]]; then
  [[ "$(uname -s)" == "Linux" ]] || fail "Dieses Skript muss unter Linux gestartet werden."
  case "$(uname -m)" in
    x86_64|amd64)
      PANDOC="$ROOT_DIR/pandoc/linux/amd64/bin/pandoc"
      if [[ -r /etc/os-release ]]; then . /etc/os-release; fi
      if [[ "${ID:-}" == "alpine" ]]; then TECTONIC="$ROOT_DIR/tectonic/linux/musl/tectonic"; else TECTONIC="$ROOT_DIR/tectonic/linux/gnu/tectonic"; fi
      ;;
    aarch64|arm64) PANDOC="$ROOT_DIR/pandoc/linux/arm64/bin/pandoc"; TECTONIC="$ROOT_DIR/tectonic/linux/aarch/tectonic" ;;
    *) fail "Nicht unterstuetzte Linux-Architektur: $(uname -m)." ;;
  esac
elif [[ "$PLATFORM" == "macos" ]]; then
  [[ "$(uname -s)" == "Darwin" ]] || fail "Dieses Skript muss unter macOS gestartet werden."
  case "$(uname -m)" in
    x86_64) PANDOC="$ROOT_DIR/pandoc/macos/bin/pandoc"; TECTONIC="$ROOT_DIR/tectonic/macos/x86_64/tectonic" ;;
    arm64) PANDOC="$ROOT_DIR/pandoc/macos/arm64/bin/pandoc"; TECTONIC="$ROOT_DIR/tectonic/macos/aarch/tectonic" ;;
    *) fail "Nicht unterstuetzte macOS-Architektur: $(uname -m)." ;;
  esac
else
  fail "Aufruf: bash pandoc-tool.sh <linux|macos>"
fi

[[ -f "$PANDOC" ]] || fail "Pandoc fehlt: $PANDOC"
[[ -f "$TECTONIC" ]] || fail "Tectonic fehlt: $TECTONIC"
[[ -d "$INPUT_DIR" ]] || fail "Ordner input fehlt."
mkdir -p "$OUT_DIR"

convert_files() {
  local files=() selections=() entry index format mode extension file source_dir output log_file use_header=false
  shopt -s nullglob
  files=("$INPUT_DIR"/*.md)
  shopt -u nullglob
  ((${#files[@]})) || { echo "[INFO] Keine Markdown-Dateien in input gefunden."; return; }

  echo "Dateien in input/:"
  for index in "${!files[@]}"; do printf '  %d) %s\n' "$((index + 1))" "$(basename "${files[$index]}")"; done
  read -r -p "Nummer(n) auswaehlen (z.B. 1;3;5, ENTER = Abbruch): " entry
  [[ -n "$entry" ]] || return
  IFS=';' read -r -a selections <<< "$entry"
  for index in "${selections[@]}"; do [[ "$index" =~ ^[0-9]+$ ]] && ((index >= 1 && index <= ${#files[@]})) || { echo "[FEHLER] Ungueltige Auswahl: $index"; return; }; done

  read -r -p "Zielformat: 1) PDF  2) Word (.docx): " format
  case "$format" in 1) extension=pdf ;; 2) extension=docx ;; *) echo "[FEHLER] Bitte 1 oder 2 eingeben."; return ;; esac
  if [[ "$format" == 1 ]]; then
    if [[ -f "$HEADER" ]]; then
      read -r -p "Standardformatierung aus Formatierung/header.tex verwenden? (J/n): " entry
      [[ ! "$entry" =~ ^[nN]$ ]] && use_header=true
    else
      echo "[WARNUNG] Formatierung/header.tex nicht gefunden."
    fi
  fi
  read -r -p "Modus: 1) Normal  2) Mit Log/Debug: " mode
  [[ "$mode" == 1 || "$mode" == 2 ]] || { echo "[FEHLER] Bitte 1 oder 2 eingeben."; return; }
  read -r -p "Ausfuehren? (j/n): " entry
  [[ "$entry" =~ ^[jJyY]$ ]] || return

  for index in "${selections[@]}"; do
    file="${files[$((index - 1))]}"; source_dir="$(dirname "$file")"; output="$OUT_DIR/$(basename "${file%.md}").$extension"
    local args=("$(basename "$file")" -o "$output" --syntax-highlighting=tango --resource-path=.)
    [[ "$format" == 1 ]] && { args+=("--pdf-engine=$TECTONIC"); [[ "$use_header" == true ]] && args+=(-H "$HEADER"); }
    if [[ "$mode" == 2 ]]; then
      log_file="$OUT_DIR/$(basename "${file%.md}").console.log"; args+=(--verbose "--log=$OUT_DIR/$(basename "${file%.md}").pandoc-log.json")
      (cd "$source_dir" && "$PANDOC" "${args[@]}") 2>&1 | tee "$log_file"; [[ ${PIPESTATUS[0]} -eq 0 ]] || echo "[FEHLER] Umwandlung fehlgeschlagen: $(basename "$file")"
    else
      (cd "$source_dir" && "$PANDOC" "${args[@]}") && echo "[OK] Fertig: $output"
    fi
  done
}

merge_files() {
  local dirs=() files=() entry selected toc output resource_path dir file use_header=false
  [[ -d "$MERGE_DIR" ]] || fail "Ordner merge fehlt."
  shopt -s nullglob
  dirs=("$MERGE_DIR"/*/)
  shopt -u nullglob
  echo "Ordner unter merge/:"; echo "  0) Benutzerdefinierter absoluter Pfad"
  for entry in "${!dirs[@]}"; do printf '  %d) %s\n' "$((entry + 1))" "$(basename "${dirs[$entry]}")"; done
  read -r -p "Ordnernummer (ENTER = Abbruch): " entry; [[ -n "$entry" ]] || return
  if [[ "$entry" == 0 ]]; then read -r -p "Absoluten Pfad eingeben: " selected; else [[ "$entry" =~ ^[0-9]+$ ]] && ((entry >= 1 && entry <= ${#dirs[@]})) || { echo "[FEHLER] Ungueltige Auswahl."; return; }; selected="${dirs[$((entry - 1))]}"; fi
  [[ -d "$selected" ]] || { echo "[FEHLER] Ordner nicht gefunden: $selected"; return; }
  while IFS= read -r file; do files+=("$file"); done < <(find "$selected" -type f -name '*.md' -print | sort)
  ((${#files[@]})) || { echo "[INFO] Keine Markdown-Dateien gefunden."; return; }
  read -r -p "Inhaltsverzeichnis hinzufuegen? (j/n): " toc
  if [[ -f "$HEADER" ]]; then
    read -r -p "Standardformatierung aus Formatierung/header.tex verwenden? (J/n): " entry
    [[ ! "$entry" =~ ^[nN]$ ]] && use_header=true
  else
    echo "[WARNUNG] Formatierung/header.tex nicht gefunden."
  fi
  output="$selected/$(basename "$selected").pdf"; resource_path="$selected"
  for file in "${files[@]}"; do dir="$(dirname "$file")"; [[ ":$resource_path:" == *":$dir:"* ]] || resource_path+=":$dir"; done
  read -r -p "Ausfuehren? (j/n): " entry; [[ "$entry" =~ ^[jJyY]$ ]] || return
  local args=("${files[@]}" -o "$output" "--pdf-engine=$TECTONIC" --syntax-highlighting=tango "--resource-path=$resource_path")
  [[ "$toc" =~ ^[jJyY]$ ]] && args+=(--toc); [[ "$use_header" == true ]] && args+=(-H "$HEADER")
  "$PANDOC" "${args[@]}" && echo "[OK] Fertig: $output"
}

if [[ -z "$ACTION" ]]; then
  echo "Pandoc fuer $PLATFORM"
  echo "  1) Einzelne Markdown-Dateien konvertieren"
  echo "  2) Markdown-Dateien zusammenfuehren"
  read -r -p "Auswahl: " ACTION
fi

case "$ACTION" in
  1|convert|makepdf) convert_files ;;
  2|merge|merge2pdf) merge_files ;;
  *) echo "Abgebrochen." ;;
esac
