Option Explicit
Dim shell, root
Set shell = CreateObject("WScript.Shell")
root = "C:\Users\jlemo\OneDrive\Desktop\openchamber"
shell.CurrentDirectory = root
shell.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & root & "\scripts\tray\ChamberSrv.ps1", 0, False
Set shell = Nothing
