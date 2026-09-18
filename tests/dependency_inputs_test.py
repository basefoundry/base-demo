"""The selection record and its materialized consumers must never drift."""
import json
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
                    text = text.replace("base-cli==0.4.3", "base-cli==0.4.2")
                elif filename == "uv.lock":
                    text = text.replace('name = "base-cli"\nversion = "0.4.3"', 'name = "base-cli"\nversion = "0.4.2"')
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
        self.assertEqual(output["base_cli_version"], "0.4.3")
        self.assertEqual(len(output["base_commit"]), 40)


if __name__ == "__main__":
    unittest.main()
