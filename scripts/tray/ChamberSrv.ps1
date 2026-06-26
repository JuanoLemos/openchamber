# ChamberSrv.ps1 — Tray app para OpenChamber
# Gestiona start/stop/restart de Chamber desde la bandeja del sistema.
# Lanzar via: powershell -WindowStyle Hidden -File ChamberSrv.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Config ──────────────────────────────────────────────────
$ROOT = "C:\Users\jlemo\OneDrive\Desktop\openchamber"
$PORT = 3000
$URL  = "http://localhost:$PORT"

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
    $tooltip = "Chamber — Deteniendo..."
    $global:watchdogEnabled = $false

    # Kill by process name
    @("bun", "electron", "opencode") | ForEach-Object {
        Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Seconds 2

    # Clean ports
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
    $notifyIcon.Text = "Chamber — Detenido"
}

function Start-Chamber {
    $notifyIcon.Text = "Chamber — Iniciando..."

    # Kill orphaned processes first
    Stop-Chamber
    Start-Sleep -Seconds 2

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

        $global:chamberProcess = $proc
        Start-Sleep -Seconds 5

        if ($proc.HasExited) {
            $notifyIcon.Text = "Chamber — Error al iniciar"
            $notifyIcon.ShowBalloonTip(5000, "Chamber", "Error al iniciar. Revisar logs.", "Error")
        } else {
            $notifyIcon.Text = "Chamber — $URL — Running"
            $notifyIcon.ShowBalloonTip(3000, "Chamber", "✅ Iniciado en $URL", "Info")
        }
    } catch {
        $notifyIcon.Text = "Chamber — Error"
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
$notifyIcon.Text = "Chamber — Iniciando..."
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

# ── Startup ─────────────────────────────────────────────────
Start-Chamber
[System.Windows.Forms.Application]::Run()
