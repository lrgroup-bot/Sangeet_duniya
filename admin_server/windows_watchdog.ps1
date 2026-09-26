# LR's Sangeet_Duniya v2.2 - Windows watchdog + safe pull
#
# Modes:
#   Install   Install/update the SYSTEM scheduled task and start it now.
#   Uninstall Remove the task and scoped firewall rule.
#   Run       Watchdog loop: health, restart, Tailscale check, safe auto-pull.
#   Check     One-shot diagnostics.
#   PullOnce  Safe fast-forward pull once, then ensure server is healthy.
#
# Safety:
# - Watches only admin_server/server.py on port 40425.
# - Never uses git reset, clean, checkout, rebase, or force.
# - Pulls only a clean tracked working tree and only by fast-forward.
# - Preserves admin_server/data, .runtime, and legacy .lrs-admin-data.
# - Never rewrites Tailscale Serve/Funnel configuration.

[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Run','Check','PullOnce','SelfTest')]
    [string]$Mode = 'Run',
    [string]$RepoRoot = '',
    [string]$Branch = '',
    [int]$Port = 40425,
    [int]$IntervalSeconds = 20,
    [int]$PullIntervalSeconds = 300,
    [switch]$NoAutoPull,
    [switch]$RepairTailscaleService
)

$ErrorActionPreference = 'Stop'
$CanonicalPort = 40425
$RequestedPort = $Port
$Port = $CanonicalPort
$TaskName = "LRs Sangeet_Duniya v2.2 Watchdog"
$OldTaskName = "LRs Sangeet_Duniya PC Admin Watchdog"
$FirewallRuleName = "LRs Sangeet_Duniya v2.2 Admin 40425"

function Resolve-RepoRoot {
    param([string]$Value)
    if ($Value) { return (Resolve-Path -LiteralPath $Value).Path }
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

$Root = Resolve-RepoRoot -Value $RepoRoot
$RuntimeRoot = Join-Path $Root '.runtime'
$LogFile = Join-Path $RuntimeRoot 'watchdog.log'
$ServerStdout = Join-Path $RuntimeRoot 'server.stdout.log'
$ServerStderr = Join-Path $RuntimeRoot 'server.stderr.log'
$PythonConfig = Join-Path $RuntimeRoot 'python.json'
$ServerScript = Join-Path $Root 'admin_server\server.py'
$DataDir = Join-Path $Root 'admin_server\data'

function Ensure-RuntimeRoot {
    New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    Ensure-RuntimeRoot
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
}

function Resolve-Branch {
    param([string]$Requested)
    if ($Requested) { return $Requested }
    try {
        $value = ((& git -C $Root branch --show-current 2>$null) | Out-String).Trim()
        if ($value) { return $value }
    } catch {}
    return 'feature/sangeet-duniya-v2.2-master'
}

$ConfiguredBranch = Resolve-Branch -Requested $Branch
$AutoPull = -not $NoAutoPull

function Get-PythonExecutable {
    Ensure-RuntimeRoot

    if (Test-Path -LiteralPath $PythonConfig) {
        try {
            $saved = Get-Content -LiteralPath $PythonConfig -Raw | ConvertFrom-Json
            if ($saved.Exe -and (Test-Path -LiteralPath $saved.Exe)) {
                return @{ Exe = [string]$saved.Exe; Prefix = @($saved.Prefix) }
            }
        } catch {}
    }

    $choices = @()
    try {
        $cmd = Get-Command python.exe -ErrorAction Stop
        if ($cmd.Source -and $cmd.Source -notmatch '\\WindowsApps\\') {
            $choices += @{ Exe = $cmd.Source; Prefix = @() }
        }
    } catch {}
    try {
        $cmd = Get-Command py.exe -ErrorAction Stop
        if ($cmd.Source) { $choices += @{ Exe = $cmd.Source; Prefix = @('-3') } }
    } catch {}

    foreach ($path in @(
        (Join-Path $env:LocalAppData 'Programs\Python\Python313\python.exe'),
        (Join-Path $env:LocalAppData 'Programs\Python\Python312\python.exe'),
        'C:\Program Files\Python313\python.exe',
        'C:\Program Files\Python312\python.exe'
    )) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            $choices += @{ Exe = $path; Prefix = @() }
        }
    }

    foreach ($choice in $choices) {
        if ($choice.Exe -and (Test-Path -LiteralPath $choice.Exe)) {
            @{ Exe = $choice.Exe; Prefix = @($choice.Prefix) } |
                ConvertTo-Json |
                Set-Content -LiteralPath $PythonConfig -Encoding UTF8
            return $choice
        }
    }

    throw "Python 3 was not found."
}

