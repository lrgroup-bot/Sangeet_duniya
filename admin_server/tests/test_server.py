import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

from admin_server.server import AdminDatabase


class AdminDatabaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.db = AdminDatabase(Path(self.temp.name) / "test.db")
        self.now = datetime(2026, 9, 25, 12, 0, tzinfo=timezone.utc)

    def tearDown(self):
        self.temp.cleanup()

    def test_six_digit_code_and_first_activation_starts_expiry(self):
        token = self.db.create_code(
            plan="fourteenDays",
            name="Rakesh",
            phone="+919999999999",
            max_devices=2,
            code="123456",
            now=self.now,
        )
        self.assertEqual(token["code"], "123456")
        self.assertIsNone(token["activated_at"])

        activation = self.db.activate(
            code="123456",
            name="Rakesh",
            phone="+919999999999",
            device_id="phone-a",
            now=self.now,
        )
        self.assertEqual(activation["plan"], "fourteenDays")
        self.assertEqual(
            activation["expires_at"],
            (self.now + timedelta(days=14))
            .isoformat()
            .replace("+00:00", "Z"),
        )

    def test_multiple_phones_share_same_validity_window(self):
        self.db.create_code(
            plan="ninetyDays",
            code="654321",
            max_devices=2,
            now=self.now,
        )
        first = self.db.activate(
            code="654321",
            name="User",
            phone="+918888888888",
            device_id="phone-a",
            now=self.now,
        )
        second = self.db.activate(
            code="654321",
            name="User",
            phone="+918888888888",
            device_id="phone-b",
            now=self.now + timedelta(days=1),
        )
        self.assertEqual(first["expires_at"], second["expires_at"])

        with self.assertRaises(PermissionError):
            self.db.activate(
                code="654321",
                name="User",
                phone="+918888888888",
                device_id="phone-c",
                now=self.now + timedelta(days=1),
            )

    def test_revoked_device_becomes_inactive(self):
        self.db.create_code(
            plan="lifetime",
            code="111222",
            now=self.now,
        )
        activation = self.db.activate(
            code="111222",
            name="User",
            phone="+917777777777",
            device_id="phone-a",
            now=self.now,
        )
        self.db.revoke_device(activation["activation_id"])
        status = self.db.status(
            activation_id=activation["activation_id"],
            device_id="phone-a",
            now=self.now,
        )
        self.assertFalse(status["active"])


if __name__ == "__main__":
    unittest.main()
