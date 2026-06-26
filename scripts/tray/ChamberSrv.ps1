# ChamberSrv.ps1 - Tray app para OpenChamber
# Gestiona start/stop/restart de Chamber desde la bandeja del sistema.
# Lanzar via: powershell -WindowStyle Hidden -File ChamberSrv.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Config ──────────────────────────────────────────────────
$ROOT = "C:\Users\jlemo\OneDrive\Desktop\openchamber"
$PORT = 3000
$URL  = "http://localhost:$PORT"
$LOGFILE = "$ROOT\scripts\tray\ChamberSrv.log"

Set-Location $ROOT
$global:chamberProcess = $null
$global:watchdogEnabled = $true

# ── Icono ───────────────────────────────────────────────────
function Get-TrayIcon {
    $bmp = New-Object System.Drawing.Bitmap(32, 32)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = "HighQuality"
    $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
    $g.FillEllipse([System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.PointF]::new(4,4), [System.Drawing.PointF]::new(28,28),
        [System.Drawing.Color]::FromArgb(255, 100, 140, 200),
        [System.Drawing.Color]::FromArgb(255, 60, 90, 150)
    ), 4, 4, 24, 24)
    $font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $g.DrawString("Ch", $font, [System.Drawing.Brushes]::White, [System.Drawing.PointF]::new(5, 5))
    $g.Dispose()
    $font.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHIcon())
}

# ── Process Management ──────────────────────────────────────
function Stop-Chamber {
    $tooltip = "Chamber - Deteniendo..."
    $global:watchdogEnabled = $false

    # Only kill processes related to THIS Chamber directory
    Get-CimInstance Win32_Process -Filter "Name='bun.exe' OR Name='electron.exe' OR Name='opencode.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match [regex]::Escape($ROOT) -or $_.ExecutablePath -match [regex]::Escape($ROOT) } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 2

    # Clean Chamber ports only if they're in use by this directory
    @($PORT, 3901, 5173) | ForEach-Object {
        $p = $_
        netstat -aon 2>$null | Select-String ":$p " | ForEach-Object {
            $line = $_ -replace '\s+', ' '
            $parts = $line.Split(' ')
            $pid = $parts[-1]
            try { Stop-Process -Id ([int]$pid) -Force -ErrorAction Stop } catch {}
        }
    }
    $global:chamberProcess = $null
    $notifyIcon.Text = "Chamber - Detenido"
}

function Test-ChamberRunning {
    $listening = netstat -aon 2>$null | Select-String ":$PORT " | Select-String "LISTENING"
    return ($listening -ne $null)
}

function Start-Chamber {
    # If Chamber is already running, just report it
    if (Test-ChamberRunning) {
        $notifyIcon.Text = "Chamber - $URL - Running"
        $notifyIcon.ShowBalloonTip(2000, "Chamber", "Ya esta corriendo en $URL", "Info")
        $global:watchdogEnabled = $true
        return
    }

    $notifyIcon.Text = "Chamber - Iniciando..."
    $global:watchdogEnabled = $true

    try {
        $procInfo = New-Object System.Diagnostics.ProcessStartInfo
        $procInfo.FileName = "bun"
        $procInfo.Arguments = "run electron:dev:bundled"
        $procInfo.WorkingDirectory = $ROOT
        $procInfo.UseShellExecute = $false
        $procInfo.CreateNoWindow = $true
        $procInfo.RedirectStandardOutput = $true
        $procInfo.RedirectStandardError = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $procInfo
        $proc.Start() | Out-Null
        $proc.BeginOutputReadLine()
        $proc.BeginErrorReadLine()

        $logDir = Split-Path $LOGFILE -Parent
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        "" | Set-Content $LOGFILE
        $proc.add_OutputDataReceived({
            if ($_.Data) { Add-Content $LOGFILE -Value "[$(Get-Date -Format 'HH:mm:ss')] $($_.Data)" }
        })
        $proc.add_ErrorDataReceived({
            if ($_.Data) { Add-Content $LOGFILE -Value "[$(Get-Date -Format 'HH:mm:ss') ERR] $($_.Data)" }
        })

        $global:chamberProcess = $proc
        Start-Sleep -Seconds 5

        if ($proc.HasExited) {
            $notifyIcon.Text = "Chamber - Error al iniciar"
            $notifyIcon.ShowBalloonTip(5000, "Chamber", "Error al iniciar. Revisar logs.", "Error")
        } else {
            $notifyIcon.Text = "Chamber - $URL - Running"
            $notifyIcon.ShowBalloonTip(3000, "Chamber", "✅ Iniciado en $URL", "Info")
        }
    } catch {
        $notifyIcon.Text = "Chamber - Error"
        $notifyIcon.ShowBalloonTip(5000, "Chamber", "Error: $_", "Error")
    }
}

