param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [ValidateSet('pdf', 'docx')]
    [string]$Format,

    [switch]$UseStandardFormatting
)

$ErrorActionPreference = 'Stop'
$rootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pandoc = Join-Path $rootDir 'pandoc\windows\pandoc.exe'
$tectonic = Join-Path $rootDir 'tectonic\windows\tectonic.exe'
$header = Join-Path $rootDir 'Formatierung\header.tex'

if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) { throw "Eingabedatei nicht gefunden: $InputFile" }
if (-not (Test-Path -LiteralPath $pandoc -PathType Leaf)) { throw "pandoc.exe fehlt: $pandoc" }
if ($Format -eq 'pdf' -and -not (Test-Path -LiteralPath $tectonic -PathType Leaf)) { throw "tectonic.exe fehlt: $tectonic" }

$sourceFile = Get-Item -LiteralPath $InputFile
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$counter = 0
do {
    $suffix = if ($counter -eq 0) { "_$timestamp" } else { "_${timestamp}_$counter" }
    $outputFile = Join-Path $sourceFile.DirectoryName ($sourceFile.BaseName + $suffix + '.' + $Format)
    $counter++
} while (Test-Path -LiteralPath $outputFile)

$arguments = @($sourceFile.FullName, '-o', $outputFile, '--syntax-highlighting=tango', "--resource-path=$($sourceFile.DirectoryName)")
if ($Format -eq 'pdf') {
    $arguments += "--pdf-engine=$tectonic"
    if ($UseStandardFormatting) {
        if (-not (Test-Path -LiteralPath $header -PathType Leaf)) { throw "Standardformatierung fehlt: $header" }
        $arguments += @('-H', $header)
    }
}

& $pandoc @arguments
if ($LASTEXITCODE -ne 0) { throw "Pandoc wurde mit Exit-Code $LASTEXITCODE beendet." }
Write-Host "[OK] Erstellt: $outputFile" -ForegroundColor Green
