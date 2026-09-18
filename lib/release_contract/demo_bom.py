"""Demo release policy layered on Base's governed BOM validator."""
from __future__ import annotations

import base64
import json
import re
import subprocess

from dependency_inputs import validate_inputs
from release_bom import ReleaseBomError, validate_bom

REPOSITORY = "basefoundry/base-demo"
PARTICIPANTS = {REPOSITORY, "basefoundry/base", "basefoundry/base-cli", "basefoundry/base-bash-libs"}
PLATFORMS = {"macos-14": "validate", "ubuntu-24.04": "validate-ubuntu"}
RUN_URL = re.compile(r"https://github\.com/basefoundry/base-demo/actions/runs/([1-9][0-9]*)\Z")


def api(path):
    result = subprocess.run(["gh", "api", path], capture_output=True, check=False, timeout=60)
    if result.returncode:
        raise ValueError("GitHub evidence lookup failed; authenticate gh with actions/contents read access")
    return json.loads(result.stdout)


def verify_run(evidence, platform, commit, inputs):
    """Verify server-owned status and immutable inputs, not a URL's spelling.

    The trust root is the reviewed workflow at the releasing commit. This
    inspection does not execute project code or accept caller-authored receipts.
    """
    match = RUN_URL.fullmatch(evidence)
    if not match:
        raise ValueError("evidence must name a concrete base-demo Actions run, not release:// or pending evidence")
    run_id = match.group(1)
    run = api(f"repos/{REPOSITORY}/actions/runs/{run_id}")
    if (
        run.get("head_repository", {}).get("full_name") != REPOSITORY
        or run.get("head_sha") != commit
        or run.get("path") != ".github/workflows/tests.yml"
        or run.get("event") not in {"push", "workflow_dispatch"}
        or run.get("status") != "completed" or run.get("conclusion") != "success"
    ):
        raise ValueError("evidence run must be a successful trusted workflow run at the exact release commit")
    jobs = api(f"repos/{REPOSITORY}/actions/runs/{run_id}/jobs?per_page=100")
    if jobs.get("total_count", 0) > 100:
        raise ValueError("evidence run exceeds the bounded job inventory; review the workflow")
    required = {PLATFORMS[platform], "validate-base-cli-source"}
    found = set()
    for job in jobs.get("jobs", []):
        name = job.get("name")
        if name not in required:
            continue
        if name in found or job.get("status") != "completed" or job.get("conclusion") != "success":
            raise ValueError("required evidence job must uniquely complete successfully")
        if name == PLATFORMS[platform] and platform not in job.get("labels", []):
            raise ValueError(f"evidence job must execute on {platform}")
        found.add(name)
    if found != required:
        raise ValueError("evidence is missing required platform or source-provider jobs")
    source = api(f"repos/{REPOSITORY}/contents/.release/supported-dependencies.json?ref={commit}")
    if source.get("encoding") != "base64":
        raise ValueError("could not verify the run's supported dependency inputs")
    tested = json.loads(base64.b64decode(source["content"]))
    validate_inputs(tested)
    if tested != inputs:
        raise ValueError("evidence run dependency inputs do not match the release BOM inputs")


def check(document, inputs, version, expected_commit=None, verify=verify_run):
    """Fail closed on incomplete identity, coverage, or live run provenance."""
    validate_bom(document, expected_repository=REPOSITORY, expected_version=version)
    if expected_commit and document["release"]["commit"] != expected_commit:
        raise ReleaseBomError("release.commit must match the tagged GITHUB_SHA")
    pins = validate_inputs(inputs)
    rows = {row["repository"].casefold(): row for row in document["components"]}
    if set(rows) != PARTICIPANTS:
        raise ValueError("BOM must contain exactly the four supported release participants")
    for repository, row in rows.items():
        if not row["required"] or row["source_mode"] not in {"release", "tag"}:
            raise ValueError(f"{repository} must be a required immutable participant")
        if len(row["platforms"]) != len(set(row["platforms"])):
            raise ValueError(f"{repository} has duplicate platforms")
        if not set(PLATFORMS).issubset(row["platforms"]):
            raise ValueError(f"{repository} must cover macos-14 and ubuntu-24.04")
        identity = document["release"] if repository == REPOSITORY else pins[repository.split("/")[1]]
        if (row["version"], row["commit"]) != (identity["version"], identity["commit"]):
            raise ValueError(f"{repository} identity does not match supported inputs or release identity")
    names, coverage, evidence = set(), set(), set()
    for row in document["combinations"]:
        if row["name"] in names:
            raise ValueError("combination names must be unique")
        names.add(row["name"])
        participants = [name.casefold() for name in row["participants"]]
        if len(participants) != len(set(participants)):
            raise ValueError("combination participants must not be duplicated")
        if not row["required"]:
            continue
        platform = row["platform"]
        if set(participants) != PARTICIPANTS or platform not in PLATFORMS:
            raise ValueError("required combinations must cover the supported four-repository platform stack")
        verify(row["evidence"], platform, document["release"]["commit"], inputs)
        coverage.add(platform)
        evidence.add(row["evidence"])
    if coverage != set(PLATFORMS):
        raise ValueError("passing required evidence is needed for both macos-14 and ubuntu-24.04")
    if any(row["evidence"] not in evidence for row in rows.values()):
        raise ValueError("component evidence must reference a verified required compatibility run")
