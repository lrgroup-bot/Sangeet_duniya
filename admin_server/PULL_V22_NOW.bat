@echo off
setlocal
cd /d "%~dp0\.."
echo Running safe v2.2 Git pull + server health check...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows_watchdog.ps1" -Mode PullOnce -RepoRoot "%CD%"
pause
endlocal
