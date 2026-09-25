#!/usr/bin/env python3
"""LR's Sangeet_Duniya v2.2 local Windows admin server.

Uses only the Python standard library. Data is stored in a local SQLite file.
Bind to 0.0.0.0 to make the server reachable from same-Wi-Fi devices and the
PC's Tailscale address. No cloud database is used.
"""

from __future__ import annotations

import argparse
import hmac
import html
import json
import os
import re
import secrets
import sqlite3
import threading
import time
from datetime import datetime, timedelta, timezone
from http import cookies
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, quote, urlparse

APP_NAME = "LR's Sangeet_Duniya"
VERSION = "2.2.0"
DEFAULT_PORT = 40425
PLAN_DAYS = {
    "sevenDays": 7,
    "fourteenDays": 14,
    "thirtyDays": 30,
    "ninetyDays": 90,
    "oneHundredEightyDays": 180,
    "oneYear": 365,
    "lifetime": None,
}
PLAN_LABELS = {
    "sevenDays": "7 Days",
    "fourteenDays": "14 Days",
    "thirtyDays": "30 Days",
    "ninetyDays": "90 Days",
    "oneHundredEightyDays": "180 Days",
    "oneYear": "365 Days",
    "lifetime": "Lifetime",
}


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def iso(value: datetime | None) -> str | None:
    return value.isoformat().replace("+00:00", "Z") if value else None


def parse_iso(value: str | None) -> datetime | None:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(
        timezone.utc
    )


