Option Explicit

Dim shell, root

Set shell = CreateObject("WScript.Shell")
root = "C:\Users\jlemo\OneDrive\Desktop\openchamber"
shell.CurrentDirectory = root

' Kill existing processes on ports 3000, 3901, 5173
shell.Run "powershell -NoProfile -WindowStyle Hidden -Command " & _
    """netstat -aon | Select-String ':3000 |:3901 |:5173 ' | ForEach-Object { " & _
    "$line = $_ -replace '\s+',' '; $parts = $line.Split(' '); " & _
    "$pid = $parts[4]; try { Stop-Process -Id ([int]$pid) -Force -ErrorAction Stop } catch {} }""", 0, True

WScript.Sleep 1500

' Launch OpenChamber Desktop (no console window)
shell.Run "bun run electron:dev:bundled", 1, False

Set shell = Nothing
