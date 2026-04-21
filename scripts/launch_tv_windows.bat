@echo off
REM Lanzar TradingView Desktop con Chrome DevTools Protocol (CDP) habilitado
REM Ruta MSIX detectada automaticamente via PowerShell

set PORT=%1
if "%PORT%"=="" set PORT=9222

REM Cerrar instancias existentes
taskkill /F /IM TradingView.exe >nul 2>&1
timeout /t 2 /nobreak >nul

REM Detectar ruta via PowerShell (soporta instalaciones MSIX/Store)
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "(Get-AppxPackage *TradingView*).InstallLocation + '\TradingView.exe'"`) do set "TV_EXE=%%i"

if not exist "%TV_EXE%" (
    echo Error: TradingView Desktop no encontrado.
    echo Instala desde Microsoft Store o tradingview.com/desktop/
    pause
    exit /b 1
)

echo TradingView encontrado: %TV_EXE%
echo Iniciando con --remote-debugging-port=%PORT%...
start "" "%TV_EXE%" --remote-debugging-port=%PORT%

echo Esperando que CDP este disponible...
timeout /t 5 /nobreak >nul

:check
curl -s http://localhost:%PORT%/json/version >nul 2>&1
if %errorlevel% neq 0 (
    echo Esperando...
    timeout /t 2 /nobreak >nul
    goto check
)

echo.
echo CDP listo en http://localhost:%PORT%
curl -s http://localhost:%PORT%/json/version
echo.
echo TradingView MCP listo para usar en Claude Code.
pause
