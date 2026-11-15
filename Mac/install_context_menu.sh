#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONVERTER="$ROOT_DIR/Mac/convert-context.sh"
SERVICES_DIR="$HOME/Library/Services"

[[ "$(uname -s)" == "Darwin" ]] || { echo "[FEHLER] Nur unter macOS ausfuehren." >&2; exit 1; }
[[ -f "$CONVERTER" ]] || { echo "[FEHLER] Konvertierungsskript fehlt: $CONVERTER" >&2; exit 1; }
chmod +x "$CONVERTER"
mkdir -p "$SERVICES_DIR"

create_workflow() {
  local name="$1" format="$2" bundle="$SERVICES_DIR/$name.workflow"
  rm -rf "$bundle"
  mkdir -p "$bundle/Contents"
  cat > "$bundle/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.pandoc-toolkit.${format}</string>
<key>CFBundleName</key><string>${name}</string>
<key>CFBundlePackageType</key><string>BNDL</string>
<key>CFBundleVersion</key><string>1.0</string>
</dict></plist>
PLIST
  cat > "$bundle/Contents/document.wflow" <<WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>AMApplicationBuild</key><array><string>523</string></array>
<key>AMApplicationVersion</key><string>2.10</string>
<key>AMDocumentVersion</key><string>2</string>
<key>actions</key><array><dict><key>action</key><dict>
<key>AMAccepts</key><dict><key>Container</key><string>List</string><key>Optional</key><true/><key>Types</key><array><string>com.apple.cocoa.string</string></array></dict>
<key>AMActionVersion</key><string>2.0.3</string><key>AMApplication</key><array><string>Automator</string></array>
<key>AMProvides</key><dict><key>Container</key><string>List</string><key>Types</key><array><string>com.apple.cocoa.string</string></array></dict>
<key>ActionBundlePath</key><string>/System/Library/Automator/Run Shell Script.action</string><key>ActionName</key><string>Run Shell Script</string>
<key>ActionParameters</key><dict><key>COMMAND_STRING</key><string><![CDATA["$CONVERTER" $format "\$@"]]></string><key>inputMethod</key><integer>1</integer><key>shell</key><string>/bin/bash</string><key>source</key><string></string></dict>
<key>BundleIdentifier</key><string>com.apple.RunShellScript</string><key>CFBundleVersion</key><string>2.0.3</string><key>Class Name</key><string>RunShellScriptAction</string>
</dict><key>isViewVisible</key><true/></dict></array>
<key>workflowMetaData</key><dict>
<key>applicationBundleID</key><string>com.apple.finder</string><key>applicationPath</key><string>/System/Library/CoreServices/Finder.app</string>
<key>inputTypeIdentifier</key><string>com.apple.Automator.fileSystemObject</string><key>outputTypeIdentifier</key><string>com.apple.Automator.nothing</string>
<key>serviceApplicationBundleID</key><string>com.apple.finder</string><key>serviceInputTypeIdentifier</key><string>com.apple.Automator.fileSystemObject</string>
<key>workflowTypeIdentifier</key><string>com.apple.Automator.servicesMenu</string>
</dict></dict></plist>
WFLOW
}

create_workflow 'Convert with Pandoc - PDF' pdf
create_workflow 'Convert with Pandoc - Word' docx
killall Finder 2>/dev/null || true
echo '[OK] Finder-Schnellaktionen installiert.'
