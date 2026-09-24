# LR's Sangeet_Duniya - Windows PC server watchdog
#
# Modes:
#   -Mode Install   Register an auto-start Windows Scheduled Task.
#   -Mode Uninstall Remove that task.
#   -Mode Run       Run the watchdog loop.
#   -Mode Check     One-shot diagnostic check.
#
# This script restarts only the LRS Python server when its /health endpoint fails.
# It never resets or rewrites Tailscale Serve/Funnel configuration.
#
# Run Install from an elevated PowerShell.

[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Run','Check')]
    [string]$Mode = 'Run',
    [string]$RepoRoot = '',
    [int]$Port = 40426,
    [int]$IntervalSeconds = 20,
    [switch]$RepairTailscaleService
)

$ErrorActionPreference = 'Stop'
$TaskName = "LRs Sangeet_Duniya PC Admin Watchdog"
$StateRoot = 'E:\LRS-Sangeet-Duniya'
$LogFile = Join-Path $StateRoot 'watchdog.log'
$ServerStdout = Join-Path $StateRoot 'server.stdout.log'
$ServerStderr = Join-Path $StateRoot 'server.stderr.log'
$PythonConfig = Join-Path $StateRoot 'python.json'

function Resolve-RepoRoot {
    param([string]$Value)
    if ($Value) { return (Resolve-Path -LiteralPath $Value).Path }
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Ensure-StateRoot {
    if (-not (Test-Path -LiteralPath $StateRoot)) {
        New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null
    }
}

function Write-Log {
    param([string]$Message)
    Ensure-StateRoot
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $LogFile -Value $line
}

function Get-PythonExecutable {
    if (Test-Path -LiteralPath $PythonConfig) {
        try {
            $saved = Get-Content -LiteralPath $PythonConfig -Raw | ConvertFrom-Json
            if ($saved.Exe -and (Test-Path -LiteralPath $saved.Exe)) {
                return @{ Exe = [string]$saved.Exe; Prefix = @($saved.Prefix) }
            }
        } catch {}
    }

    $candidates = @()
    try {
        $cmd = Get-Command python.exe -ErrorAction Stop
        if ($cmd.Source -and $cmd.Source -notmatch '\\WindowsApps\\') { $candidates += $cmd.Source }
    } catch {}
    try {
        $cmd = Get-Command py.exe -ErrorAction Stop
        if ($cmd.Source) { $candidates += $cmd.Source }
    } catch {}

    $candidates += @(
        (Join-Path $env:LocalAppData 'Programs\Python\Python313\python.exe'),
        (Join-Path $env:LocalAppData 'Programs\Python\Python312\python.exe'),
        'C:\Program Files\Python313\python.exe',
        'C:\Program Files\Python312\python.exe'
    )

    foreach ($path in $candidates | Select-Object -Unique) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            if ([IO.Path]::GetFileName($path) -ieq 'python.exe') {
                return @{ Exe = $path; Prefix = @() }
            }
            if ([IO.Path]::GetFileName($path) -ieq 'py.exe') {
                return @{ Exe = $path; Prefix = @('-3') }
            }
        }
    }

    throw "Python 3 was not found."
}

function Get-TailscaleExecutable {
    $paths = @()
    try {
        $cmd = Get-Command tailscale.exe -ErrorAction Stop
        if ($cmd.Source) { $paths += $cmd.Source }
    } catch {}

    $paths += @(
        'C:\Program Files\Tailscale\tailscale.exe',
        'C:\Program Files (x86)\Tailscale\tailscale.exe'
    )

    foreach ($path in $paths | Select-Object -Unique) {
        if ($path -and (Test-Path -LiteralPath $path)) { return $path }
    }
    return $null
}

function Get-ServerProcesses {
    try {
        return @(Get-CimInstance Win32_Process |
            Where-Object {
                $_.Name -in @('python.exe','pythonw.exe','py.exe') -and
                $_.CommandLine -and
                $_.CommandLine -match 'tailscale_admin_server\.py'
            })
    } catch {
        return @()
    }
}

function Test-ServerHealth {
    try {
        $result = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 5 -Method Get
        return ($result.ok -eq $true -and $result.app -eq "LRs Sangeet_Duniya")
    } catch {
        return $false
    }
}