class AdminDatabase:
    def __init__(self, path: Path):
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._init_schema()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.path, timeout=10)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        return connection

    def _init_schema(self) -> None:
        with self._connect() as db:
            db.executescript(
                """
                CREATE TABLE IF NOT EXISTS activation_codes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    code TEXT NOT NULL UNIQUE,
                    name TEXT NOT NULL DEFAULT '',
                    phone TEXT NOT NULL DEFAULT '',
                    plan TEXT NOT NULL,
                    duration_days INTEGER,
                    created_at TEXT NOT NULL,
                    activated_at TEXT,
                    expires_at TEXT,
                    max_devices INTEGER NOT NULL DEFAULT 5,
                    revoked INTEGER NOT NULL DEFAULT 0
                );

                CREATE TABLE IF NOT EXISTS devices (
                    activation_id TEXT PRIMARY KEY,
                    code_id INTEGER NOT NULL REFERENCES activation_codes(id),
                    device_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    phone TEXT NOT NULL,
                    first_seen TEXT NOT NULL,
                    last_seen TEXT NOT NULL,
                    revoked INTEGER NOT NULL DEFAULT 0,
                    UNIQUE(code_id, device_id)
                );

                CREATE INDEX IF NOT EXISTS idx_devices_code
                ON devices(code_id);

                CREATE INDEX IF NOT EXISTS idx_devices_device_id
                ON devices(device_id);
                """
            )

    def create_code(
        self,
        *,
        plan: str,
        name: str = "",
        phone: str = "",
        max_devices: int = 5,
        code: str | None = None,
        now: datetime | None = None,
    ) -> dict:
        if plan not in PLAN_DAYS:
            raise ValueError("Unsupported validity plan.")
        if not 1 <= max_devices <= 50:
            raise ValueError("max_devices must be from 1 to 50.")

        created = now or utc_now()
        duration_days = PLAN_DAYS[plan]

        with self._connect() as db:
            for _ in range(100):
                candidate = code or f"{secrets.randbelow(1_000_000):06d}"
                if not re.fullmatch(r"\d{6}", candidate):
                    raise ValueError("Activation code must contain six digits.")
                try:
                    cursor = db.execute(
                        """
                        INSERT INTO activation_codes
                        (code, name, phone, plan, duration_days, created_at,
                         max_devices)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            candidate,
                            name.strip(),
                            phone.strip(),
                            plan,
                            duration_days,
                            iso(created),
                            max_devices,
                        ),
                    )
                    db.commit()
                    return self.get_code(cursor.lastrowid)
                except sqlite3.IntegrityError:
                    if code is not None:
                        raise ValueError("Activation code already exists.")
            raise RuntimeError("Could not allocate a unique activation code.")

    def get_code(self, code_id: int) -> dict:
        with self._connect() as db:
            row = db.execute(
                "SELECT * FROM activation_codes WHERE id = ?", (code_id,)
            ).fetchone()
        if row is None:
            raise KeyError(code_id)
        return dict(row)

    def activate(
        self,
        *,
        code: str,
        name: str,
        phone: str,
        device_id: str,
        now: datetime | None = None,
    ) -> dict:
        if not re.fullmatch(r"\d{6}", code):
            raise ValueError("Invalid activation code.")
        if not name.strip() or len(phone.strip()) < 7 or not device_id.strip():
            raise ValueError("Name, phone and device ID are required.")

        current = now or utc_now()
        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            token = db.execute(
                "SELECT * FROM activation_codes WHERE code = ?", (code,)
            ).fetchone()
            if token is None:
                raise PermissionError("Activation code was not found.")
            if token["revoked"]:
                raise PermissionError("Activation code has been revoked.")

            bound_phone = token["phone"].strip()
            bound_name = token["name"].strip()
            if bound_phone and bound_phone != phone.strip():
                raise PermissionError("Activation code belongs to another phone.")

            activated_at = parse_iso(token["activated_at"])
            expires_at = parse_iso(token["expires_at"])

            if activated_at is None:
                activated_at = current
                duration = token["duration_days"]
                expires_at = (
                    None
                    if duration is None
                    else current + timedelta(days=int(duration))
                )
                db.execute(
                    """
                    UPDATE activation_codes
                    SET activated_at = ?, expires_at = ?,
                        name = CASE WHEN name = '' THEN ? ELSE name END,
                        phone = CASE WHEN phone = '' THEN ? ELSE phone END
                    WHERE id = ?
                    """,
                    (
                        iso(activated_at),
                        iso(expires_at),
                        name.strip(),
                        phone.strip(),
                        token["id"],
                    ),
                )
                bound_name = bound_name or name.strip()
                bound_phone = bound_phone or phone.strip()

            if expires_at is not None and current >= expires_at:
                raise PermissionError("Activation code has expired.")

            existing = db.execute(
                """
                SELECT * FROM devices
                WHERE code_id = ? AND device_id = ?
                """,
                (token["id"], device_id.strip()),
            ).fetchone()

            if existing is not None:
                if existing["revoked"]:
                    raise PermissionError("This device has been revoked.")
                db.execute(
                    "UPDATE devices SET last_seen = ? WHERE activation_id = ?",
                    (iso(current), existing["activation_id"]),
                )
                activation_id = existing["activation_id"]
            else:
                active_count = db.execute(
                    """
                    SELECT COUNT(*) AS count FROM devices
                    WHERE code_id = ? AND revoked = 0
                    """,
                    (token["id"],),
                ).fetchone()["count"]
                if active_count >= token["max_devices"]:
                    raise PermissionError(
                        "Maximum number of activated phones reached."
                    )
                activation_id = secrets.token_urlsafe(24)
                db.execute(
                    """
                    INSERT INTO devices
                    (activation_id, code_id, device_id, name, phone,
                     first_seen, last_seen)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        activation_id,
                        token["id"],
                        device_id.strip(),
                        name.strip(),
                        phone.strip(),
                        iso(current),
                        iso(current),
                    ),
                )
            db.commit()

        return self.status(
            activation_id=activation_id,
            device_id=device_id,
            now=current,
        )["activation"]

    def status(
        self,
        *,
        activation_id: str,
        device_id: str,
        now: datetime | None = None,
    ) -> dict:
        current = now or utc_now()
        with self._connect() as db:
            row = db.execute(
                """
                SELECT
                    d.activation_id,
                    d.device_id,
                    d.name AS device_name,
                    d.phone AS device_phone,
                    d.revoked AS device_revoked,
                    c.id AS code_id,
                    c.name AS code_name,
                    c.phone AS code_phone,
                    c.plan,
                    c.created_at,
                    c.activated_at,
                    c.expires_at,
                    c.revoked AS code_revoked
                FROM devices d
                JOIN activation_codes c ON c.id = d.code_id
                WHERE d.activation_id = ? AND d.device_id = ?
                """,
                (activation_id, device_id),
            ).fetchone()

            if row is None:
                return {"ok": False, "active": False, "error": "Unknown device."}

            expires_at = parse_iso(row["expires_at"])
            active = (
                not row["device_revoked"]
                and not row["code_revoked"]
                and (expires_at is None or current < expires_at)
            )
            if active:
                db.execute(
                    "UPDATE devices SET last_seen = ? WHERE activation_id = ?",
                    (iso(current), activation_id),
                )
                db.commit()

        activation = {
            "plan": row["plan"],
            "issued_at": row["created_at"],
            "activated_at": row["activated_at"],
            "expires_at": row["expires_at"],
            "phone": row["code_phone"] or row["device_phone"],
            "name": row["code_name"] or row["device_name"],
            "activation_id": row["activation_id"],
            "device_id": row["device_id"],
        }
        return {
            "ok": active,
            "active": active,
            "activation": activation,
            "error": None if active else "Activation is expired or revoked.",
        }

    def revoke_code(self, code_id: int) -> None:
        with self._connect() as db:
            db.execute(
                "UPDATE activation_codes SET revoked = 1 WHERE id = ?",
                (code_id,),
            )
            db.commit()

    def revoke_device(self, activation_id: str) -> None:
        with self._connect() as db:
            db.execute(
                "UPDATE devices SET revoked = 1 WHERE activation_id = ?",
                (activation_id,),
            )
            db.commit()

    def snapshot(self) -> dict:
        with self._connect() as db:
            codes = [
                dict(row)
                for row in db.execute(
                    "SELECT * FROM activation_codes ORDER BY id DESC"
                ).fetchall()
            ]
            devices = [
                dict(row)
                for row in db.execute(
                    """
                    SELECT d.*, c.code, c.plan, c.expires_at
                    FROM devices d
                    JOIN activation_codes c ON c.id = d.code_id
                    ORDER BY d.last_seen DESC
                    """
                ).fetchall()
            ]
        return {"codes": codes, "devices": devices}


