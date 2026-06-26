@echo off
cd /d "%~dp0..\.."
start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "scripts\tray\ChamberSrv.ps1"
exit