function Get-ServerProcesses {
    try {
        $escapedRoot = [regex]::Escape($Root)
        return @(Get-CimInstance Win32_Process | Where-Object {
            $_.Name -in @('python.exe','pythonw.exe','py.exe') -and
            $_.CommandLine -and
            $_.CommandLine -match 'admin_server[\\/]server\.py' -and
            $_.CommandLine -match $escapedRoot
        })
    } catch {
        return @()
    }
}

function Get-ProcessConfiguredPort {
    param($Process)
    if ($null -eq $Process -or -not $Process.CommandLine) { return $null }

    $match = [regex]::Match(
        [string]$Process.CommandLine,
        '(?:--port(?:=|\s+))(?<port>\d{2,5})'
    )
    if (-not $match.Success) { return $null }

    try { return [int]$match.Groups['port'].Value }
    catch { return $null }
}

function Repair-PortDrift {
    $processes = @(Get-ServerProcesses)
    $wrong = @($processes | Where-Object {
        $p = Get-ProcessConfiguredPort -Process $_
        $null -ne $p -and $p -ne $CanonicalPort
    })

    if ($wrong.Count -eq 0) { return $false }

    foreach ($p in $wrong) {
        $configured = Get-ProcessConfiguredPort -Process $p
        try {
            Stop-Process -Id ([int]$p.ProcessId) -Force -ErrorAction Stop
            Write-Log "PORT SELF-HEAL: stopped Sangeet server PID $($p.ProcessId) using non-canonical port $configured; canonical port is $CanonicalPort."
        } catch {
            Write-Log "WARNING: could not stop wrong-port PID $($p.ProcessId): $($_.Exception.Message)"
        }
    }

    return $true
}

function Test-HealthPayload {
    param($Result)
    if ($null -eq $Result) { return $false }
    $version = [string]$Result.version
    return (
        $Result.ok -eq $true -and
        $Result.app -eq "LR's Sangeet_Duniya" -and
        $version.StartsWith('2.')
    )
}

function Test-ServerHealth {
    try {
        $result = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 5 -Method Get
        return (Test-HealthPayload -Result $result)
    } catch {
        return $false
    }
}

function Stop-LrsServer {
    foreach ($p in @(Get-ServerProcesses)) {
        try {
            Stop-Process -Id ([int]$p.ProcessId) -Force -ErrorAction Stop
            Write-Log "Stopped v2.2 admin server PID $($p.ProcessId)."
        } catch {
            Write-Log "WARNING: Could not stop PID $($p.ProcessId): $($_.Exception.Message)"
        }
    }
}

function Start-LrsServer {
    Ensure-RuntimeRoot
    [void](Repair-PortDrift)
    if (Test-ServerHealth) { return $true }

    if (@(Get-ServerProcesses).Count -gt 0) {
        Write-Log "Server process exists but health failed; restarting only the v2.2 server."
        Stop-LrsServer
        Start-Sleep -Seconds 2
    }

    if (-not (Test-Path -LiteralPath $ServerScript)) {
        Write-Log "ERROR: Missing $ServerScript"
        return $false
    }

    $pythonInfo = Get-PythonExecutable
    $args = @()
    $args += $pythonInfo.Prefix
    $args += @('-u', $ServerScript, '--host', '0.0.0.0', '--port', "$Port", '--data-dir', $DataDir)

    Write-Log "Starting v2.2 PC Admin Server on 0.0.0.0:$Port using $($pythonInfo.Exe)."

    $start = @{
        FilePath = $pythonInfo.Exe
        ArgumentList = $args
        WorkingDirectory = $Root
        WindowStyle = 'Hidden'
        RedirectStandardOutput = $ServerStdout
        RedirectStandardError = $ServerStderr
    }
    Start-Process @start | Out-Null

    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 1
        if (Test-ServerHealth) {
            Write-Log "v2.2 PC Admin Server is healthy."
            return $true
        }
    }

    Write-Log "ERROR: Server did not become healthy. See $ServerStderr."
    return $false
}

