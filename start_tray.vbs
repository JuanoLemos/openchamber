Option Explicit
Dim shell, root
Set shell = CreateObject("WScript.Shell")
root = "C:\Users\jlemo\OneDrive\Desktop\openchamber"
shell.CurrentDirectory = root
shell.Run "scripts\tray\ChamberSrv.bat", 0, False
Set shell = Nothing
