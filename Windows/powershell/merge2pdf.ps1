$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location -LiteralPath $scriptDir

# --- Checks ---
$pandocPath = Join-Path $scriptDir 'pandoc\windows\pandoc.exe'
if (-not (Test-Path -LiteralPath $pandocPath -PathType Leaf)) {
    Write-Host '[FEHLER] pandoc.exe fehlt in pandoc\windows\' -ForegroundColor Red
    Read-Host 'Enter druecken zum Beenden'
    exit 1
}

$mergeRoot = Join-Path $scriptDir 'merge'
if (-not (Test-Path -LiteralPath $mergeRoot -PathType Container)) {
    Write-Host '[FEHLER] Ordner merge\ fehlt im Projektordner' -ForegroundColor Red
    Read-Host 'Enter druecken zum Beenden'
    exit 1
}

# Engine
$tectonicPath = Join-Path $scriptDir 'tectonic\windows\tectonic.exe'
if (-not (Test-Path -LiteralPath $tectonicPath -PathType Leaf)) {
    Write-Host '[FEHLER] tectonic.exe fehlt in tectonic\windows\' -ForegroundColor Red
    Read-Host 'Enter druecken zum Beenden'
    exit 1
}
$engine = $tectonicPath

# Header
$headerArg = @()
$headerPath = Join-Path $scriptDir 'Formatierung\header.tex'
if (Test-Path -LiteralPath $headerPath -PathType Leaf) {
    $headerArg = @('-H', $headerPath)
}
else {
    Write-Host '[WARNUNG] Formatierung\header.tex nicht gefunden. (-H wird weggelassen)' -ForegroundColor Yellow
}

# --- Ordnerauswahl ---
Write-Host ''
Write-Host 'Verfuegbare Ordner unter merge\:'
Write-Host '  0  Benutzerdefinierter Ordner (absoluter Pfad)'

$dirs = Get-ChildItem -LiteralPath $mergeRoot -Directory | Sort-Object Name
if ($dirs.Count -eq 0) {
    Write-Host '[INFO] Keine Unterordner in merge\ gefunden.' -ForegroundColor Yellow
    Read-Host 'Enter druecken zum Beenden'
    exit 0
}

for ($i = 0; $i -lt $dirs.Count; $i++) {
    Write-Host "  $($i + 1)  $($dirs[$i].Name)"
}

# Eingabe Ordnernummer
while ($true) {
    Write-Host ''
    $choice = Read-Host 'Ordnernummer auswaehlen (ENTER = Abbruch)'

    if ([string]::IsNullOrWhiteSpace($choice)) {
        Write-Host 'Abgebrochen.'
        Read-Host 'Enter druecken zum Beenden'
        exit 0
    }

    $num = 0
    if (-not [int]::TryParse($choice.Trim(), [ref]$num)) {
        Write-Host "[FEHLER] Bitte eine Zahl eingeben (0..$($dirs.Count))." -ForegroundColor Red
        continue
    }

    if ($num -lt 0 -or $num -gt $dirs.Count) {
        Write-Host "[FEHLER] Nummer ausserhalb des gueltigen Bereichs (0..$($dirs.Count))." -ForegroundColor Red
        continue
    }

    if ($num -eq 0) {
        $custom = Read-Host 'Absoluten Pfad eingeben'
        if ([string]::IsNullOrWhiteSpace($custom)) {
            Write-Host '[FEHLER] Kein Pfad eingegeben.' -ForegroundColor Red
            continue
        }
        if (-not (Test-Path -LiteralPath $custom -PathType Container)) {
            Write-Host "[FEHLER] Ordner existiert nicht: $custom" -ForegroundColor Red
            continue
        }
        $selDir = (Resolve-Path -LiteralPath $custom).Path
    }
    else {
        $selDir = $dirs[$num - 1].FullName
    }

    break
}

Write-Host ''
Write-Host "Ausgewaehlter Ordner: $selDir"

# --- *.md sammeln + natuerlich sortieren ---
Write-Host ''
Write-Host 'Suche *.md Dateien (rekursiv) ...'

$mdFiles = Get-ChildItem -LiteralPath $selDir -Recurse -File -Filter '*.md' |
    Sort-Object @{
        Expression = { [regex]::Replace($_.Name, '\d+', { param($m) $m.Value.PadLeft(20, '0') }) }
    }, FullName

if ($mdFiles.Count -eq 0) {
    Write-Host '[INFO] Keine *.md Dateien gefunden.' -ForegroundColor Yellow
    Read-Host 'Enter druecken zum Beenden'
    exit 0
}

for ($i = 0; $i -lt $mdFiles.Count; $i++) {
    Write-Host "  $($i + 1)  $($mdFiles[$i].Name)"
}

# --- TOC ---
Write-Host ''
$tocInput = Read-Host 'Inhaltsverzeichnis (--toc) hinzufuegen? (J/N)'
$tocArg = @()
if ($tocInput.Trim().ToUpper() -eq 'J') {
    $tocArg = @('--toc')
}

# --- Output ---
$outBase = Split-Path -Leaf $selDir
if ([string]::IsNullOrWhiteSpace($outBase)) {
    $outBase = 'merged'
}
$outFile = Join-Path $selDir "$outBase.pdf"

# --- Resource paths fuer Bilder etc. ---
$resourceDirs = @($selDir) + @(
    $mdFiles |
    ForEach-Object { $_.DirectoryName } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique
)
$resourceDirs = $resourceDirs | Select-Object -Unique
$resourcePath = ($resourceDirs -join [IO.Path]::PathSeparator)

Write-Host ''
Write-Host 'Ressourcen-Suchpfade:'
foreach ($dir in $resourceDirs) {
    Write-Host "  $dir"
}

# --- Kommando zusammenbauen ---
$inFiles = $mdFiles | ForEach-Object { $_.FullName }

$pandocArgs = $inFiles + @(
    '-o', $outFile,
    "--pdf-engine=$engine",
    '--syntax-highlighting=tango',
    "--resource-path=$resourcePath"
) + $tocArg + $headerArg

Write-Host ''
Write-Host 'Fertige Syntax:'
Write-Host ('pandoc.exe ' + ($pandocArgs -join ' '))
Write-Host ''

$confirm = Read-Host 'Ausfuehren? (J/N)'
if ($confirm.Trim().ToUpper() -ne 'J') {
    Write-Host 'Nicht ausgefuehrt.'
    Read-Host 'Enter druecken zum Beenden'
    exit 0
}

Write-Host ''
Write-Host "[RUN] pandoc.exe ... -o $outFile"

& $pandocPath @pandocArgs

Write-Host ''
Write-Host "Fertig: $outFile" -ForegroundColor Green
Read-Host 'Enter druecken zum Beenden'
