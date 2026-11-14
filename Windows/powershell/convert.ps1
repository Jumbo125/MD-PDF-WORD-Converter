$Host.UI.RawUI.WindowTitle = "Pandoc MD->PDF/DOCX"

$rootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location -LiteralPath $rootDir

$pandoc        = Join-Path $rootDir 'pandoc\windows\pandoc.exe'
$inputDir      = Join-Path $rootDir 'input'
$outDir        = Join-Path $rootDir 'out'
$header        = Join-Path $rootDir 'Formatierung\header.tex'
$tectonicLocal = Join-Path $rootDir 'tectonic\windows\tectonic.exe'

if (-not (Test-Path -LiteralPath $pandoc)) {
    Write-Host "[FEHLER] pandoc.exe fehlt in pandoc\windows\"
    exit 1
}

if (-not (Test-Path -LiteralPath $inputDir)) {
    Write-Host "[FEHLER] Ordner input\ fehlt"
    exit 1
}

if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

if (-not (Test-Path -LiteralPath $tectonicLocal -PathType Leaf)) {
    Write-Host "[FEHLER] tectonic.exe fehlt in tectonic\windows\"
    exit 1
}

$engine = $tectonicLocal

function Read-FileSelection {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Files
    )

    $sel = Read-Host "Nummer(n) auswaehlen (z.B. 1;3;5) (ENTER oder q = Ende)"

    if ([string]::IsNullOrWhiteSpace($sel) -or $sel -eq 'q') {
        return $null
    }

    $parts = $sel -split ';'
    $indexes = @()

    foreach ($part in $parts) {
        $part = $part.Trim()

        if ([string]::IsNullOrWhiteSpace($part)) {
            continue
        }

        $index = 0
        if (-not [int]::TryParse($part, [ref]$index)) {
            Write-Host "[FEHLER] Ungueltige Eingabe: $part"
            return @()
        }

        if ($index -lt 1 -or $index -gt $Files.Count) {
            Write-Host "[FEHLER] Nummer ausserhalb des Bereichs: $index"
            return @()
        }

        if ($indexes -notcontains $index) {
            $indexes += $index
        }
    }

    return $indexes
}

function Read-ModeSelection {
    Write-Host ""
    Write-Host "Modus:"
    Write-Host "  1) Normal"
    Write-Host "  2) Mit Log/Debug"
    Write-Host ""

    $mode = Read-Host "Modus auswaehlen"

    switch ($mode) {
        '1' { return 'normal' }
        '2' { return 'log' }
        default {
            Write-Host "[FEHLER] Bitte 1 oder 2 eingeben."
            return $null
        }
    }
}

function Read-FormatSelection {
    Write-Host ""
    Write-Host "Zielformat:"
    Write-Host "  1) PDF"
    Write-Host "  2) Word (.docx)"
    Write-Host ""

    $format = Read-Host "Zielformat auswaehlen"

    switch ($format) {
        '1' { return 'pdf' }
        '2' { return 'docx' }
        default {
            Write-Host "[FEHLER] Bitte 1 oder 2 eingeben."
            return $null
        }
    }
}

