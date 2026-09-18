"""Verify isolation, redaction and failure cleanup without external providers."""
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest

sys.path.insert(0, str(Path(__file__).parent / "scenarios"))
from fixture import Fixture


class HarnessTests(unittest.TestCase):
    def args(self):
        return SimpleNamespace(python=Path(sys.executable), base=Path("/unused"),
                               base_cli=Path("/unused-cli"), bash_libs=Path("/unused-libs"))

    def test_failure_cleans_disposable_home(self):
        root = None
        with self.assertRaisesRegex(RuntimeError, "expected failure"):
            with Fixture(self.args()) as fixture:
                root = fixture.root
                self.assertEqual(Path(fixture.env["HOME"]), fixture.home)
                self.assertNotIn("GH_TOKEN", fixture.env)
                self.assertNotIn("BASH_ENV", fixture.env)
                raise RuntimeError("expected failure")
        self.assertFalse(root.exists())

    def test_cli_failures_redact_fixture_root(self):
        with Fixture(self.args()) as fixture:
            fixture.args.base = fixture.root / "provider"
            launcher = fixture.args.base / "bin/basectl"
            launcher.parent.mkdir(parents=True)
            launcher.write_text('#!/bin/sh\nprintf "%s\\n" "$HOME"\nexit 1\n')
            launcher.chmod(0o755)
            with self.assertRaises(AssertionError) as failure:
                fixture.run("check", "--manifest", fixture.root / "project.yaml")
            self.assertNotIn(str(fixture.root), str(failure.exception))
            self.assertIn("<fixture>", str(failure.exception))


if __name__ == "__main__":
    unittest.main()
