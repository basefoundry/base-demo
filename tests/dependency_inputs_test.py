"""The selection record and its materialized consumers must never drift."""
import json
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InputsTests(unittest.TestCase):
    def check(self, root):
        return subprocess.run(["python3", str(ROOT / "bin/base-demo-dependencies"), "--repo", str(root), "--check"],
                              capture_output=True, text=True)

    def test_current_inputs_match(self):
        result = self.check(ROOT)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_materialized_drift_fails(self):
        for filename in ("install.sh", "pyproject.toml", "uv.lock", ".release/release-bom.json"):
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                (root / ".release").mkdir()
                for name in ("install.sh", "pyproject.toml", "uv.lock", ".release/release-bom.json",
                             ".release/supported-dependencies.json"):
                    shutil.copyfile(ROOT / name, root / name)
                path = root / filename
                text = path.read_text()
                if filename == "install.sh":
                    text = text.replace("BASE_RELEASE_REF:-v1.9.0", "BASE_RELEASE_REF:-v1.8.0")
                elif filename == "pyproject.toml":
                    text = text.replace("base-cli==0.5.1", "base-cli==0.5.0")
                elif filename == "uv.lock":
                    text = text.replace('name = "base-cli"\nversion = "0.5.1"', 'name = "base-cli"\nversion = "0.5.0"')
                else:
                    document = json.loads(text)
                    document["components"][1]["commit"] = "f" * 40
                    text = json.dumps(document)
                path.write_text(text)
                result = self.check(root)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("does not match", result.stderr)

    def test_github_outputs_are_only_validated_scalars(self):
        result = subprocess.run(["python3", str(ROOT / "bin/base-demo-dependencies"), "--github-output"],
                                capture_output=True, text=True, check=True)
        output = dict(line.split("=", 1) for line in result.stdout.splitlines())
        self.assertEqual(output["base_version"], "1.9.0")
        self.assertEqual(output["base_cli_version"], "0.5.1")
        self.assertEqual(len(output["base_commit"]), 40)

    def test_advisory_candidate_pin_matches_documented_references(self):
        workflow = (ROOT / ".github/workflows/scenarios.yml").read_text()
        match = re.search(
            r"- lane: advisory-v1\.10-candidate\s+base: ([0-9a-f]{40})",
            workflow,
        )
        self.assertIsNotNone(match)
        candidate = match.group(1)
        stable = json.loads(
            (ROOT / ".release/supported-dependencies.json").read_text()
        )["components"]["base"]["commit"]
        documented = set()
        for filename in (
            "docs/trust-scenarios.md",
            "docs/workspace-scenarios.md",
            "docs/first-success.md",
        ):
            with self.subTest(filename=filename):
                text = (ROOT / filename).read_text()
                self.assertIn(candidate, text)
                documented.update(re.findall(r"\b[0-9a-f]{40}\b", text))
        self.assertEqual(documented, {stable, candidate})


if __name__ == "__main__":
    unittest.main()
