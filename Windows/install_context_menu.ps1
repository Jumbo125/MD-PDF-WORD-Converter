$ErrorActionPreference = 'Stop'
$menuKey = 'Registry::HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.md\shell\ConvertWithPandoc'
$scriptPath = Join-Path $PSScriptRoot 'powershell\convert-context.ps1'
$pandocIcon = Join-Path (Split-Path -Parent $PSScriptRoot) 'pandoc\windows\pandoc.exe'
$powerShell = (Get-Command powershell.exe -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw "Konvertierungsskript fehlt: $scriptPath" }

New-Item -Path $menuKey -Force | Out-Null
New-ItemProperty -Path $menuKey -Name 'MUIVerb' -Value 'Convert with Pandoc' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $menuKey -Name 'Icon' -Value $pandocIcon -PropertyType String -Force | Out-Null
# Ein leerer SubCommands-Wert kennzeichnet diesen Eintrag explizit als
# Untermenü. Die eigentlichen Befehle liegen unten in shell\... .
New-ItemProperty -Path $menuKey -Name 'SubCommands' -Value '' -PropertyType String -Force | Out-Null

foreach ($item in @(
    @{ Key = 'ConvertToPdfStandard'; Label = 'Convert to PDF (Standardformatierung)'; Format = 'pdf'; UseStandardFormatting = $true },
    @{ Key = 'ConvertToPdfPlain'; Label = 'Convert to PDF (ohne Standardformatierung)'; Format = 'pdf'; UseStandardFormatting = $false },
    @{ Key = 'ConvertToWord'; Label = 'Convert to Word (.docx)'; Format = 'docx'; UseStandardFormatting = $false }
)) {
    $itemKey = Join-Path $menuKey ("shell\" + $item.Key)
    $commandKey = Join-Path $itemKey 'command'
    New-Item -Path $commandKey -Force | Out-Null
    New-ItemProperty -Path $itemKey -Name 'MUIVerb' -Value $item.Label -PropertyType String -Force | Out-Null
    $formattingArgument = if ($item.UseStandardFormatting) { ' -UseStandardFormatting' } else { '' }
    $command = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" -InputFile "%1" -Format {2}{3}' -f $powerShell, $scriptPath, $item.Format, $formattingArgument
    Set-Item -Path $commandKey -Value $command
}

Write-Host '[OK] Kontextmenue fuer Markdown-Dateien installiert.' -ForegroundColor Green
Write-Host 'Windows 11: Das Menue erscheint ggf. unter "Weitere Optionen anzeigen".'
