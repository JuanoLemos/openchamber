@echo off
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "scripts\tray\ChamberSrv.ps1"
pause