class RateLimiter:
    def __init__(self, limit: int = 12, window_seconds: int = 300):
        self.limit = limit
        self.window_seconds = window_seconds
        self._attempts: dict[str, list[float]] = {}
        self._lock = threading.Lock()

    def allow(self, key: str) -> bool:
        now = time.monotonic()
        cutoff = now - self.window_seconds
        with self._lock:
            entries = [value for value in self._attempts.get(key, []) if value >= cutoff]
            if len(entries) >= self.limit:
                self._attempts[key] = entries
                return False
            entries.append(now)
            self._attempts[key] = entries
            return True


def load_admin_token(data_dir: Path) -> str:
    env = os.environ.get("SANGEET_ADMIN_TOKEN", "").strip()
    if env:
        return env

    path = data_dir / "admin_token.txt"
    if path.exists():
        token = path.read_text(encoding="utf-8").strip()
        if token:
            return token

    token = secrets.token_urlsafe(32)
    path.write_text(token + "\n", encoding="utf-8")
    return token


def make_handler(db: AdminDatabase, admin_token: str, limiter: RateLimiter):
    class Handler(BaseHTTPRequestHandler):
        server_version = "SangeetDuniyaAdmin/2.2"

        def log_message(self, fmt: str, *args) -> None:
            print(
                f"[{datetime.now().isoformat(timespec='seconds')}] "
                f"{self.client_address[0]} - {fmt % args}"
            )

        def _json(self, status: int, payload: dict) -> None:
            body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _html(self, status: int, markup: str) -> None:
            body = markup.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _redirect(self, location: str, *, cookie: str | None = None) -> None:
            self.send_response(303)
            self.send_header("Location", location)
            if cookie:
                self.send_header("Set-Cookie", cookie)
            self.end_headers()

        def _read_json(self) -> dict:
            length = int(self.headers.get("Content-Length", "0") or 0)
            if length <= 0 or length > 64_000:
                return {}
            raw = self.rfile.read(length)
            decoded = json.loads(raw.decode("utf-8"))
            return decoded if isinstance(decoded, dict) else {}

        def _read_form(self) -> dict[str, str]:
            length = int(self.headers.get("Content-Length", "0") or 0)
            raw = self.rfile.read(min(length, 64_000)).decode("utf-8")
            parsed = parse_qs(raw, keep_blank_values=True)
            return {key: values[-1] for key, values in parsed.items()}

        def _admin_authorized(self) -> bool:
            header = self.headers.get("Authorization", "")
            if header.startswith("Bearer "):
                return hmac.compare_digest(header[7:].strip(), admin_token)

            jar = cookies.SimpleCookie()
            try:
                jar.load(self.headers.get("Cookie", ""))
                morsel = jar.get("sangeet_admin")
                if morsel:
                    return hmac.compare_digest(morsel.value, admin_token)
            except cookies.CookieError:
                pass
            return False

        def _activation_error(self, message: str, status: int = 403) -> None:
            self._json(
                status,
                {"ok": False, "active": False, "error": message},
            )

        def do_GET(self) -> None:
            parsed = urlparse(self.path)

            if parsed.path == "/health":
                self._json(
                    200,
                    {
                        "ok": True,
                        "app": APP_NAME,
                        "version": VERSION,
                        "local_first": True,
                        "tailscale_compatible": True,
                    },
                )
                return

            if parsed.path == "/api/status":
                query = parse_qs(parsed.query)
                activation_id = (query.get("activation_id") or [""])[0]
                device_id = (query.get("device_id") or [""])[0]
                result = db.status(
                    activation_id=activation_id,
                    device_id=device_id,
                )
                self._json(200 if result["active"] else 403, result)
                return

            if parsed.path == "/api/admin/state":
                if not self._admin_authorized():
                    self._json(401, {"ok": False, "error": "Admin login required."})
                    return
                self._json(200, {"ok": True, **db.snapshot()})
                return

            if parsed.path == "/logout":
                self._redirect(
                    "/",
                    cookie="sangeet_admin=; Max-Age=0; Path=/; HttpOnly; SameSite=Strict",
                )
                return

            if parsed.path == "/":
                if not self._admin_authorized():
                    self._html(200, login_page())
                else:
                    self._html(200, dashboard_page(db.snapshot()))
                return

            self._json(404, {"ok": False, "error": "Not found."})

        def do_POST(self) -> None:
            parsed = urlparse(self.path)

            if parsed.path == "/api/activate":
                remote = self.client_address[0]
                if not limiter.allow(remote):
                    self._activation_error(
                        "Too many activation attempts. Try again later.",
                        429,
                    )
                    return
                try:
                    payload = self._read_json()
                    activation = db.activate(
                        code=str(payload.get("code", "")).strip(),
                        name=str(payload.get("name", "")).strip(),
                        phone=str(payload.get("phone", "")).strip(),
                        device_id=str(payload.get("device_id", "")).strip(),
                    )
                    self._json(
                        200,
                        {"ok": True, "active": True, "activation": activation},
                    )
                except (ValueError, PermissionError) as error:
                    self._activation_error(str(error))
                except Exception as error:
                    print("Activation error:", repr(error))
                    self._activation_error("Activation server error.", 500)
                return

            if parsed.path == "/login":
                form = self._read_form()
                supplied = form.get("token", "")
                if hmac.compare_digest(supplied, admin_token):
                    self._redirect(
                        "/",
                        cookie=(
                            "sangeet_admin="
                            + quote(admin_token, safe="")
                            + "; Path=/; HttpOnly; SameSite=Strict"
                        ),
                    )
                else:
                    self._html(403, login_page(error="Invalid admin token."))
                return

            if not self._admin_authorized():
                self._json(401, {"ok": False, "error": "Admin login required."})
                return

            if parsed.path == "/admin/create":
                form = self._read_form()
                try:
                    db.create_code(
                        plan=form.get("plan", ""),
                        name=form.get("name", ""),
                        phone=form.get("phone", ""),
                        max_devices=int(form.get("max_devices", "5")),
                    )
                    self._redirect("/")
                except (ValueError, TypeError) as error:
                    self._html(400, dashboard_page(db.snapshot(), error=str(error)))
                return

            if parsed.path == "/admin/revoke-code":
                form = self._read_form()
                db.revoke_code(int(form.get("id", "0")))
                self._redirect("/")
                return

            if parsed.path == "/admin/revoke-device":
                form = self._read_form()
                db.revoke_device(form.get("activation_id", ""))
                self._redirect("/")
                return

            self._json(404, {"ok": False, "error": "Not found."})

    return Handler


