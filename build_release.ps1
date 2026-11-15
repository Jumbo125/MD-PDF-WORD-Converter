param(
    [string]$Version,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'release')
)

# Erstellt alle Betriebssystem-Releases, unabhängig von Windows.
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Read-Host 'Versionsnummer eingeben (z.B. 1.0.0)'
}
$Version = $Version.Trim() -replace '^[vV]', ''
if ($Version -notmatch '^\d+(\.\d+)*$') {
    throw "Ungueltige Versionsnummer: $Version"
}

function Copy-RequiredItem {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Erforderliche Datei oder Ordner fehlt: $Source"
    }
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function New-ReleaseArchive {
    param(
        [Parameter(Mandatory = $true)][string]$OsName
    )

    $stageDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("pandoc-pdf-toolkit-$OsName-" + [Guid]::NewGuid())
    $archiveName = "pandoc-pdf-toolkit-V$Version-$OsName.zip"
    $archivePath = Join-Path $OutputDirectory $archiveName
    $hashPath = "$archivePath.sha256"

    try {
        New-Item -ItemType Directory -Path $stageDirectory -Force | Out-Null
        foreach ($document in @('README.md', 'README.txt', 'LICENSE')) {
            Copy-RequiredItem (Join-Path $PSScriptRoot $document) (Join-Path $stageDirectory $document)
        }
        Copy-RequiredItem (Join-Path $PSScriptRoot 'Formatierung') (Join-Path $stageDirectory 'Formatierung')
        Copy-RequiredItem (Join-Path $PSScriptRoot "pandoc\$OsName") (Join-Path $stageDirectory "pandoc\$OsName")
        Copy-RequiredItem (Join-Path $PSScriptRoot "tectonic\$OsName") (Join-Path $stageDirectory "tectonic\$OsName")

        if ($OsName -in @('linux', 'macos')) {
            Copy-RequiredItem (Join-Path $PSScriptRoot 'Linux\pandoc-tool.sh') (Join-Path $stageDirectory 'Linux\pandoc-tool.sh')
        }
        if ($OsName -eq 'macos') {
            Copy-RequiredItem (Join-Path $PSScriptRoot 'Mac') (Join-Path $stageDirectory 'Mac')
        }
        if ($OsName -eq 'windows') {
            Copy-RequiredItem (Join-Path $PSScriptRoot 'makepdf.bat') (Join-Path $stageDirectory 'makepdf.bat')
            Copy-RequiredItem (Join-Path $PSScriptRoot 'merge2pdf.bat') (Join-Path $stageDirectory 'merge2pdf.bat')
        }
        else {
            Copy-RequiredItem (Join-Path $PSScriptRoot 'makepdf.sh') (Join-Path $stageDirectory 'makepdf.sh')
            Copy-RequiredItem (Join-Path $PSScriptRoot 'merge2pdf.sh') (Join-Path $stageDirectory 'merge2pdf.sh')
        }
        if ($OsName -eq 'linux') {
            Copy-RequiredItem (Join-Path $PSScriptRoot 'install.sh') (Join-Path $stageDirectory 'install.sh')
            Copy-RequiredItem (Join-Path $PSScriptRoot 'Linux\install.sh') (Join-Path $stageDirectory 'Linux\install.sh')
        }
        if ($OsName -eq 'windows') {
            Copy-RequiredItem (Join-Path $PSScriptRoot 'Windows') (Join-Path $stageDirectory 'Windows')
        }

        foreach ($workDirectory in @('input', 'merge', 'out')) {
            $target = Join-Path $stageDirectory $workDirectory
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $target '.gitkeep') -Force | Out-Null
        }

        Remove-Item -LiteralPath $archivePath, $hashPath -Force -ErrorAction SilentlyContinue
        Compress-Archive -Path (Join-Path $stageDirectory '*') -DestinationPath $archivePath -CompressionLevel Optimal
        $hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-Content -LiteralPath $hashPath -Value "$hash  $archiveName" -NoNewline
        Write-Host "[OK] $archiveName"
    }
    finally {
        if (Test-Path -LiteralPath $stageDirectory) {
            Remove-Item -LiteralPath $stageDirectory -Recurse -Force
        }
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
New-ReleaseArchive -OsName 'windows'
New-ReleaseArchive -OsName 'linux'
New-ReleaseArchive -OsName 'macos'
Write-Host "[OK] Alle Release-Archive und SHA-256-Dateien liegen in: $OutputDirectory"
