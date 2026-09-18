"""Offline fixtures for strict gates and server-owned evidence verification."""
import base64
import copy
import json
import runpy
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lib/release_contract"))
import demo_bom


def fixture():
    inputs = {"schema_version": 1, "components": {
        "base": {"version": "1.9.0", "commit": "b" * 40, "installer_sha256": "e" * 64},
        "base-cli": {"version": "0.4.3", "commit": "c" * 40},
        "base-bash-libs": {"version": "2.1.0", "commit": "d" * 40},
    }}
    release = {"repository": demo_bom.REPOSITORY, "version": "0.1.0", "tag": "v0.1.0", "commit": "a" * 40}
    url = "https://github.com/basefoundry/base-demo/actions/runs/123"
    components = []
    for name in ["base-demo", "base", "base-cli", "base-bash-libs"]:
        row = release if name == "base-demo" else inputs["components"][name]
        components.append({
            "repository": "basefoundry/" + name, "version": row["version"],
            "tag": "v" + row["version"], "commit": row["commit"], "source_mode": "release",
            "api_schema_version": "fixture-contract@1", "platforms": list(demo_bom.PLATFORMS),
            "required": True, "result": "passed", "evidence": url,
        })
    combinations = [{"name": platform, "participants": sorted(demo_bom.PARTICIPANTS),
                     "platform": platform, "required": True, "result": "passed", "evidence": url}
                    for platform in demo_bom.PLATFORMS]
    return {"schema_version": 1, "release": release, "components": components, "combinations": combinations}, inputs


