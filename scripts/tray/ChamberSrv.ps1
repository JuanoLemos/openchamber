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
$global:chamberPid = $null
$global:startedAt = $null
$global:watchdogEnabled = $true

# ── Logging ──────────────────────────────────────────────
function Log-Event($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LOGFILE -Value "$ts $msg"
}

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
    $global:watchdogEnabled = $false
    $notifyIcon.Text = "Chamber - Deteniendo..."
    Log-Event "STOP iniciado"

    Get-Process -Name "bun", "electron" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    @($PORT, 3901, 5173) | ForEach-Object {
        $p = $_
        netstat -aon 2>$null | Select-String ":$p " | ForEach-Object {
            $line = $_ -replace '\s+', ' '
            $pid = $line.Split(' ')[-1]
            try { Stop-Process -Id ([int]$pid) -Force -ErrorAction Stop } catch {}
        }
    }
    $global:chamberPid = $null
    $notifyIcon.Text = "Chamber - Detenido"
    Log-Event "STOP completado"
}

function Test-ChamberRunning {
    $listening = netstat -aon 2>$null | Select-String ":$PORT " | Select-String "LISTENING"
    return ($listening -ne $null)
}

function Start-Chamber {
    if (Test-ChamberRunning) {
        $notifyIcon.Text = "Chamber - $URL"
        if (-not $global:startedAt) { $global:startedAt = Get-Date }
        $notifyIcon.ShowBalloonTip(2000, "Chamber", "Ya esta corriendo en $URL", "Info")
        $global:watchdogEnabled = $true
        Log-Event "START saltado — ya corriendo en :$PORT"
        return
    }

    $notifyIcon.Text = "Chamber - Iniciando..."
    $global:watchdogEnabled = $true
    Log-Event "START iniciando bun run electron:dev:bundled"

    try {
        $procInfo = New-Object System.Diagnostics.ProcessStartInfo
        $procInfo.FileName = "bun"
        $procInfo.Arguments = "run electron:dev:bundled"
        $procInfo.WorkingDirectory = $ROOT
        $procInfo.UseShellExecute = $false
        $procInfo.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $procInfo
        $proc.Start() | Out-Null
        $global:chamberPid = $proc.Id
        Start-Sleep -Seconds 8

        if (Test-ChamberRunning) {
            $global:startedAt = Get-Date
            $notifyIcon.Text = "Chamber - $URL"
            $notifyIcon.ShowBalloonTip(3000, "Chamber", "Iniciado en $URL", "Info")
            Log-Event "START exitoso — PID $($global:chamberPid) escuchando en :$PORT"
        } else {
            $notifyIcon.Text = "Chamber - Iniciando (puede tardar)..."
            Log-Event "START en espera — proceso lanzado pero :$PORT aún no responde"
        }
    } catch {
        $notifyIcon.Text = "Chamber - Error"
        $notifyIcon.ShowBalloonTip(5000, "Chamber", "Error: $_", "Error")
        Log-Event "START ERROR: $_"
    }
}

function Restart-Chamber {
    $notifyIcon.ShowBalloonTip(2000, "Chamber", "Reiniciando...", "Info")
    Log-Event "RESTART iniciado"
    Stop-Chamber
    Start-Sleep -Seconds 3
    Start-Chamber
    Log-Event "RESTART completado"
}

function Build-UI {
    $notifyIcon.ShowBalloonTip(2000, "Chamber", "🔨 Rebuild UI iniciado...", "Info")
    try {
        $procInfo = New-Object System.Diagnostics.ProcessStartInfo
        $procInfo.FileName = "bun"
        $procInfo.Arguments = "run build:ui"
        $procInfo.WorkingDirectory = $ROOT
        $procInfo.UseShellExecute = $false
        $procInfo.RedirectStandardOutput = $true
        $procInfo.RedirectStandardError = $true
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $procInfo
        $proc.Start() | Out-Null
        $proc.WaitForExit()
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LOGFILE -Value "$timestamp BUILD:UI exit=$($proc.ExitCode)`n$stdout`n$stderr"
        if ($proc.ExitCode -eq 0) {
            $notifyIcon.ShowBalloonTip(3000, "Chamber", "✅ UI rebuild completada", "Info")
        } else {
            $lastErr = if ($stderr) { ($stderr -split "`n")[-2] } else { "Error desconocido" }
            $notifyIcon.ShowBalloonTip(5000, "Chamber", "❌ Rebuild error: $lastErr", "Error")
        }
    } catch {
        $notifyIcon.ShowBalloonTip(5000, "Chamber", "❌ Error: $_", "Error")
    }
}

function RebuildAndRestart {
    Build-UI
    Start-Sleep -Seconds 2
    Restart-Chamber
}

