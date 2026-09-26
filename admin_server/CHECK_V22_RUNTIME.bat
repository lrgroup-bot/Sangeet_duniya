@echo off
setlocal
cd /d "%~dp0\.."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows_watchdog.ps1" -Mode Check -RepoRoot "%CD%"
pause
endlocal
