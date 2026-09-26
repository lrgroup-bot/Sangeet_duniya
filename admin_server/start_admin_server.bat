@echo off
setlocal
cd /d "%~dp0"
echo Starting LR's Sangeet_Duniya v2.2 Admin Server...
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 server.py --host 0.0.0.0 --port 40425
) else (
  python server.py --host 0.0.0.0 --port 40425
)
endlocal
