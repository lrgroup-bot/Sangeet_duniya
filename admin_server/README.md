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