function Get-GitHead {
    try { return ((& git -C $Root rev-parse HEAD 2>$null) | Out-String).Trim() }
    catch { return '' }
}

function Invoke-SafePull {
    param([string]$TargetBranch)

    try {
        $null = Get-Command git -ErrorAction Stop
    } catch {
        Write-Log "Auto-pull skipped: Git was not found."
        return @{ Changed = $false; Reason = 'git-not-found' }
    }

    try {
        $currentBranch = ((& git -C $Root branch --show-current 2>$null) | Out-String).Trim()
        if (-not $currentBranch) {
            Write-Log "Auto-pull skipped: detached HEAD."
            return @{ Changed = $false; Reason = 'detached-head' }
        }
        if ($currentBranch -ne $TargetBranch) {
            Write-Log "Auto-pull skipped: current '$currentBranch' != configured '$TargetBranch'."
            return @{ Changed = $false; Reason = 'branch-mismatch' }
        }

        $tracked = ((& git -C $Root status --porcelain --untracked-files=no 2>$null) | Out-String).Trim()
        if ($tracked) {
            Write-Log "Auto-pull skipped: tracked working tree contains local changes."
            return @{ Changed = $false; Reason = 'tracked-changes' }
        }

        $before = Get-GitHead

        # Git writes normal fetch progress ("From ...") to stderr. Windows
        # PowerShell can convert that into an ErrorRecord when the script uses
        # ErrorActionPreference=Stop, even though git exits successfully.
        # Suppress routine stderr here and trust the native exit code.
        $fetchOutput = ((& git -C $Root fetch --prune origin $TargetBranch 2>$null) | Out-String).Trim()
        $fetchExit = $LASTEXITCODE
        if ($fetchOutput) { Write-Log "git fetch: $fetchOutput" }
        if ($fetchExit -ne 0) {
            Write-Log "Auto-pull skipped: git fetch failed with exit code $fetchExit."
            return @{ Changed = $false; Reason = 'fetch-failed' }
        }

        $remoteRef = "origin/$TargetBranch"
        $remote = ((& git -C $Root rev-parse $remoteRef 2>$null) | Out-String).Trim()
        if (-not $remote -or $before -eq $remote) {
            return @{ Changed = $false; Reason = 'up-to-date' }
        }

        & git -C $Root merge-base --is-ancestor $before $remote 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Auto-pull skipped: update is not a fast-forward."
            return @{ Changed = $false; Reason = 'not-fast-forward' }
        }

        $mergeOutput = ((& git -C $Root merge --ff-only $remoteRef 2>$null) | Out-String).Trim()
        $mergeExit = $LASTEXITCODE
        if ($mergeOutput) { Write-Log "git merge: $mergeOutput" }
        if ($mergeExit -ne 0) {
            Write-Log "Auto-pull failed: ff-only merge returned exit code $mergeExit."
            return @{ Changed = $false; Reason = 'merge-failed' }
        }

        $after = Get-GitHead
        if ($after -and $after -ne $before) {
            Write-Log "Repository fast-forwarded: $before -> $after."
            return @{ Changed = $true; Reason = 'updated'; Before = $before; After = $after }
        }

        return @{ Changed = $false; Reason = 'up-to-date' }
    } catch {
        Write-Log "Auto-pull error: $($_.Exception.Message)"
        return @{ Changed = $false; Reason = 'exception' }
    }
}