def login_page(error: str = "") -> str:
    error_html = (
        f'<p class="error">{html.escape(error)}</p>' if error else ""
    )
    return f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sangeet Admin Login</title>
<style>
body{{font-family:Segoe UI,Arial,sans-serif;background:#0d0d0d;color:#fff;
display:grid;place-items:center;min-height:100vh;margin:0}}
.card{{width:min(420px,88vw);background:#18140d;border:1px solid #5c471b;
border-radius:22px;padding:28px}}
h1{{color:#ffc857}} input,button{{box-sizing:border-box;width:100%;padding:13px;
margin-top:10px;border-radius:12px;border:1px solid #5c471b;background:#0f0f0f;color:#fff}}
button{{background:#ffc857;color:#111;font-weight:800;cursor:pointer}}
.error{{color:#ff7d7d}}
</style>
</head>
<body><form class="card" method="post" action="/login">
<h1>LR's Sangeet_Duniya</h1>
<p>Windows PC Admin Server v{VERSION}</p>
{error_html}
<label>Admin token</label>
<input name="token" type="password" autocomplete="current-password" required>
<button type="submit">Open Dashboard</button>
</form></body></html>"""


def remaining_label(expires_at: str | None) -> str:
    expiry = parse_iso(expires_at)
    if expiry is None:
        return "Lifetime"
    delta = expiry - utc_now()
    if delta.total_seconds() <= 0:
        return "Expired"
    days = delta.days
    hours = delta.seconds // 3600
    minutes = (delta.seconds % 3600) // 60
    return f"{days}d {hours}h {minutes}m"


def dashboard_page(snapshot: dict, error: str = "") -> str:
    options = "".join(
        f'<option value="{html.escape(key)}">{html.escape(PLAN_LABELS[key])}</option>'
        for key in PLAN_DAYS
    )

    code_rows = []
    for row in snapshot["codes"]:
        status = (
            "Revoked"
            if row["revoked"]
            else remaining_label(row["expires_at"])
            if row["activated_at"]
            else "Not activated"
        )
        code_rows.append(
            "<tr>"
            f"<td class='code'>{html.escape(row['code'])}</td>"
            f"<td>{html.escape(PLAN_LABELS.get(row['plan'], row['plan']))}</td>"
            f"<td>{html.escape(row['name'] or '—')}</td>"
            f"<td>{html.escape(row['phone'] or '—')}</td>"
            f"<td>{html.escape(status)}</td>"
            f"<td>{row['max_devices']}</td>"
            "<td>"
            + (
                "<span class='muted'>Revoked</span>"
                if row["revoked"]
                else (
                    "<form method='post' action='/admin/revoke-code'>"
                    f"<input type='hidden' name='id' value='{row['id']}'>"
                    "<button class='danger' type='submit'>Revoke</button></form>"
                )
            )
            + "</td></tr>"
        )

    device_rows = []
    for row in snapshot["devices"]:
        active = not row["revoked"] and remaining_label(row["expires_at"]) != "Expired"
        device_rows.append(
            "<tr>"
            f"<td>{html.escape(row['name'])}</td>"
            f"<td>{html.escape(row['phone'])}</td>"
            f"<td class='mono'>{html.escape(row['device_id'])}</td>"
            f"<td>{html.escape(row['code'])}</td>"
            f"<td>{html.escape(row['last_seen'])}</td>"
            f"<td>{'Active' if active else 'Revoked/Expired'}</td>"
            "<td>"
            + (
                "<span class='muted'>Revoked</span>"
                if row["revoked"]
                else (
                    "<form method='post' action='/admin/revoke-device'>"
                    "<input type='hidden' name='activation_id' value='"
                    + html.escape(row["activation_id"])
                    + "'><button class='danger' type='submit'>Revoke</button></form>"
                )
            )
            + "</td></tr>"
        )

    error_html = (
        f'<div class="error">{html.escape(error)}</div>' if error else ""
    )
    return f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="10">
<title>Sangeet Admin</title>
<style>
:root{{--gold:#ffc857;--panel:#17130d;--border:#493918}}
*{{box-sizing:border-box}} body{{margin:0;background:#090909;color:#fff;
font-family:Segoe UI,Arial,sans-serif}} main{{max-width:1180px;margin:auto;padding:24px}}
header{{display:flex;justify-content:space-between;align-items:center;gap:12px}}
h1,h2{{color:var(--gold)}} .panel{{background:var(--panel);border:1px solid var(--border);
border-radius:20px;padding:18px;margin:16px 0;overflow:auto}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px}}
input,select,button{{padding:11px;border-radius:10px;border:1px solid #654d1a;
background:#0d0d0d;color:#fff}} button{{background:var(--gold);color:#111;font-weight:800;
cursor:pointer}} .danger{{background:#6d2222;color:#fff;padding:7px 10px}}
table{{width:100%;border-collapse:collapse;min-width:860px}} th,td{{text-align:left;
padding:10px;border-bottom:1px solid #312817;font-size:13px}} .code{{font-size:22px;
font-weight:900;letter-spacing:4px;color:var(--gold)}} .mono{{font-family:Consolas,monospace;
font-size:11px}} .muted{{color:#999}} .error{{padding:12px;background:#4d1919;
border-radius:10px}} a{{color:var(--gold)}}
</style>
</head>
<body><main>
<header><div><h1>LR's Sangeet_Duniya v{VERSION}</h1>
<div class="muted">Windows PC Admin • SQLite • same Wi-Fi / Tailscale</div></div>
<a href="/logout">Log out</a></header>
{error_html}
<section class="panel"><h2>Create 6-digit activation code</h2>
<form method="post" action="/admin/create" class="grid">
<input name="name" placeholder="Recipient name">
<input name="phone" placeholder="Phone number">
<select name="plan">{options}</select>
<input name="max_devices" type="number" min="1" max="50" value="5"
title="Maximum phones using this code">
<button type="submit">Generate Code</button>
</form></section>
<section class="panel"><h2>Activation Codes</h2>
<table><thead><tr><th>Code</th><th>Validity</th><th>Name</th><th>Phone</th>
<th>Countdown</th><th>Max phones</th><th>Action</th></tr></thead>
<tbody>{''.join(code_rows) or '<tr><td colspan="7">No codes yet.</td></tr>'}</tbody>
</table></section>
<section class="panel"><h2>Activated Phones</h2>
<table><thead><tr><th>Name</th><th>Phone</th><th>Device ID</th><th>Code</th>
<th>Last sync</th><th>Status</th><th>Action</th></tr></thead>
<tbody>{''.join(device_rows) or '<tr><td colspan="7">No activated phones yet.</td></tr>'}</tbody>
</table></section>
</main></body></html>"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument(
        "--data-dir",
        default=str(Path(__file__).resolve().parent / "data"),
    )
    args = parser.parse_args()

    data_dir = Path(args.data_dir).resolve()
    data_dir.mkdir(parents=True, exist_ok=True)
    db = AdminDatabase(data_dir / "sangeet_admin.db")
    admin_token = load_admin_token(data_dir)
    limiter = RateLimiter()
    handler = make_handler(db, admin_token, limiter)
    server = ThreadingHTTPServer((args.host, args.port), handler)

    print("=" * 68)
    print(f"{APP_NAME} v{VERSION} Windows PC Admin Server")
    print(f"Listening: http://{args.host}:{args.port}")
    print(f"Dashboard: http://127.0.0.1:{args.port}/")
    print("Use the PC LAN IPv4 or Tailscale IPv4 in the mobile app.")
    print(f"ADMIN TOKEN: {admin_token}")
    print(f"Database: {db.path}")
    print("=" * 68)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
