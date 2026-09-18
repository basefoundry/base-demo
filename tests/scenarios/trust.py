"""Assert command approval, invalidation, revoke and independent consent."""
from __future__ import annotations

import json
from pathlib import Path
import shlex
import subprocess

from fixture import Fixture, arguments


def main():
    args = arguments(__doc__)
    with Fixture(args) as fixture:
        project = fixture.project()
        manifest = project / "base_manifest.yaml"
        original = manifest.read_text()
        workspace = ("--workspace", fixture.workspace)
        fixture.run("run", "demo", "--list", *workspace)
        denied = fixture.run("run", "demo", "hello", *workspace, expected=1)
        assert "trust" in (denied.stdout + denied.stderr).lower()
        assert not (project / "executed").exists()
        fixture.run("trust", "allow", "demo", *workspace)
        fixture.run("run", "demo", "hello", *workspace)
        assert (project / "executed").read_text() == "executed\n"
        (project / "executed").unlink()
        manifest.write_text(original + "\n# changed after review\n")
        fixture.run("run", "demo", "hello", *workspace, expected=1)
        assert not (project / "executed").exists()
        if args.candidate:
            # Historical multi-approval cleanup is the implemented v1.10
            # contract, not a guarantee of the older stable release.
            fixture.run("trust", "allow", "demo", *workspace)
        fixture.run("trust", "revoke", "demo", *workspace)
        fixture.run("run", "demo", "hello", *workspace, expected=1)
        # Reverting the manifest must not resurrect the older approval.
        manifest.write_text(original)
        fixture.run("run", "demo", "hello", *workspace, expected=1)
        scope = "historical approvals" if args.candidate else "single reviewed approval"
        print(f"PASS: inspection -> denial -> approval -> execution -> invalidation -> revoke ({scope})")

        # Preview only: do not authorize or apply any IDE mutation.
        manifest.write_text(original + "ide:\n  vscode:\n    settings:\n      editor.formatOnSave: true\n")
        preview = fixture.run("setup", "demo", "--manifest", manifest, "--dry-run", "--yes")
        assert "IDE" in (preview.stdout + preview.stderr) or "settings" in (preview.stdout + preview.stderr)
        fixture.run("run", "demo", "hello", *workspace, expected=1)
        fixture.no_ide_settings()
        print("PASS: --yes plus setup preview does not approve manifest commands or write IDE settings")
        env = dict(fixture.env)
        env["PYTHONPATH"] = str(args.base_cli.resolve() / "lib/python") + ":" + str(args.base.resolve() / "cli/python")
        guard = subprocess.run([str(args.python.absolute()), str(Path(__file__).with_name("ide_guard.py"))],
                               env=env, cwd=fixture.root, capture_output=True, text=True, timeout=30)
        assert guard.returncode == 0, (guard.stdout + guard.stderr).replace(str(fixture.root), "<fixture>")
        print(guard.stdout.strip())
        fixture.no_ide_settings()

        if args.candidate:
            help_result = fixture.run("check", "--help")
            assert "--verify-project-runtime" in help_result.stdout, "candidate lacks runtime verification contract"
            manifest.write_text(original + "python: {}\n")
            runtime = project / ".venv/bin/python"
            runtime.parent.mkdir(parents=True)
            marker = project / "runtime-probed"
            runtime.write_text("#!/bin/sh\n" + f"printf probe >> {shlex.quote(str(marker))}\n"
                               + f"exec {shlex.quote(str(args.python.absolute()))} \"$@\"\n")
            runtime.chmod(0o755)
            (project / ".venv/pyvenv.cfg").write_text("scenario = project-runtime\n")
            fixture.run("trust", "allow", "demo", *workspace)
            static = fixture.run("check", "--ci", "--manifest", manifest, "--format", "json", expected=(0, 1))
            assert "unverified" in static.stdout
            payload = json.loads(static.stdout)
            assert payload["project_checks"]["status"] == "warn"
            # Host prerequisites remain real diagnostics, separate from this
            # disposable project contract. Assert their aggregate exit exactly.
            assert static.returncode == (1 if payload["status"] == "error" else 0)
            assert not marker.exists(), "saved command approval unexpectedly permitted a runtime probe"
            verified = fixture.run("check", "--ci", "--manifest", manifest, "--verify-project-runtime", "--format", "json",
                                   expected=(0, 1))
            payload = json.loads(verified.stdout)
            assert payload["project_checks"]["status"] != "error", payload["project_checks"]
            assert verified.returncode == (1 if payload["status"] == "error" else 0)
            assert marker.exists(), "explicit verification did not probe the runtime"
            fixture.no_ide_settings()
            print("PASS: saved command approval does not grant runtime inspection; explicit verification probes only the fixture")
        else:
            print("BOUNDARY: full historical revocation and --verify-project-runtime require the implemented v1.10 candidate")
        print(f"PASS: isolated trust scenario at Base {args.base_commit}; fixture cleanup on success and failure")


if __name__ == "__main__":
    main()
