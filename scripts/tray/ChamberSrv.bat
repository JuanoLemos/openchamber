@echo off
cd /d "%~dp0..\.."
start "" powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\tray\ChamberSrv.ps1"
exit
