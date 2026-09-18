"""Disposable public-CLI scenario support; never inherit learner Base state."""
from __future__ import annotations

import argparse
import json
import os
import shlex
from pathlib import Path
import subprocess
import tempfile


def arguments(description):
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--base-commit", required=True)
    parser.add_argument("--base-cli", type=Path, required=True)
    parser.add_argument("--bash-libs", type=Path, required=True)
    parser.add_argument("--python", type=Path, required=True, help="existing Base-compatible Python interpreter")
    parser.add_argument("--candidate", action="store_true")
    args = parser.parse_args()
    for name, path, expected in (
        ("base", args.base, args.base_commit),
        ("base-cli", args.base_cli, "8a93d22156ba75a99965f7c355f867acba630069"),
        ("base-bash-libs", args.bash_libs, "36fec50c446dcea8c521a1ba3e7fee2394f169c0"),
    ):
        actual = subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD"], text=True).strip()
        dirty = subprocess.check_output(["git", "-C", str(path), "status", "--porcelain"], text=True)
        if actual != expected or dirty:
            parser.error(f"{name} must be a clean exact-commit checkout")
    if not args.candidate and args.base_commit != "ac8d294421e1bfc14afa8c6a2a12f1affb5268ee":
        parser.error("stable lane requires supported Base v1.9.0; pass --candidate for separately recorded source")
    return args


class Fixture:
    def __init__(self, args):
        self.args = args
        self.temporary = tempfile.TemporaryDirectory(prefix="base-demo-scenario-")
        self.root = Path(self.temporary.name).resolve()
        self.home = self.root / "home"
        self.workspace = self.root / "workspace"
        self.home.mkdir()
        self.workspace.mkdir()
        # A proxy selects the existing interpreter without writing to its venv.
        venv = self.home / ".base.d/base/.venv"
        (venv / "bin").mkdir(parents=True)
        proxy = venv / "bin/python"
        proxy.write_text("#!/bin/sh\nexec " + shlex.quote(str(args.python.absolute())) + ' "$@"\n')
        proxy.chmod(0o755)
        (venv / "pyvenv.cfg").write_text("scenario = isolated\n")
        self.env = {
            "HOME": str(self.home), "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
            "BASE_HOME": str(args.base.resolve()), "BASE_SETUP_VENV_DIR": str(venv),
            "BASE_CLI_SOURCE_DIR": str(args.base_cli.resolve() / "lib/python"),
            "BASE_BASH_LIBS_DIR": str(args.bash_libs.resolve() / "lib/bash"),
            "BASE_CACHE_DIR": str(self.root / "cache"), "BASE_SETUP_NOTIFY": "false",
            "XDG_CONFIG_HOME": str(self.home / ".config"), "XDG_CACHE_HOME": str(self.root / "xdg-cache"),
            "TMPDIR": str(self.root), "NO_COLOR": "1", "TERM": "dumb",
        }

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.temporary.cleanup()

    def project(self, name="demo", extra=""):
        root = self.workspace / name
        root.mkdir(exist_ok=True)
        command = 'printf "executed\\n" > "$BASE_PROJECT_ROOT/executed"'
        (root / "base_manifest.yaml").write_text(
            f"project:\n  name: {name}\nartifacts: []\ncommands:\n  hello: {json.dumps(command)}\n" + extra
        )
        return root

    def run(self, *args, expected=0, cwd=None):
        result = subprocess.run([str(self.args.base.resolve() / "bin/basectl"), *map(str, args)],
                                env=self.env, cwd=cwd or self.workspace, capture_output=True, text=True, timeout=90)
        allowed = expected if isinstance(expected, tuple) else (expected,)
        if result.returncode not in allowed:
            # Only redacted fixture-local diagnostics are emitted on failure.
            output = (result.stdout + result.stderr).replace(str(self.root), "<fixture>")
            command = str(args).replace(str(self.root), "<fixture>")
            raise AssertionError(f"{command}: expected exit {expected}, got {result.returncode}\n{output}")
        return result

    def no_ide_settings(self):
        assert not list(self.home.rglob("settings.json")), "fixture unexpectedly wrote IDE settings"