class BomTests(unittest.TestCase):
    def setUp(self):
        self.bom, self.inputs = fixture()
        self.run = {"head_repository": {"full_name": demo_bom.REPOSITORY}, "head_sha": "a" * 40,
                    "path": ".github/workflows/tests.yml", "event": "push",
                    "status": "completed", "conclusion": "success"}
        self.jobs = {"total_count": 3, "jobs": [
            {"name": name, "labels": [platform], "status": "completed", "conclusion": "success"}
            for platform, name in demo_bom.PLATFORMS.items()
        ] + [{"name": "validate-base-cli-source", "status": "completed", "conclusion": "success"}]}
        self.tested_inputs = copy.deepcopy(self.inputs)

    def api(self, path):
        if "/jobs?" in path:
            return self.jobs
        if "/contents/" in path:
            return {"encoding": "base64", "content": base64.b64encode(json.dumps(self.tested_inputs).encode()).decode()}
        return self.run

    def check(self):
        with patch.object(demo_bom, "api", side_effect=self.api):
            demo_bom.check(self.bom, self.inputs, "0.1.0", "a" * 40)

    def test_valid_complete_immutable_bom(self):
        self.check()

    def test_invalid_corpus(self):
        mutations = {
            "boolean schema": lambda d: d.update(schema_version=True),
            "failed second combination": lambda d: d["combinations"][1].update(result="failed"),
            "missing self": lambda d: d["components"].pop(0),
            "missing provider": lambda d: d["components"].pop(),
            "self SHA": lambda d: d["components"][0].update(commit="f" * 40),
            "unknown source": lambda d: d["components"][1].update(source_mode="unknown"),
            "duplicate component": lambda d: d["components"].append(copy.deepcopy(d["components"][0])),
            "duplicate participant": lambda d: d["combinations"][0]["participants"].append("basefoundry/base"),
            "missing macOS": lambda d: d["combinations"].pop(0),
            "missing Ubuntu": lambda d: d["combinations"].pop(1),
            "pin mismatch": lambda d: d["components"][1].update(commit="f" * 40),
            "result scalar": lambda d: d["components"][1].update(result=True),
            "required scalar": lambda d: d["combinations"][1].update(required=1),
            "unknown key": lambda d: d["components"][1].update(extra="unexpected"),
            "wrong platform": lambda d: d["components"][1].update(platforms=["ubuntu-24.04"]),
            "duplicate name": lambda d: d["combinations"][1].update(name=d["combinations"][0]["name"]),
            "self version": lambda d: d["components"][0].update(version="0.2.0", tag="v0.2.0"),
            "release evidence": lambda d: d["combinations"][0].update(evidence="release://v0.1.0"),
            "untested": lambda d: d["components"][1].update(result="not_tested"),
            "unverified component evidence": lambda d: d["components"][1].update(evidence="release://v1.9.0"),
        }
        for name, mutate in mutations.items():
            with self.subTest(name=name):
                self.bom, self.inputs = fixture()
                mutate(self.bom)
                with self.assertRaises(ValueError):
                    self.check()

    def test_live_metadata_mismatch(self):
        for field, value in {"head_sha": "f" * 40, "conclusion": "failure", "event": "pull_request",
                             "path": ".github/workflows/untrusted.yml", "status": "in_progress",
                             "head_repository": {"full_name": "someone/fork"}}.items():
            with self.subTest(field=field):
                original = copy.deepcopy(self.run)
                self.run[field] = value
                with self.assertRaises(ValueError):
                    self.check()
                self.run = original

    def test_job_failure_wrong_runner_and_missing_source_lane(self):
        for mutation in (lambda j: j["jobs"][0].update(conclusion="failure"),
                         lambda j: j["jobs"][0].update(labels=["macos-latest"]),
                         lambda j: j["jobs"].pop(),
                         lambda j: j["jobs"].append(copy.deepcopy(j["jobs"][0]))):
            original = copy.deepcopy(self.jobs)
            mutation(self.jobs)
            with self.assertRaises(ValueError):
                self.check()
            self.jobs = original

    def test_run_input_drift(self):
        self.tested_inputs["components"]["base"]["commit"] = "f" * 40
        with self.assertRaisesRegex(ValueError, "dependency inputs"):
            self.check()

    def test_finalized_artifact_route(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "repo"
            (root / ".release").mkdir(parents=True)
            (root / "VERSION").write_text("0.1.0\n")
            (root / "install.sh").write_bytes((ROOT / "install.sh").read_bytes())
            (root / ".release/release-bom.json").write_text(json.dumps(self.bom))
            output = Path(temp) / "assets"
            subprocess.run([str(ROOT / "bin/base-demo-release-finalize"), "--repo", str(root),
                            "--commit", "a" * 40, "--output-dir", str(output)], check=True, capture_output=True)
            self.bom = json.loads((output / "release-bom.json").read_text())
            self.check()

    def test_finalizer_binds_only_verified_evidence(self):
        build = runpy.run_path(str(ROOT / "bin/base-demo-release-finalize"))["build_assets"]
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / ".release").mkdir()
            (root / "VERSION").write_text("0.1.0\n")
            (root / "install.sh").write_bytes((ROOT / "install.sh").read_bytes())
            for row in self.bom["components"] + self.bom["combinations"]:
                row.update(result="not_tested", evidence="pending")
            path = root / ".release/release-bom.json"
            path.write_text(json.dumps(self.bom))
            original = path.read_bytes()
            (root / ".release/supported-dependencies.json").write_text(json.dumps(self.inputs))
            with patch.object(demo_bom, "api", side_effect=self.api):
                _, content, _, _ = build(root, "a" * 40, "123")
                self.assertTrue(all(r["result"] == "passed" for r in json.loads(content)["components"]))
                self.run["conclusion"] = "failure"
                with self.assertRaises(SystemExit):
                    build(root, "a" * 40, "123")
            self.assertEqual(path.read_bytes(), original)

    def test_next_version_can_be_prepared_without_certifying_or_publishing_it(self):
        build = runpy.run_path(str(ROOT / "bin/base-demo-release-finalize"))["build_assets"]
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / ".release").mkdir()
            (root / "VERSION").write_text("0.2.0\n")
            (root / "install.sh").write_bytes((ROOT / "install.sh").read_bytes())
            self.bom["release"].update(version="0.2.0", tag="v0.2.0")
            self.bom["components"][0].update(version="0.2.0", tag="v0.2.0")
            for row in self.bom["components"] + self.bom["combinations"]:
                row.update(result="not_tested", evidence="pending")
            (root / ".release/release-bom.json").write_text(json.dumps(self.bom))
            tag, content, installer, _ = build(root, "a" * 40)
            self.assertEqual(tag, "v0.2.0")
            self.assertIn(b'PROJECT_RELEASE_REF="${PROJECT_RELEASE_REF:-v0.2.0}"', installer)
            self.assertTrue(all(r["result"] == "not_tested" for r in json.loads(content)["components"]))
            with self.assertRaises(ValueError):
                demo_bom.check(json.loads(content), self.inputs, "0.2.0", "a" * 40)
            self.assertFalse((root / ".git").exists())


if __name__ == "__main__":
    unittest.main()
