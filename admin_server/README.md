# Sangeet_Duniya v2.2 Windows PC Admin Server

This is the local-first activation authority for LR's Sangeet_Duniya.

## Capabilities

- Runs on the Windows PC with Python 3 only.
- Stores activation codes and devices in a local SQLite database.
- Generates six-digit activation codes.
- Supports 7, 14, 30, 90, 180, 365 day and Lifetime validity.
- Starts the validity countdown on the first successful activation.
- Supports multiple phones up to the device limit selected for each code.
- Works on the same Wi-Fi network or through the PC's Tailscale address.
- Provides a local dashboard for codes, users, devices, countdowns and revocation.
- Uses no Supabase, Vercel or cloud database.

## Start on Windows

Double-click `start_admin_server.bat`, or run:

```powershell
py -3 admin_server\server.py --host 0.0.0.0 --port 40425
```

On first start the server creates its SQLite data directory and a random local admin login token. The console prints that token.

Open the dashboard on the PC:

```text
http://127.0.0.1:40425/
```

## Connect a phone

On the app activation screen enter either the PC's same-Wi-Fi IPv4 address, such as `192.168.1.10:40425`, or its Tailscale IPv4 address, such as `100.x.x.x:40425`. Then enter the six-digit code created in the PC dashboard.

Tailscale encrypts traffic between Tailscale peers. Plain HTTP on the local Wi-Fi should only be used on a trusted private LAN.

The generated database and admin-login token are runtime data and must not be committed to Git.


## Windows watchdog + safe Git pull

v2.2 includes `admin_server/windows_watchdog.ps1`.

It watches the **v2.2** server only:

- process: `admin_server/server.py`
- health: `http://127.0.0.1:40425/health`
- port: `40425`
- data: `admin_server/data`
- runtime logs: `.runtime`

The watchdog removes the obsolete scheduled task named
`LRs Sangeet_Duniya PC Admin Watchdog` if it exists. It does not delete the old
`.lrs-admin-data` directory.

Install from an **elevated PowerShell / Administrator** terminal:

```powershell
cd E:\LRS-Sangeet-Duniya
powershell -ExecutionPolicy Bypass -File .\admin_server\windows_watchdog.ps1 -Mode Install
```

Or run `admin_server\INSTALL_V22_WATCHDOG.bat` as Administrator.

The scheduled task:

- starts at Windows boot,
- checks health every 20 seconds,
- restarts the v2.2 server if it stops responding,
- checks Tailscale service state every 5 minutes,
- creates a scoped firewall rule for TCP 40425 from LocalSubnet and the
  Tailscale CGNAT range `100.64.0.0/10`,
- checks Git for updates every 5 minutes by default.

### Safe pull behavior

Auto-update is intentionally conservative. It will update only when all of the
following are true:

1. the repository is on the branch captured when the watchdog was installed,
2. tracked files have no local modifications,
3. `git fetch` succeeds,
4. the remote branch is a strict fast-forward of the current local HEAD.

The watchdog never performs `git reset`, `git clean`, `git checkout`,
`git rebase` or a forced update. Untracked runtime files therefore cannot be
silently deleted.

After a successful fast-forward update, only the v2.2 admin-server process is
restarted. SQLite data and the admin token remain in `admin_server/data`.

Run a one-shot update and health check:

```powershell
powershell -ExecutionPolicy Bypass -File .\admin_server\windows_watchdog.ps1 -Mode PullOnce
```

Run diagnostics without modifying Git:

```powershell
powershell -ExecutionPolicy Bypass -File .\admin_server\windows_watchdog.ps1 -Mode Check
```

Disable Git auto-pull while keeping health recovery:

```powershell
powershell -ExecutionPolicy Bypass -File .\admin_server\windows_watchdog.ps1 -Mode Install -NoAutoPull
```

Uninstall the scheduled task and firewall rule:

```powershell
powershell -ExecutionPolicy Bypass -File .\admin_server\windows_watchdog.ps1 -Mode Uninstall
```

Uninstalling never deletes the SQLite database, admin token, legacy data or logs.


## Canonical port policy

**TCP 40425 is the permanent canonical LR's Sangeet_Duniya v2.2 admin-server port.**
The app, Windows watchdog, health checks and firewall rule all use 40425.

The watchdog treats port drift as a recoverable fault:

- a Sangeet `admin_server/server.py` process launched with a different `--port`
  is detected and stopped,
- the canonical server is kept/restarted on `0.0.0.0:40425`,
- passing another `-Port` value to the watchdog does not migrate the runtime;
  40425 is enforced,
- SQLite data and the admin token are not changed during port repair.

A port migration must therefore be an explicit future application-version change,
not an accidental runtime setting.