while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "Dateien in `"$inputDir`" (*.md), sortiert nach Erstellungsdatum:"
    Write-Host ""

    $files = Get-ChildItem -LiteralPath $inputDir -Filter '*.md' -File |
             Sort-Object CreationTime -Descending

    if (-not $files -or $files.Count -eq 0) {
        Write-Host "[INFO] Keine *.md Dateien in input\ gefunden."
        break
    }

    for ($i = 0; $i -lt $files.Count; $i++) {
        $n = $i + 1
        Write-Host ("  {0}) {1}    [erstellt: {2:yyyy-MM-dd HH:mm:ss}]" -f $n, $files[$i].Name, $files[$i].CreationTime)
    }

    Write-Host ""
    $useHeader = Test-Path -LiteralPath $header
    if (-not $useHeader) {
        Write-Host "[WARNUNG] header.tex nicht gefunden. (nur fuer PDF relevant)"
    }

    Write-Host ""
    $indexes = Read-FileSelection -Files $files

    if ($null -eq $indexes) {
        Write-Host "Abgebrochen."
        break
    }

    if ($indexes.Count -eq 0) {
        Start-Sleep -Seconds 1
        continue
    }

    $format = Read-FormatSelection
    if ($null -eq $format) {
        Start-Sleep -Seconds 1
        continue
    }

    $mode = Read-ModeSelection
    if ($null -eq $mode) {
        Start-Sleep -Seconds 1
        continue
    }

    Write-Host ""
    Write-Host "Ausgewaehlte Dateien:"
    foreach ($index in $indexes) {
        $file = $files[$index - 1]
        Write-Host ("  {0}) {1}" -f $index, $file.Name)
    }

    Write-Host ""
    Write-Host ("Zielformat: {0}" -f ($(if ($format -eq 'pdf') { 'PDF' } else { 'Word (.docx)' })))

    if ($mode -eq 'log') {
        Write-Host "Log/Debug: EIN"
    } else {
        Write-Host "Log/Debug: AUS"
    }

    Write-Host ""
    $run = Read-Host "Ausfuehren? (j/n)"
    if ($run -notin @('j','J','y','Y')) {
        continue
    }

    foreach ($index in $indexes) {
        $file       = $files[$index - 1]
        $sourceDir  = $file.DirectoryName
        $inputName  = $file.Name
        $extension  = if ($format -eq 'pdf') { '.pdf' } else { '.docx' }
        $outfile    = Join-Path $outDir ($file.BaseName + $extension)
        $jsonLog    = Join-Path $outDir ($file.BaseName + '.pandoc-log.json')
        $consoleLog = Join-Path $outDir ($file.BaseName + '.console.log')
        $debugTex   = Join-Path $outDir ($file.BaseName + '.debug.tex')

        $args = @(
            $inputName
            '-o'
            $outfile
            '--syntax-highlighting=tango'
            '--resource-path=.'
        )

        if ($format -eq 'pdf') {
            $args += "--pdf-engine=$engine"

            if ($useHeader) {
                $args += @('-H', $header)
            }
        }

        if ($mode -eq 'log') {
            $args += @('--verbose', "--log=$jsonLog")
        }

        Write-Host ""
        Write-Host ('[RUN] Arbeitsordner: "{0}"' -f $sourceDir)
        Write-Host ('[RUN] pandoc.exe "{0}" -o "{1}" --resource-path=.' -f $inputName, $outfile)

        if ($mode -eq 'log') {
            if (Test-Path -LiteralPath $consoleLog) {
                Remove-Item -LiteralPath $consoleLog -Force
            }

            Push-Location -LiteralPath $sourceDir
            try {
                & $pandoc @args 2>&1 | Tee-Object -FilePath $consoleLog
                $exitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }
        }
        else {
            Push-Location -LiteralPath $sourceDir
            try {
                & $pandoc @args
                $exitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }
        }

        Write-Host ""
        if ($exitCode -eq 0) {
            Write-Host ('[OK] Fertig: "{0}"' -f $outfile)

            if ($mode -eq 'log') {
                Write-Host ('[LOG] JSON: "{0}"' -f $jsonLog)
                Write-Host ('[LOG] Konsole: "{0}"' -f $consoleLog)
            }
        }
        else {
            Write-Host ('[FEHLER] Umwandlung fehlgeschlagen: "{0}" (ExitCode: {1})' -f $file.Name, $exitCode)

            if ($mode -eq 'log') {
                Write-Host ('[LOG] JSON: "{0}"' -f $jsonLog)
                Write-Host ('[LOG] Konsole: "{0}"' -f $consoleLog)

                if ($format -eq 'pdf') {
                    $debugArgs = @(
                        $inputName
                        '-s'
                        '-o'
                        $debugTex
                        '--syntax-highlighting=tango'
                        '--resource-path=.'
                        '--verbose'
                        "--log=$jsonLog"
                    )

                    if ($useHeader) {
                        $debugArgs += @('-H', $header)
                    }

                    Write-Host '[INFO] Erzeuge Debug-TEX...'
                    Push-Location -LiteralPath $sourceDir
                    try {
                        & $pandoc @debugArgs *> $null
                        $debugExit = $LASTEXITCODE
                    }
                    finally {
                        Pop-Location
                    }

                    if ($debugExit -eq 0) {
                        Write-Host ('[LOG] Debug-TEX: "{0}"' -f $debugTex)
                    }
                    else {
                        Write-Host '[INFO] Debug-TEX konnte nicht erzeugt werden.'
                    }
                }
            }
        }
    }

    Write-Host ""
    [void](Read-Host "ENTER fuer zurueck zur Liste")
}