function Check-TailscaleService {
    $service = Get-Service -Name 'Tailscale' -ErrorAction SilentlyContinue
    if (-not $service) { return 'not-installed' }
    if ($service.Status -eq 'Running') { return 'running' }

    if ($RepairTailscaleService) {
        try {
            Start-Service -Name 'Tailscale'
            Write-Log "Tailscale service restarted."
            return 'restarted'
        } catch {
            Write-Log "WARNING: Tailscale restart failed: $($_.Exception.Message)"
        }
    }
    return "$($service.Status)"
}

function Ensure-FirewallRule {
    try {
        $existing = Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue
        if (-not $existing) {
            $params = @{
                DisplayName = $FirewallRuleName
                Direction = 'Inbound'
                Action = 'Allow'
                Protocol = 'TCP'
                LocalPort = $Port
                RemoteAddress = @('LocalSubnet','100.64.0.0/10')
                Profile = 'Any'
            }
            New-NetFirewallRule @params | Out-Null
            Write-Log "Installed scoped firewall rule for LAN + Tailscale on $Port."
        }
    } catch {
        Write-Log "WARNING: Firewall rule not installed: $($_.Exception.Message)"
    }
}

function Remove-FirewallRule {
    try {
        Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue |
            Remove-NetFirewallRule -ErrorAction SilentlyContinue
    } catch {}
}

function Run-OneShotCheck {
    [void](Repair-PortDrift)
    $healthy = Test-ServerHealth
    $proc = @(Get-ServerProcesses)
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    Write-Host "LR's Sangeet_Duniya v2.2 PC Runtime"
    Write-Host "Repo       : $Root"
    Write-Host "Branch     : $ConfiguredBranch"
    Write-Host "HEAD       : $(Get-GitHead)"
    Write-Host "Health     : $(if ($healthy) {'HEALTHY'} else {'NOT HEALTHY'})"
    Write-Host "Port       : $Port (CANONICAL / LOCKED)"
    Write-Host "Server PID : $(if ($proc.Count) {(($proc | ForEach-Object ProcessId) -join ', ')} else {'NOT RUNNING'})"
    Write-Host "Task       : $(if ($task) {$task.State} else {'NOT INSTALLED'})"
    Write-Host "Auto-pull  : $AutoPull"
    Write-Host "Tailscale  : $(Check-TailscaleService)"
    Write-Host "Data       : $DataDir"
    Write-Host "Logs       : $RuntimeRoot"

    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 3
        Write-Host ""
        Write-Host "Health JSON:"
        $health | ConvertTo-Json -Depth 10
    } catch {}
}

function Install-Watchdog {
    Ensure-RuntimeRoot
    if (-not (Test-Path -LiteralPath $ServerScript)) {
        throw "Cannot install: $ServerScript does not exist."
    }

    $pythonInfo = Get-PythonExecutable
    Ensure-FirewallRule

    try {
        $null = Get-Command git -ErrorAction Stop
        & git config --system --add safe.directory $Root 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Registered repo as a system Git safe.directory for the SYSTEM watchdog."
        }
    } catch {
        Write-Log "WARNING: Could not register Git safe.directory: $($_.Exception.Message)"
    }

    Unregister-ScheduledTask -TaskName $OldTaskName -Confirm:$false -ErrorAction SilentlyContinue

    $scriptPath = $script:PSCommandPath
    $psArgs = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -Mode Run -RepoRoot "{1}" -Branch "{2}" -Port {3} -IntervalSeconds {4} -PullIntervalSeconds {5}' -f $scriptPath, $Root, $ConfiguredBranch, $CanonicalPort, $IntervalSeconds, $PullIntervalSeconds
    if ($NoAutoPull) { $psArgs += ' -NoAutoPull' }
    if ($RepairTailscaleService) { $psArgs += ' -RepairTailscaleService' }

    $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $psArgs
    $trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Seconds 20)
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)

    $register = @{
        TaskName = $TaskName
        Action = $action
        Trigger = $trigger
        Settings = $settings
        User = 'SYSTEM'
        RunLevel = 'Highest'
        Force = $true
    }
    Register-ScheduledTask @register | Out-Null

    if ($RequestedPort -ne $CanonicalPort) {
        Write-Log "PORT SELF-HEAL: requested port $RequestedPort ignored; canonical port $CanonicalPort enforced."
    }
    Write-Log "Installed '$TaskName'. Branch=$ConfiguredBranch Port=$CanonicalPort AutoPull=$AutoPull"
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 3

    Write-Host "Installed : $TaskName"
    Write-Host "Repo      : $Root"
    Write-Host "Branch    : $ConfiguredBranch"
    Write-Host "Port      : $Port"
    Write-Host "Python    : $($pythonInfo.Exe)"
    Write-Host "Auto-pull : $AutoPull (safe ff-only)"
    Write-Host "Old task  : removed if present"
    Write-Host ""
    Run-OneShotCheck
}

