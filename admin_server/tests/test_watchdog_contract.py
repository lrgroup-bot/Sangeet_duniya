from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
WATCHDOG = ROOT / "admin_server" / "windows_watchdog.ps1"


class WatchdogContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = WATCHDOG.read_text(encoding="utf-8")

    def test_v22_server_and_port_contract(self):
        self.assertIn("admin_server\\server.py", self.text)
        self.assertIn("[int]$Port = 40425", self.text)
        self.assertIn("$CanonicalPort = 40425", self.text)
        self.assertIn("$Port = $CanonicalPort", self.text)
        self.assertIn("PORT SELF-HEAL", self.text)
        self.assertIn("Repair-PortDrift", self.text)
        self.assertIn("http://127.0.0.1:$Port/health", self.text)
        self.assertNotIn("tailscale_admin_server.py", self.text)
        self.assertNotIn("[int]$Port = 40426", self.text)

    def test_pull_is_fast_forward_only(self):
        self.assertIn("status --porcelain --untracked-files=no", self.text)
        self.assertIn("merge-base --is-ancestor", self.text)
        self.assertIn("merge --ff-only", self.text)
        self.assertNotIn("git -C $Root reset", self.text)
        self.assertNotIn("git -C $Root clean", self.text)

    def test_runtime_data_is_preserved(self):
        self.assertIn("admin_server\\data", self.text)
        self.assertIn(".runtime", self.text)
        self.assertIn(".lrs-admin-data", self.text)
        self.assertIn("$OldTaskName", self.text)
        self.assertIn("safe.directory", self.text)
        self.assertIn("@('-u', $ServerScript", self.text)
        self.assertIn("$version.StartsWith('2.')", self.text)
        self.assertIn("'SelfTest'", self.text)
        self.assertIn("fetch --prune origin $TargetBranch 2>$null", self.text)
        self.assertIn("merge --ff-only $remoteRef 2>$null", self.text)
        self.assertNotIn("fetch --prune origin $TargetBranch 2>&1", self.text)
        self.assertNotIn("merge --ff-only $remoteRef 2>&1", self.text)


if __name__ == "__main__":
    unittest.main()
