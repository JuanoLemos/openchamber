@echo off
title OpenChamber — Server
cd /d "%~dp0"

echo [1/3] Buscando procesos previos...
set KILLED=0
for /f "tokens=5" %%p in ('netstat -aon 2^>nul ^| findstr ":5173 " ^| findstr "LISTENING"') do (
    echo  Deteniendo PID %%p en puerto 5173
    taskkill /F /PID %%p >nul 2>&1
    set KILLED=1
)
for /f "tokens=5" %%p in ('netstat -aon 2^>nul ^| findstr ":3901 " ^| findstr "LISTENING"') do (
    echo  Deteniendo PID %%p en puerto 3901
    taskkill /F /PID %%p >nul 2>&1
    set KILLED=1
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

echo [3/3] Iniciando OpenChamber en http://127.0.0.1:5173
echo  Abri esa URL en el navegador. Cierra esta ventana para detener.
echo.
bun run dev
echo.
echo  El servidor se detuvo.
pause
