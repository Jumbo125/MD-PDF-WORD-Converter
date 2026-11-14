@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0powershell\merge2pdf.ps1"
set "rc=%errorlevel%"
if not "%rc%"=="0" (
  echo.
  echo [FEHLER] merge2pdf.ps1 wurde mit Exit-Code %rc% beendet.
  pause
)
exit /b %rc%
