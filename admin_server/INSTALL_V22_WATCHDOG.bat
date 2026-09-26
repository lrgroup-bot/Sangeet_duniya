@echo off
setlocal
cd /d "%~dp0\.."
echo Installing LR's Sangeet_Duniya v2.2 watchdog...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows_watchdog.ps1" -Mode Install -RepoRoot "%CD%"
echo.
echo If Windows requested administrator permission, approve it.
pause
endlocal
