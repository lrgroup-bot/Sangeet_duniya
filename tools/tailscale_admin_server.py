#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import secrets
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

APP = "LRs Sangeet_Duniya"


def iso(ms=None):
    if ms is None:
        ms = int(time.time() * 1000)
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(ms / 1000))


class Store:
    def __init__(self, root):
        self.root = Path(root)
        self.root.mkdir(parents=True, exist_ok=True)
        self.cfg = self.root / "config.json"
        self.tokens = self.root / "tokens.json"
        self.users = self.root / "users.json"
        self.pending = self.root / "pending.json"
        self._ensure()

    def _read(self, path, default):
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return default

    def _write(self, path, value):
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(
            json.dumps(value, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        tmp.replace(path)

    def _ensure(self):
        if not self.cfg.exists():
            self._write(
                self.cfg,
                {
                    "user_key": secrets.token_urlsafe(32),
                    "admin_key": secrets.token_urlsafe(40),
                    "created_at": iso(),
                },
            )
        if not self.tokens.exists():
            self._write(self.tokens, {"activationTokens": [], "legacyTokens": []})
        if not self.users.exists():
            self._write(self.users, {"users": []})
        if not self.pending.exists():
            self._write(self.pending, {"requests": []})

    @property
    def user_key(self):
        return str(self._read(self.cfg, {}).get("user_key", ""))

    @property
    def admin_key(self):
        return str(self._read(self.cfg, {}).get("admin_key", ""))

    def get_activation_tokens(self):
        data = self._read(self.tokens, {})
        raw = data.get("activationTokens")
        if isinstance(raw, list):
            return [x for x in raw if isinstance(x, dict)]

        # Backward-compatible read of the previous tokens.json format.
        raw = data.get("tokens", [])
        if isinstance(raw, list):
            return [x for x in raw if isinstance(x, dict)]
        return []

    def set_activation_tokens(self, records):
        data = self._read(self.tokens, {})
        legacy = data.get("legacyTokens", [])
        if not isinstance(legacy, list):
            legacy = []
        self._write(
            self.tokens,
            {
                "activationTokens": records,
                "legacyTokens": [str(x) for x in legacy],
            },
        )

    def set_legacy_tokens(self, values):
        data = self._read(self.tokens, {})
        records = self.get_activation_tokens()
        self._write(
            self.tokens,
            {
                "activationTokens": records,
                "legacyTokens": [str(x) for x in values if str(x).strip()],
            },
        )

    def get_legacy_tokens(self):
        data = self._read(self.tokens, {})
        raw = data.get("legacyTokens", [])
        return [str(x) for x in raw] if isinstance(raw, list) else []

    def get_users(self):
        return self._read(self.users, {"users": []}).get("users", [])

    def get_pending(self):
        data = self._read(self.pending, {"requests": []})
        raw = data.get("requests", [])
        return [x for x in raw if isinstance(x, dict)]

    def save_pending(self, request):
        items = self.get_pending()
        phone = str(request.get("phone", ""))
        items = [x for x in items if str(x.get("phone", "")) != phone]
        items.append(request)
        self._write(self.pending, {"requests": items})

    def remove_pending(self, phone):
        items = [
            x for x in self.get_pending()
            if str(x.get("phone", "")) != str(phone)
        ]
        self._write(self.pending, {"requests": items})

    def save_user(self, user):
        items = self.get_users()
        phone = user["phone"]
        for index, existing in enumerate(items):
            if existing.get("phone") == phone:
                user["id"] = existing.get("id", user["id"])
                items[index] = user
                break
        else:
            items.append(user)
        self._write(self.users, {"users": items})


def equal(a, b):
    if len(a) != len(b):
        return False
    result = 0
    for aa, bb in zip(a.encode(), b.encode()):
        result |= aa ^ bb
    return result == 0


def token_payload(token):
    parts = token.strip().split(".")
    if len(parts) != 3 or parts[0] != "LRS1":
        return None
    try:
        raw = base64.urlsafe_b64decode(
            parts[1] + "=" * (-len(parts[1]) % 4)
        )
        data = json.loads(raw.decode())
        if not isinstance(data, dict) or data.get("v") != 1:
            return None
        expires = int(data.get("expires", 0))
        now = int(time.time() * 1000)
        if expires and now >= expires:
            return None
        return {
            "plan": str(data.get("plan", "")),
            "issued": int(data.get("issued", 0)),
            "expires": expires,
            "phone": str(data.get("phone", "")),
        }
    except Exception:
        return None


def activation_record_is_expired(record):
    expires = record.get("expiresAt")
    if not expires:
        return False
    try:
        from datetime import datetime, timezone

        value = datetime.fromisoformat(str(expires).replace("Z", "+00:00"))
        return datetime.now(timezone.utc) >= value
    except Exception:
        return True


class Handler(BaseHTTPRequestHandler):
    server_version = "LRS-PC-Admin/1.1"

    def log_message(self, fmt, *args):
        print("[LRS-PC]", fmt % args)

    @property
    def store(self):
        return self.server.store

    def request_path(self):
        return urlparse(self.path_raw).path or "/"

    def key(self):
        return parse_qs(urlparse(self.path_raw).query).get("key", [""])[0]

    def json(self, status, payload):
        data = b"" if payload is None else json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Methods",
            "GET,POST,OPTIONS",
        )
        self.send_header(
            "Access-Control-Allow-Headers",
            "content-type",
        )
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if data:
            self.wfile.write(data)

    def read(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
            return json.loads(self.rfile.read(length).decode())
        except Exception:
            return None

    def user_ok(self):
        return equal(self.key(), self.store.user_key)

    def admin_ok(self):
        return equal(self.key(), self.store.admin_key)

    def do_OPTIONS(self):
        self.path_raw = self.path
        self.json(204, None)

    def do_GET(self):
        self.path_raw = self.path
        path = self.request_path()

        if path == "/health":
            return self.json(
                200,
                {"ok": True, "app": APP, "server": "PC"},
            )

        # Customer apps use this only to retrieve the USER KEY. The USER KEY
        # is intentionally shareable; the ADMIN KEY is never returned here.
        if path == "/public/user-key":
            return self.json(
                200,
                {
                    "ok": True,
                    "app": APP,
                    "key": self.store.user_key,
                },
            )

        if path == "/connect":
            if not self.user_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "User key required."},
                )
            return self.json(
                200,
                {"ok": True, "message": "Connected to PC admin server."},
            )

        if path == "/users":
            if not self.admin_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "Admin key required."},
                )
            return self.json(
                200,
                {"ok": True, "users": self.store.get_users()},
            )

        if path == "/admin":
            if not self.admin_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "Admin key required."},
                )
            return self.json(
                200,
                {
                    "ok": True,
                    "users": len(self.store.get_users()),
                    "tokens": len(self.store.get_activation_tokens()),
                },
            )

        if path == "/pending":
            if not self.admin_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "Admin key required."},
                )
            return self.json(
                200,
                {
                    "ok": True,
                    "requests": self.store.get_pending(),
                },
            )

        return self.json(404, {"ok": False, "error": "Not found."})

    def do_POST(self):
        self.path_raw = self.path
        path = self.request_path()

        if path == "/request-access":
            if not self.user_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "User key required."},
                )

            body = self.read() or {}
            name = str(body.get("name", "")).strip()
            phone = str(body.get("phone", "")).strip()

            if (
                len(name) < 2
                or len(phone) != 10
                or not phone.isdigit()
                or phone[0] not in "6789"
            ):
                return self.json(
                    400,
                    {
                        "ok": False,
                        "error": "Name and valid 10-digit phone number are required.",
                    },
                )

            self.store.save_pending(
                {
                    "id": str(int(time.time() * 1000000)),
                    "name": name,
                    "phone": phone,
                    "requestedAt": iso(),
                    "status": "pending",
                    "source": "remote",
                }
            )
            return self.json(
                200,
                {
                    "ok": True,
                    "status": "pending",
                    "message": "Access request sent to the administrator.",
                },
            )

        if path == "/pending/resolve":
            if not self.admin_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "Admin key required."},
                )

            body = self.read() or {}
            phone = str(body.get("phone", "")).strip()
            if (
                len(phone) != 10
                or not phone.isdigit()
                or phone[0] not in "6789"
            ):
                return self.json(
                    400,
                    {
                        "ok": False,
                        "error": "A valid phone number is required.",
                    },
                )

            self.store.remove_pending(phone)
            return self.json(200, {"ok": True})

        if path == "/tokens":
            if not self.admin_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "Admin key required."},
                )

            body = self.read() or {}
            records = body.get("activationTokens", [])
            if not isinstance(records, list):
                records = []

            clean_records = []
            for record in records:
                if not isinstance(record, dict):
                    continue
                token = str(record.get("token", "")).strip()
                if len(token) != 6 or not token.isdigit():
                    continue
                clean_records.append(
                    {
                        "token": token,
                        "customerName": str(
                            record.get("customerName", "")
                        ),
                        "phone": str(record.get("phone", "")),
                        "plan": str(record.get("plan", "sevenDays")),
                        "issuedAt": str(record.get("issuedAt", "")),
                        "expiresAt": record.get("expiresAt"),
                        "used": bool(record.get("used", False)),
                        "activatedAt": record.get("activatedAt"),
                    }
                )

            self.store.set_activation_tokens(clean_records)
            legacy = body.get("tokens", [])
            if isinstance(legacy, list):
                self.store.set_legacy_tokens(legacy)

            return self.json(
                200,
                {
                    "ok": True,
                    "synced": len(clean_records),
                },
            )

        if path == "/activate":
            if not self.user_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "User key required."},
                )

            body = self.read() or {}
            name = str(body.get("name", "")).strip()
            phone = str(body.get("phone", "")).strip()
            token = str(body.get("token", "")).strip()

            if (
                not name
                or len(phone) != 10
                or not phone.isdigit()
                or phone[0] not in "6789"
                or len(token) != 6
                or not token.isdigit()
            ):
                return self.json(
                    400,
                    {
                        "ok": False,
                        "error": (
                            "Name, 10-digit phone number and "
                            "6-digit token are required."
                        ),
                    },
                )

            records = self.store.get_activation_tokens()
            for index, record in enumerate(records):
                if str(record.get("token", "")) != token:
                    continue

                if bool(record.get("used", False)):
                    return self.json(
                        403,
                        {"ok": False, "error": "Activation token already used."},
                    )

                if activation_record_is_expired(record):
                    return self.json(
                        403,
                        {"ok": False, "error": "Activation token expired."},
                    )

                bound_phone = str(record.get("phone", "")).strip()
                if bound_phone != phone:
                    return self.json(
                        403,
                        {"ok": False, "error": "Token is bound to a different phone."},
                    )

                verified_name = str(record.get("customerName", "")).strip()
                if verified_name and verified_name.casefold() != name.casefold():
                    return self.json(
                        403,
                        {"ok": False, "error": "Name does not match the administrator verification."},
                    )

                activated_at = iso()
                updated = dict(record)
                updated["used"] = True
                updated["activatedAt"] = activated_at
                records[index] = updated
                self.store.set_activation_tokens(records)

                user = {
                    "id": str(int(time.time() * 1000000)),
                    "name": name,
                    "phone": phone,
                    "plan": str(record.get("plan", "sevenDays")),
                    "issued": str(record.get("issuedAt", activated_at)),
                    "activated": activated_at,
                    "expires": record.get("expiresAt"),
                    "token": token,
                }
                self.store.save_user(user)

                return self.json(
                    200,
                    {
                        "ok": True,
                        "activation": {
                            **updated,
                            "customerName": name,
                            "phone": phone,
                        },
                    },
                )

            return self.json(
                403,
                {
                    "ok": False,
                    "error": "Invalid activation token.",
                },
            )

        if path == "/register":
            if not self.user_ok():
                return self.json(
                    401,
                    {"ok": False, "error": "User key required."},
                )

            body = self.read() or {}
            name = str(body.get("name", "")).strip()
            phone = str(body.get("phone", "")).strip()
            token = str(body.get("token", "")).strip()

            if (
                not name
                or len(phone) != 10
                or not phone.isdigit()
                or not token
            ):
                return self.json(
                    400,
                    {
                        "ok": False,
                        "error": "Name, 10-digit phone number and token are required.",
                    },
                )

            info = token_payload(token)
            if info is None:
                return self.json(
                    403,
                    {"ok": False, "error": "Token is invalid or expired."},
                )

            if info["phone"] and info["phone"] != phone:
                return self.json(
                    403,
                    {"ok": False, "error": "Token is bound to a different phone."},
                )

            user = {
                "id": str(int(time.time() * 1000000)),
                "name": name,
                "phone": phone,
                "plan": info["plan"],
                "issued": iso(info["issued"]),
                "activated": iso(),
                "expires": iso(info["expires"]) if info["expires"] else None,
                "token": token,
            }
            self.store.save_user(user)

            return self.json(
                200,
                {
                    "ok": True,
                    "name": name,
                    "phone": phone,
                    "plan": info["plan"],
                    "issuedAt": iso(info["issued"]),
                    "expiresAt": iso(info["expires"]) if info["expires"] else None,
                },
            )

        return self.json(404, {"ok": False, "error": "Not found."})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=40426)
    parser.add_argument("--data-dir", default=".lrs-admin-data")
    args = parser.parse_args()

    store = Store(args.data_dir)
    httpd = ThreadingHTTPServer((args.host, args.port), Handler)
    httpd.store = store

    print("\nLRs Sangeet_Duniya PC Admin Server")
    print("Local:", f"http://{args.host}:{args.port}")
    print("Data :", Path(args.data_dir).resolve())
    print("\nUSER KEY (safe to share with app users):\n" + store.user_key)
    print("\nADMIN KEY (keep private; use only for admin operations):\n" + store.admin_key)
    print("\nThen expose this port with Tailscale Serve or Funnel.")
    print(
        "Check existing config first: "
        "tailscale serve status && tailscale funnel status"
    )
    httpd.serve_forever()


if __name__ == "__main__":
    main()
