"""Tests for the base-demo Python CLI."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import base_cli
from base_cli.testing import invoke

from base_demo_cli.__main__ import app


class BaseDemoCliTests(unittest.TestCase):
    def test_info_uses_context(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            home = Path(tmpdir) / "home"
            project = Path(tmpdir) / "workspace" / "base-demo"
            project.mkdir(parents=True)

            result = invoke(
                app,
                ["info"],
                home=home,
                cwd=project,
                manifest={"project": {"name": "base-demo"}, "artifacts": []},
            )

        self.assertEqual(result.exit_code, base_cli.ExitCode.SUCCESS, result.output)
        self.assertIn("base-demo python cli", result.output)
        self.assertIn("project_name=base-demo", result.output)
        self.assertIn("project_root=", result.output)
        self.assertIn("workspace_root=", result.output)

    def test_env_prints_base_environment(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            home = Path(tmpdir) / "home"
            project = Path(tmpdir) / "workspace" / "base-demo"
            project.mkdir(parents=True)

            result = invoke(
                app,
                ["env"],
                home=home,
                cwd=project,
                env={"BASE_PROJECT": "base-demo", "BASE_DEMO_ENV": "baseline"},
                manifest={"project": {"name": "base-demo"}, "artifacts": []},
            )

        self.assertEqual(result.exit_code, base_cli.ExitCode.SUCCESS, result.output)
        self.assertIn("BASE_PROJECT=base-demo", result.output)
        self.assertIn("BASE_DEMO_ENV=baseline", result.output)

    def test_debug_logs_from_info(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            home = Path(tmpdir) / "home"
            project = Path(tmpdir) / "workspace" / "base-demo"
            project.mkdir(parents=True)

            result = invoke(
                app,
                ["--debug", "info"],
                home=home,
                cwd=project,
                manifest={"project": {"name": "base-demo"}, "artifacts": []},
            )

        self.assertEqual(result.exit_code, base_cli.ExitCode.SUCCESS, result.output)
        self.assertIn("base_demo_cli info command", result.stderr)


if __name__ == "__main__":
    unittest.main()