function Start-LrsServer {
    param([string]$Root)

    if (Test-ServerHealth) { return $true }

    $proc = @(Get-ServerProcesses)
    if ($proc.Count -gt 0) {
        Write-Log "LRS server process exists but /health is failing. Restarting our server process."
        foreach ($p in $proc) {
            try {
                Stop-Process -Id ([int]$p.ProcessId) -Force -ErrorAction Stop
            } catch {
                Write-Log "Could not stop stale LRS server PID $($p.ProcessId): $($_.Exception.Message)"
            }
        }
        Start-Sleep -Seconds 2
    }

    $pythonInfo = Get-PythonExecutable
    $scriptPath = Join-Path $Root 'tools\tailscale_admin_server.py'
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Log "ERROR: $scriptPath was not found."
        return $false
    }

    $dataDir = Join-Path $Root '.lrs-admin-data'
    if (-not (Test-Path -LiteralPath $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    $args = @()
    $args += $pythonInfo.Prefix
    $args += @(
        $scriptPath,
        '--host', '127.0.0.1',
        '--port', "$Port",
        '--data-dir', $dataDir
    )

    Write-Log "Starting LRS PC Admin Server on 127.0.0.1:$Port using $($pythonInfo.Exe)."

    $startParams = @{
        FilePath = $pythonInfo.Exe
        ArgumentList = $args
        WorkingDirectory = $Root
        WindowStyle = 'Hidden'
        RedirectStandardOutput = $ServerStdout
        RedirectStandardError = $ServerStderr
    }
    Start-Process @startParams | Out-Null

    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        if (Test-ServerHealth) {
            Write-Log "LRS PC Admin Server is healthy."
            return $true
        }
    }

    Write-Log "ERROR: LRS PC Admin Server did not become healthy within 10 seconds. See $ServerStderr."
    return $false
}

function Run-TailscaleCommand {
    param([string[]]$Arguments)
    $exe = Get-TailscaleExecutable
    if (-not $exe) { return 'Tailscale executable not found' }
    try {
        return ((& $exe @Arguments 2>&1) | Out-String).Trim()
    } catch {
        return "ERROR: $($_.Exception.Message)"
    }
}

function Check-TailscaleService {
    $service = Get-Service -Name 'Tailscale' -ErrorAction SilentlyContinue
    if (-not $service) { return 'Tailscale Windows service not found' }

    if ($service.Status -eq 'Running') { return 'Running' }

    if ($RepairTailscaleService) {
        try {
            Start-Service -Name 'Tailscale'
            Write-Log 'Tailscale Windows service was stopped; started because -RepairTailscaleService was supplied.'
            return 'Restarted'
        } catch {
            Write-Log "WARNING: Tailscale service is $($service.Status), but auto-start failed: $($_.Exception.Message)"
        }
    }

    return "$($service.Status) (not modified)"
}

function Run-OneShotCheck {
    $root = Resolve-RepoRoot -Value $RepoRoot
    Write-Host "LR's Sangeet_Duniya Windows Checker"
    Write-Host "Repo : $root"
    Write-Host "Port : $Port"
    Write-Host ""

    $healthy = Test-ServerHealth
    Write-Host ("PC Admin Server : " + $(if ($healthy) { 'HEALTHY' } else { 'NOT HEALTHY' }))

    $proc = @(Get-ServerProcesses)
    if ($proc.Count -eq 0) {
        Write-Host "Server process  : NOT RUNNING"
    } else {
        Write-Host ("Server process  : RUNNING (PID " + (($proc | ForEach-Object ProcessId) -join ', ') + ")")
    }

    Write-Host ("Tailscale service: " + (Check-TailscaleService))
    Write-Host ""
    Write-Host "Tailscale status:"
    Write-Host (Run-TailscaleCommand @('status'))
    Write-Host ""
    Write-Host "Serve status:"
    Write-Host (Run-TailscaleCommand @('serve','status'))
    Write-Host ""
    Write-Host "Funnel status:"
    Write-Host (Run-TailscaleCommand @('funnel','status'))
    Write-Host ""
    Write-Host "Logs:"
    Write-Host "  $LogFile"
    Write-Host "  $ServerStdout"
    Write-Host "  $ServerStderr"
}

