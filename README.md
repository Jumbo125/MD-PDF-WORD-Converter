# Pandoc PDF Toolkit

Plattformübergreifendes Paket zum Konvertieren einzelner Markdown-Dateien und
zum Zusammenführen mehrerer Markdown-Dateien zu PDF oder DOCX.

## Warum dieses Projekt entstanden ist

Ich arbeite schon lange mit Pandoc. Bisher bestand mein persönlicher Workflow
vor allem aus einer BAT- beziehungsweise PowerShell-Datei, in der ich die zu
verarbeitenden Dateien jedes Mal einzeln aufgelistet habe. Das war für den
eigenen Gebrauch praktisch, aber nicht besonders bequem weiterzugeben.

Dieses Repository macht den Ablauf für andere verfügbar: Es bündelt die
benötigten Werkzeuge, bietet getrennte Startskripte für das Erstellen und
Zusammenführen von Dokumenten und ergänzt den Workflow um Einträge im
Kontextmenü. Damit lassen sich Markdown-Dateien direkt per Rechtsklick nach
PDF oder Word konvertieren, ohne vorhandene Dateien zu überschreiben.

Copyright (c) 2026 Andreas Rottmann

```mermaid
flowchart TD
    Input[input/ Markdown-Dateien] --> Windows[Windows]
    Input --> Linux[Linux]
    Input --> Mac[macOS]
    Windows --> WP[Windows/powershell/]
    WP --> PWin[pandoc/windows/pandoc.exe]
    WP --> TWin[tectonic/windows/tectonic.exe]
    Linux --> LS[Linux/makepdf.sh oder merge2pdf.sh]
    LS --> PLin[pandoc/linux/]
    LS --> TLin[tectonic/linux/]
    Mac --> MS[Mac/makepdf.sh oder merge2pdf.sh]
    MS --> PMac[pandoc/macos/]
    MS --> TMac[tectonic/macos/]
    PWin --> Output[out/ PDF oder DOCX]
    TWin --> Output
    PLin --> Output
    TLin --> Output
    PMac --> Output
    TMac --> Output
```

## Verwendung

### Windows

- Einzelne Dateien: `Windows\makepdf.bat`
- Markdown-Dateien zusammenführen: `Windows\merge2pdf.bat`

#### Kontextmenü für einzelne Markdown-Dateien

Mit `Windows\install_context_menu.ps1` kann für `.md`-Dateien das Kontextmenü
`Convert with Pandoc` installiert werden. Es enthält `Convert to PDF` und
`Convert to Word (.docx)`. Die Ausgabe wird neben der Originaldatei mit einem
Zeitstempel erzeugt, zum Beispiel `dokument_20261115-142530.pdf`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Windows\install_context_menu.ps1"
```

Entfernen mit:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Windows\uninstall_context_menu.ps1"
```

### Linux

Zuerst die enthaltenen Programme ohne Administratorrechte installieren:

```bash
bash Linux/install.sh
```

Danach starten:

```bash
bash Linux/makepdf.sh
bash Linux/merge2pdf.sh
```

Der Installer erkennt die Linux-Distribution und die Prozessorarchitektur. Er
unterstützt x86_64 sowie ARM64, zum Beispiel Raspberry Pi OS 64-Bit.

### macOS

```bash
bash Mac/makepdf.sh
bash Mac/merge2pdf.sh
```

#### Finder-Kontextmenü

Mit `bash Mac/install_context_menu.sh` werden zwei Finder-Schnellaktionen
installiert: `Convert with Pandoc - PDF` und `Convert with Pandoc - Word`.
Die Ausgabe wird neben der Originaldatei mit Zeitstempel erstellt. Entfernen
mit `bash Mac/uninstall_context_menu.sh`.

Für Intel-Macs sind Pandoc und Tectonic enthalten. Für Apple Silicon muss noch
die Pandoc-ARM64-Datei unter `pandoc/macos/arm64/bin/pandoc` abgelegt werden.

## Ordner

- `input/`: einzelne Markdown-Eingabedateien
- `merge/`: Ordner mit Markdown-Dateien zum Zusammenführen
- `out/`: erzeugte PDF- und DOCX-Dateien
- `Formatierung/header.tex`: optionale PDF-Formatierung
- `pandoc/` und `tectonic/`: Programme, getrennt nach Betriebssystem

## Lizenz

Dieses Projekt ist unter der **GNU General Public License v3.0** lizenziert.
Der vollständige Text steht in [LICENSE](LICENSE).

Die enthaltenen Drittprogramme bleiben unter ihren jeweiligen Lizenzen:
Pandoc unter GPL-2.0-or-later und Tectonic unter der MIT-Lizenz. Die zugehörigen
Lizenzhinweise in den jeweiligen Programmordnern müssen bei Weitergabe erhalten
bleiben.