function Start-HMR {
    try {
        Start-Process -NoNewWindow "powershell" -ArgumentList "-NoProfile -Command `"cd '$ROOT'; bun run dev:web:hmr`"" -WindowStyle Hidden
        Start-Sleep -Seconds 3
        Start-Process "http://127.0.0.1:5173"
        $notifyIcon.ShowBalloonTip(3000, "Chamber", "🌐 HMR iniciado en http://127.0.0.1:5173", "Info")
    } catch {
        $notifyIcon.ShowBalloonTip(5000, "Chamber", "Error al iniciar HMR: $_", "Error")
    }
}

# ── Tray Icon ───────────────────────────────────────────────
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = Get-TrayIcon
$notifyIcon.Text = "Chamber - Iniciando..."
$notifyIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$openItem = New-Object System.Windows.Forms.ToolStripMenuItem
$openItem.Text = "Abrir Chamber"
$openItem.Add_Click({ 
    if (Test-ChamberRunning) {
        Log-Event "ABRIR — :$PORT ya corriendo, abriendo navegador"
        Start-Process "http://localhost:$PORT"
    } else {
        Log-Event "ABRIR — :$PORT libre, iniciando Chamber"
        Start-Chamber
    }
})
$contextMenu.Items.Add($openItem)

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$restartItem = New-Object System.Windows.Forms.ToolStripMenuItem
$restartItem.Text = "Reiniciar"
$restartItem.Add_Click({ Restart-Chamber })
$contextMenu.Items.Add($restartItem)

$rebuildRestartItem = New-Object System.Windows.Forms.ToolStripMenuItem
$rebuildRestartItem.Text = "Reiniciar + Rebuild"
$rebuildRestartItem.Add_Click({ RebuildAndRestart })
$contextMenu.Items.Add($rebuildRestartItem)

$stopItem = New-Object System.Windows.Forms.ToolStripMenuItem
$stopItem.Text = "Detener"
$stopItem.Add_Click({ Stop-Chamber; $notifyIcon.ShowBalloonTip(2000, "Chamber", "Servidor detenido", "Info") })
$contextMenu.Items.Add($stopItem)

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$rebuildItem = New-Object System.Windows.Forms.ToolStripMenuItem
$rebuildItem.Text = "Rebuild UI"
$rebuildItem.Add_Click({ Build-UI })
$contextMenu.Items.Add($rebuildItem)

$hmrItem = New-Object System.Windows.Forms.ToolStripMenuItem
$hmrItem.Text = "Abrir Dev HMR (5173)"
$hmrItem.Add_Click({ Start-HMR })
$contextMenu.Items.Add($hmrItem)

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
$tickCount = 0
$healthOk = $true
$watchdogTimer.Add_Tick({
    if (-not $global:watchdogEnabled) { return }
    $tickCount++

    # Live tooltip data
    if ($global:chamberPid -ne $null) {
        $running = Test-ChamberRunning
        $memStr = ""
        $uptimeStr = ""

        try {
            $ps = Get-Process -Id $global:chamberPid -ErrorAction Stop
            $memMb = [math]::Round($ps.WorkingSet64 / 1MB, 0)
            $memStr = "$memMb MB"
        } catch {}

        if ($global:startedAt) {
            $uptime = (Get-Date) - $global:startedAt
            if ($uptime.TotalMinutes -lt 1) {
                $uptimeStr = "$([math]::Round($uptime.TotalSeconds, 0))s"
            } elseif ($uptime.TotalHours -lt 1) {
                $uptimeStr = "$($uptime.Minutes)m"
            } else {
                $uptimeStr = "$($uptime.Hours)h $($uptime.Minutes)m"
            }
        }

        if ($running) {
            $tooltip = "Chamber :$PORT"
            if ($memStr) { $tooltip += " | $memStr" }
            if ($uptimeStr) { $tooltip += " | $uptimeStr" }
            $notifyIcon.Text = $tooltip
        } else {
            $notifyIcon.Text = "Chamber - Sin respuesta :$PORT"
        }
    }

    # Watchdog: auto-relanzar si muere

    # Health check cada 60s (cada 12 ticks)
    if ($tickCount % 12 -eq 0 -and $global:chamberPid -ne $null -and (Test-ChamberRunning)) {
        try {
            $health = Invoke-RestMethod -Uri "http://localhost:$PORT/health" -TimeoutSec 5 -ErrorAction Stop
            if (-not $healthOk) {
                $healthOk = $true
                $notifyIcon.ShowBalloonTip(3000, "Chamber", "Salud recuperada", "Info")
            }
        } catch {
            if ($healthOk) {
                $healthOk = $false
                $notifyIcon.ShowBalloonTip(5000, "Chamber", "Sin respuesta en :$PORT", "Warning")
            }
        }
    }

    # Watchdog: auto-relanzar si muere
    if ($global:chamberPid -eq $null) { return }

    $alive = try { Get-Process -Id $global:chamberPid -ErrorAction Stop | Out-Null; $true } catch { $false }
    if (-not $alive) {
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
# El form ya está Minimized + ShowInTaskbar=$false. No necesita Hide().

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
