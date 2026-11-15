$ErrorActionPreference = 'Stop'
$menuKey = 'Registry::HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.md\shell\ConvertWithPandoc'

if (Test-Path -LiteralPath $menuKey) {
    Remove-Item -LiteralPath $menuKey -Recurse -Force
    Write-Host '[OK] Kontextmenue entfernt.' -ForegroundColor Green
}
else {
    Write-Host '[INFO] Kein Kontextmenue gefunden.'
}
