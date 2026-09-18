"""Rehearse the evaluator command sequence in a disposable minimal project."""
from pathlib import Path
import shutil

from fixture import Fixture, arguments


def main():
    args = arguments(__doc__)
    source = Path(__file__).resolve().parents[2]
    with Fixture(args) as fixture:
        root = fixture.project("base-demo")
        (root / "base_manifest.yaml").write_text(
            "project:\n  name: base-demo\nartifacts: []\n"
            "commands:\n  hello: ./src/hello.sh\ntest:\n  command: ./src/hello.sh\n")
        (root / "src").mkdir()
        shutil.copy2(source / "src/hello.sh", root / "src/hello.sh")
        (root / ".ai-context").mkdir()
        (root / ".ai-context/overview.md").write_text("# Disposable evaluator handoff\n")
        fixture.run("run", "--list", cwd=root)
        fixture.run("test", "--dry-run", cwd=root)
        fixture.run("trust", "status", "base-demo", "--workspace", fixture.workspace, cwd=root)
        fixture.run("run", "hello", cwd=root, expected=1)
        fixture.run("trust", "allow", "base-demo", "--workspace", fixture.workspace, cwd=root)
        fixture.env["BASE_DEMO_ENV"] = "baseline"
        output = fixture.run("run", "hello", cwd=root).stdout
        for expected in ("hello from base-demo", "BASE_PROJECT=base-demo", "BASE_DEMO_ENV=baseline"):
            assert expected in output
        handoff = fixture.run("export-context", "--format", "markdown", "--print", cwd=root).stdout
        assert "Disposable evaluator handoff" in handoff
        fixture.no_ide_settings()
        print("PASS: evaluator inspection, safe denial/recovery, actual hello script and context handoff")
        print("SCOPE: minimal project rehearsal; full setup/toolchain validation remains the hosted demo gate")


if __name__ == "__main__":
    main()
