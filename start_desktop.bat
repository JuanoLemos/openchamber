@echo off
title OpenChamber — Desktop
cd /d "%~dp0"

echo [1/3] Buscando procesos previos...
set KILLED=0
for /f "tokens=5" %%p in ('netstat -aon 2^>nul ^| findstr ":3000 " ^| findstr "LISTENING"') do (
    echo  Deteniendo PID %%p en puerto 3000
    taskkill /F /PID %%p >nul 2>&1 && set KILLED=1
)
for /f "tokens=5" %%p in ('netstat -aon 2^>nul ^| findstr ":3901 " ^| findstr "LISTENING"') do (
    echo  Deteniendo PID %%p en puerto 3901
    taskkill /F /PID %%p >nul 2>&1 && set KILLED=1
)
for /f "tokens=5" %%p in ('netstat -aon 2^>nul ^| findstr ":5173 " ^| findstr "LISTENING"') do (
    echo  Deteniendo PID %%p en puerto 5173
    taskkill /F /PID %%p >nul 2>&1 && set KILLED=1
)
if %KILLED%==0 echo  Ningun proceso previo encontrado.
timeout /t 1 /nobreak >nul

echo [2/3] Verificando Bun...
where bun >nul 2>&1
if errorlevel 1 (
    echo ERROR: Bun no esta instalado.
    echo  Instalalo con: npm install -g bun
    pause
    exit /b 1
)
echo  Bun OK.

echo [3/3] Verificando Electron...
if not exist "node_modules\.bun\electron@41.2.1\node_modules\electron\dist\electron.exe" (
    echo  Binario de Electron no encontrado. Reinstalando...
    call bun install
    if errorlevel 1 (
        echo ERROR: No se pudo instalar Electron.
        pause
        exit /b 1
    )
)
echo  Electron OK.
echo.

echo Iniciando OpenChamber Desktop...
echo  Cierra la ventana de la app para detener el servidor.
echo.
bun run electron:dev:bundled
echo.
echo  El servidor se detuvo.
pause