function Restart-Chamber {
    $notifyIcon.ShowBalloonTip(2000, "Chamber", "Reiniciando...", "Info")
    Stop-Chamber
    Start-Sleep -Seconds 3
    Start-Chamber
}

# ── Tray Icon ───────────────────────────────────────────────
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = Get-TrayIcon
$notifyIcon.Text = "Chamber - Iniciando..."
$notifyIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$openItem = New-Object System.Windows.Forms.ToolStripMenuItem
$openItem.Text = "Abrir Chamber"
$openItem.Add_Click({ Start-Process $URL })
$contextMenu.Items.Add($openItem)

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$restartItem = New-Object System.Windows.Forms.ToolStripMenuItem
$restartItem.Text = "Reiniciar"
$restartItem.Add_Click({ Restart-Chamber })
$contextMenu.Items.Add($restartItem)

$stopItem = New-Object System.Windows.Forms.ToolStripMenuItem
$stopItem.Text = "Detener"
$stopItem.Add_Click({ Stop-Chamber; $notifyIcon.ShowBalloonTip(2000, "Chamber", "Servidor detenido", "Info") })
$contextMenu.Items.Add($stopItem)

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Cerrar"
$exitItem.Add_Click({
    $global:watchdogEnabled = $false
    Stop-Chamber
    $notifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.Items.Add($exitItem)

$notifyIcon.ContextMenuStrip = $contextMenu

# ── Watchdog ────────────────────────────────────────────────
$watchdogTimer = New-Object System.Windows.Forms.Timer
$watchdogTimer.Interval = 5000
$deadSince = $null
$watchdogTimer.Add_Tick({
    if (-not $global:watchdogEnabled) { return }
    if ($global:chamberProcess -eq $null) { return }

    if ($global:chamberProcess.HasExited) {
        if ($deadSince -eq $null) {
            $deadSince = Get-Date
        } elseif (((Get-Date) - $deadSince).TotalSeconds -gt 30) {
            $deadSince = $null
            $notifyIcon.ShowBalloonTip(3000, "Chamber", "Proceso detenido. Relanzando...", "Warning")
            Start-Chamber
        }
    } else {
        $deadSince = $null
    }
})
$watchdogTimer.Start()

# ── Form invisible (mantiene vivo el message pump) ───────────
$trayForm = New-Object System.Windows.Forms.Form
$trayForm.WindowState = "Minimized"
$trayForm.ShowInTaskbar = $false
$trayForm.add_Load({ $trayForm.Hide() })

# Actualizar el handler del item "Cerrar" para cerrar el form
$exitItem.Add_Click({
    $global:watchdogEnabled = $false
    Stop-Chamber
    $notifyIcon.Visible = $false
    $watchdogTimer.Stop()
    $trayForm.Close()
    [System.Windows.Forms.Application]::Exit()
})

# ── Startup ─────────────────────────────────────────────────
$trayForm.Show()
$watchdogTimer.Start()
Start-Chamber
[System.Windows.Forms.Application]::Run($trayForm)
