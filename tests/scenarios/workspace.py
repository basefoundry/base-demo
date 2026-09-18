"""Assert disposable workspace inventory, checkout targeting and selected tests."""
from __future__ import annotations

import json
import shlex

from fixture import Fixture, arguments


def main():
    args = arguments(__doc__)
    with Fixture(args) as fixture:
        roots = {}
        for name in ("healthy", "failing", "untrusted", "no-test", "undeclared"):
            root = fixture.project(name, "python: {}\n" if name == "no-test" else "")
            roots[name] = root
            if name != "no-test":
                command = 'printf "tested\\n" >> "$BASE_PROJECT_ROOT/tested"'
                if name == "failing":
                    command += "; exit 7"
                with (root / "base_manifest.yaml").open("a") as stream:
                    stream.write("test:\n  command: " + json.dumps(command) + "\n")
        manifest = fixture.root / "team workspace.yaml"
        manifest.write_text("schema_version: 1\nworkspace:\n  name: scenario\nrepos:\n"
                            "  - name: healthy\n  - name: failing\n  - name: untrusted\n"
                            "  - name: no-test\n  - name: missing\n"
                            "    url: https://github.com/example/missing.git\n")
        options = ("--workspace", fixture.workspace, "--manifest", manifest)
        for command in ("status", "onboarding", "agent-brief"):
            result = fixture.run("workspace", command, *options, "--format", "json", expected=(0, 1))
            payload = json.loads(result.stdout)
            assert payload["workspace"] == str(fixture.workspace)
            assert payload["workspace_manifest"]["path"] == str(manifest)
            assert "missing" in result.stdout
        assert not list(fixture.workspace.rglob("tested")), "read-only inventory executed a test"
        if not args.candidate:
            print("PASS: stable workspace status, onboarding and agent-brief are read-only")
            print("BOUNDARY: selected workspace tests, expanded inventory and targeted next_actions require the v1.10 candidate")
            return

        assert "test" in fixture.run("workspace", "--help").stdout
        reports = {}
        for command in ("onboarding", "agent-brief"):
            reports[command] = json.loads(fixture.run("workspace", command, *options, "--format", "json").stdout)
            actions = reports[command]["next_actions"]
            assert [a["order"] for a in actions] == list(range(1, len(actions) + 1))
        actions = reports["onboarding"]["next_actions"]
        assert [a["description"] for a in actions] == [
                "Clone missing repos", "Set up unconfigured projects", "Trust new manifests",
                "Review runtimes and verify workspace health",
            ]
        commands = [c for a in actions for c in a["commands"]]
        verify = shlex.split(commands[-1])
        assert verify[verify.index("--workspace") + 1] == str(fixture.workspace)
        assert verify[verify.index("--manifest") + 1] == str(manifest)
        actions = reports["agent-brief"]["next_actions"]
        names = ["healthy", "failing", "untrusted", "no-test", "missing", "undeclared"]
        assert [a["description"] for a in actions] == [f"Prepare repository {name}" for name in names]
        for name, action in zip(names, actions):
            assert action["commands"]
            assert all(str(fixture.workspace / name) in shlex.split(c) for c in action["commands"])
        inventory = {r["repository"]: r for r in reports["agent-brief"]["repositories"]}
        assert not inventory["undeclared"]["expected"]
        assert inventory["missing"]["required"] and inventory["missing"]["discovery_status"] == "missing"

        # The generated, digest-bound trust command must retain its workspace
        # even when invoked from another checkout with the same project name.
        other = fixture.root / "other workspace" / "healthy"
        other.mkdir(parents=True)
        (other / "base_manifest.yaml").write_text((roots["healthy"] / "base_manifest.yaml").read_text())
        entry = next(r for r in reports["onboarding"]["repositories"] if r["repository"] == "healthy")
        words = shlex.split(entry["trust_command"])
        assert words[:3] == ["basectl", "trust", "allow"]
        assert words[words.index("--workspace") + 1] == str(fixture.workspace)
        fixture.run(*words[1:], cwd=other)
        selected = fixture.run("trust", "status", "healthy", "--workspace", fixture.workspace)
        unselected = fixture.run("trust", "status", "healthy", "--workspace", other.parent)
        assert "\tallowed\t" in selected.stdout and "\tblocked\t" in unselected.stdout
        with (roots["healthy"] / "base_manifest.yaml").open("a") as stream:
            stream.write("\n# changed after recovery guidance\n")
        stale = fixture.run(*words[1:], cwd=other, expected=2)
        assert "SHA-256" in stale.stdout + stale.stderr
        for name in ("healthy", "failing"):
            fixture.run("trust", "allow", name, "--workspace", fixture.workspace)
        print("PASS: ordered recovery actions bind the reviewed checkout and reject stale manifest evidence")

        # Selection is a filter, not an execution-order override. Put the
        # failing peer first in declaration order for the fail-fast example.
        manifest.write_text(manifest.read_text().replace(
            "  - name: healthy\n  - name: failing\n", "  - name: failing\n  - name: healthy\n"))

        def tests(selection=None, fail_fast=False, expected=0):
            extra = ("--projects", selection) if selection else ()
            if fail_fast:
                extra += ("--fail-fast",)
            return json.loads(fixture.run("workspace", "test", *options, *extra,
                                          "--format", "json", expected=expected).stdout)

        result = tests("healthy")
        assert result["counts"] == {"passed": 1, "failed": 0, "skipped": 0}
        assert result["projects"][0]["path"] == str(roots["healthy"])
        assert (roots["healthy"] / "tested").read_text() == "tested\n"
        assert len(list(fixture.root.rglob("tested"))) == 1
        (roots["healthy"] / "tested").unlink()
        result = tests("failing,untrusted,no-test", expected=1)
        assert result["counts"] == {"passed": 0, "failed": 2, "skipped": 1}
        assert not (roots["untrusted"] / "tested").exists()
        result = tests("failing,healthy", fail_fast=True, expected=1)
        assert result["counts"] == {"passed": 0, "failed": 1, "skipped": 1}
        assert not (roots["healthy"] / "tested").exists()
        result = tests(expected=1)
        assert result["counts"] == {"passed": 1, "failed": 3, "skipped": 1}
        assert not (roots["undeclared"] / "tested").exists()
        assert not (other / "tested").exists()
        print("PASS: selected execution, failure, untrusted denial, skip, fail-fast and missing-required aggregate exit")

        alias = fixture.workspace / "alias"
        alias.symlink_to(roots["healthy"], target_is_directory=True)
        with manifest.open("a") as stream:
            stream.write("  - name: alias\n")
        fixture.run("workspace", "test", *options, "--projects", "healthy,alias", expected=2)
        result = tests("alias")
        assert result["counts"]["passed"] == 1
        assert result["projects"][0]["repository"] == "alias"
        fixture.no_ide_settings()
        print(f"PASS: alias selection cannot double-run one manifest; workspace scenario at Base {args.base_commit}")


if __name__ == "__main__":
    main()