function Uninstall-Watchdog {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Remove-FirewallRule
    Write-Host "Removed: $TaskName"
    Write-Host "Server database, admin token, legacy data, and logs were preserved."
}

function Run-Watchdog {
    Ensure-RuntimeRoot
    Write-Log "Watchdog started. Repo=$Root Branch=$ConfiguredBranch Port=$Port AutoPull=$AutoPull"

    $lastHealthState = $null
    $lastPullCheck = [DateTime]::MinValue
    $lastTailscaleCheck = [DateTime]::MinValue

    while ($true) {
        try {
            [void](Repair-PortDrift)
            $health = Test-ServerHealth
            if ($health -ne $lastHealthState) {
                Write-Log ("Server health changed: " + $(if ($health) { 'HEALTHY' } else { 'NOT HEALTHY' }))
                $lastHealthState = $health
            }

            if (-not $health) {
                [void](Start-LrsServer)
                $lastHealthState = Test-ServerHealth
            }

            if ($AutoPull -and ((Get-Date) - $lastPullCheck).TotalSeconds -ge $PullIntervalSeconds) {
                $pull = Invoke-SafePull -TargetBranch $ConfiguredBranch
                if ($pull.Changed) {
                    Write-Log "Code updated; restarting v2.2 admin server."
                    Stop-LrsServer
                    [void](Start-LrsServer)
                }
                $lastPullCheck = Get-Date
            }

            if (((Get-Date) - $lastTailscaleCheck).TotalMinutes -ge 5) {
                Write-Log "Tailscale service: $(Check-TailscaleService)"
                $lastTailscaleCheck = Get-Date
            }
        } catch {
            Write-Log "Watchdog loop error: $($_.Exception.Message)"
        }

        Start-Sleep -Seconds $IntervalSeconds
    }
}

switch ($Mode) {
    'Install' { Install-Watchdog }
    'Uninstall' { Uninstall-Watchdog }
    'Run' { Run-Watchdog }
    'Check' { Run-OneShotCheck }
    'PullOnce' {
        $result = Invoke-SafePull -TargetBranch $ConfiguredBranch
        if ($result.Changed) { Stop-LrsServer }
        [void](Start-LrsServer)
        Run-OneShotCheck
    }
    'SelfTest' {
        $good = [pscustomobject]@{
            ok = $true
            app = "LR's Sangeet_Duniya"
            version = '2.2.0'
        }
        $badVersion = [pscustomobject]@{
            ok = $true
            app = "LR's Sangeet_Duniya"
            version = '1.9.9'
        }
        $badApp = [pscustomobject]@{
            ok = $true
            app = 'Wrong App'
            version = '2.2.0'
        }

        if (-not (Test-HealthPayload -Result $good)) {
            throw 'SelfTest failed: valid v2.2.0 health payload was rejected.'
        }
        if (Test-HealthPayload -Result $badVersion) {
            throw 'SelfTest failed: v1.x payload was accepted.'
        }
        if (Test-HealthPayload -Result $badApp) {
            throw 'SelfTest failed: wrong app payload was accepted.'
        }

        if ($CanonicalPort -ne 40425 -or $Port -ne 40425) {
            throw 'SelfTest failed: canonical port lock is not 40425.'
        }

        Write-Host 'WATCHDOG SELF-TEST PASSED'
    }
}