function Install-Watchdog {
    $root = Resolve-RepoRoot -Value $RepoRoot
    Ensure-StateRoot

    $pythonInfo = Get-PythonExecutable
    Ensure-StateRoot
    @{ Exe = $pythonInfo.Exe; Prefix = @($pythonInfo.Prefix) } | ConvertTo-Json | Set-Content -LiteralPath $PythonConfig -Encoding UTF8
    $serverPath = Join-Path $root 'tools\tailscale_admin_server.py'
    if (-not (Test-Path -LiteralPath $serverPath)) {
        throw "Cannot install watchdog: $serverPath does not exist."
    }

    $scriptPath = $MyInvocation.MyCommand.Path
    $psArgs = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -Mode Run -RepoRoot "{1}" -Port {2} -IntervalSeconds {3}' -f $scriptPath, $root, $Port, $IntervalSeconds
    if ($RepairTailscaleService) { $psArgs += ' -RepairTailscaleService' }

    $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $psArgs
    $trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Seconds 30)
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)

    $registerParams = @{
        TaskName = $TaskName
        Action = $action
        Trigger = $trigger
        Settings = $settings
        User = 'SYSTEM'
        RunLevel = 'Highest'
        Force = $true
    }
    Register-ScheduledTask @registerParams | Out-Null

    Write-Log "Installed or updated scheduled task '$TaskName'."
    Write-Host "Installed: $TaskName"
    Write-Host "Python   : $($pythonInfo.Exe)"
    Write-Host "Repo     : $root"
    Write-Host "Port     : $Port"
    Write-Host "Startup  : Windows startup + 30-second delay"
    Write-Host "Check    : every $IntervalSeconds seconds"
    Write-Host "Tailscale: existing Serve/Funnel configuration is not changed"
}

function Uninstall-Watchdog {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Removed: $TaskName"
    Write-Host "Tailscale Serve/Funnel configuration was not changed."
}

function Run-Watchdog {
    $root = Resolve-RepoRoot -Value $RepoRoot
    Ensure-StateRoot
    Write-Log "Watchdog started. Repo=$root Port=$Port Interval=$IntervalSeconds seconds"

    $lastTailscaleCheck = [DateTime]::MinValue
    $lastHealthState = $null
    $lastTailscaleSummary = $null

    while ($true) {
        try {
            $health = Test-ServerHealth

            if ($health -ne $lastHealthState) {
                Write-Log ("PC Admin Server health changed: " + $(if ($health) { 'HEALTHY' } else { 'NOT HEALTHY' }))
                $lastHealthState = $health
            }

            if (-not $health) {
                [void](Start-LrsServer -Root $root)
            }

            if ((Get-Date) - $lastTailscaleCheck -ge (New-TimeSpan -Minutes 5)) {
                $serviceState = Check-TailscaleService
                $tsStatus = Run-TailscaleCommand @('status')
                $serve = Run-TailscaleCommand @('serve','status')
                $funnel = Run-TailscaleCommand @('funnel','status')

                $serveLine = (($serve -split '\r?\n') | Where-Object { $_.Trim() } | Select-Object -First 3) -join ' | '
                $funnelLine = (($funnel -split '\r?\n') | Where-Object { $_.Trim() } | Select-Object -First 3) -join ' | '
                $summary = "$serviceState | Serve: $serveLine | Funnel: $funnelLine"

                if ($summary -ne $lastTailscaleSummary) {
                    Write-Log "Tailscale check: $summary"
                    $lastTailscaleSummary = $summary
                }

                $lastTailscaleCheck = Get-Date
            }
        } catch {
            Write-Log "Watchdog loop error: $($_.Exception.Message)"
        }

        Start-Sleep -Seconds $IntervalSeconds
    }
}

switch ($Mode) {
    'Install'   { Install-Watchdog }
    'Uninstall' { Uninstall-Watchdog }
    'Check'     { Run-OneShotCheck }
    'Run'       { Run-Watchdog }
}
