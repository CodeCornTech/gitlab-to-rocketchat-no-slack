"""Fast, network-free checks for the publishable documentation bundle."""

import json
import pathlib
import re
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent


class RepositoryTests(unittest.TestCase):
    def test_sample_is_valid_rocketchat_message(self):
        payload = json.loads((ROOT / "examples/payload.json").read_text(encoding="utf-8"))
        self.assertIsInstance(payload["text"], str)
        self.assertTrue(payload["text"])
        self.assertTrue(payload["attachments"])

    def test_bash_syntax(self):
        scripts = sorted((ROOT / "scripts").glob("*.sh"))
        self.assertTrue(scripts)
        for script in scripts:
            with self.subTest(script=script.name):
                subprocess.run(["bash", "-n", str(script)], check=True)

    def test_no_live_webhook_tokens(self):
        # URLs in docs use generic examples, not real /hooks/<id>/<token> secrets.
        publishable = [
            *ROOT.glob("*.md"),
            *ROOT.glob("docs/*.md"),
            *ROOT.glob("scripts/*.sh"),
            *ROOT.glob("examples/*.json"),
        ]
        token_url = re.compile(r"https?://[^\s\"']+/hooks/[A-Za-z0-9]{12,}/[A-Za-z0-9]{20,}")
        for path in publishable:
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertNotRegex(path.read_text(encoding="utf-8"), token_url)

    def test_referenced_guide_files_exist(self):
        for path in (
            "docs/it.md",
            "docs/troubleshooting.md",
            "docs/native-webhooks.md",
            "SECURITY.md",
            "LICENSE",
        ):
            self.assertTrue((ROOT / path).is_file(), path)


if __name__ == "__main__":
    unittest.main()
