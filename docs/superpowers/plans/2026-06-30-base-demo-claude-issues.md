# Base Demo Claude Issues Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the new Claude-filed base-demo issues into a safe PR train that expands Base 1.3.0 feature coverage without making the demo brittle.

**Architecture:** Keep base-demo as a compact representative environment. Manifest-field issues should update `base_manifest.yaml`, the README contract map, `.ai-context/manifest.md`, and `tests/validate.sh` together. Walkthrough issues should update `demo/demo.sh` and `tests/demo_test.bats` together, using fake `basectl` outputs in BATS and graceful observed commands where local machine state can vary.

**Tech Stack:** Bash, BATS, Base CLI (`basectl`), Base manifest YAML, Homebrew/Brewfile, Go, Python `base_cli`, GitHub Actions on macOS.

---

## Current Issue Assessment

| Issue | Assessment | Plan |
| --- | --- | --- |
| #108 `health.required_ports` | Real manifest coverage gap. | Implement. Use a safe default-free app port, not common local PostgreSQL 5432. |
| #109 `python.requires_python` | Real manifest coverage gap. | Implement with #108 as a runtime/health manifest PR. |
| #110 `artifacts` | Already resolved by PR #105 with `bats-core`. | Close as duplicate/resolved, no code. |
| #111 build target `working_dir` | Real build manifest coverage gap. | Implement on `go-api`; keep `build.sh` as standalone direct-service script. |
| #112 `runner: uv` | Real command-runner coverage gap, but needs `uv` dependency. | Implement as separate uv-backed command and add `uv` to Brewfile. |
| #113 `basectl repo check` | Already in `demo/demo.sh` Step 1 and BATS. | Close as resolved, no code. |
| #114 post-activation `doctor` | Already in activation step; check and doctor both run twice. | Close as resolved, no code. |
| #115 logs/history | Real walkthrough coverage gap. | Implement in demo observability PR. |
| #116 config show | Real walkthrough coverage gap. | Implement in demo observability PR. |
| #117 workspace status | Real walkthrough coverage gap; needs repo-owned manifest example. | Implement in demo observability PR. |
| #118 export-context | Real walkthrough coverage gap. | Implement in demo observability PR, using `--print` to avoid dirtying the repo. |
| #119 `base_demo_cli` subcommands | Real Python CLI teaching gap. | Implement as its own PR; larger than the walkthrough-only issues. |
| #120 IDE manifest field | Real manifest coverage gap, but headless CI needs IDE opt-out. | Implement as its own PR after the Base v1.3.0 CI prerequisite. |

## Cross-Cutting Prerequisite: CI Must Use Base v1.3.0

The new issues target Base 1.3.0-era manifest features. Current `.github/workflows/tests.yml` still clones `basefoundry/base` at `v0.4.4`, which can reject newer manifest fields or miss newer commands. Do this before manifest-field PRs.

### Task 0: Close Already-Resolved Issues

**Files:** none

- [ ] **Step 1: Close #110 as resolved by PR #105**

Run:

```bash
gh issue close 110 --repo basefoundry/base-demo --comment "Closing as already resolved by PR #105. \`base_manifest.yaml\` now declares a non-empty \`artifacts\` list with the \`bats-core\` tool artifact, and README/demo/validation coverage make the setup artifact behavior visible."
```

- [ ] **Step 2: Close #113 as resolved by existing demo coverage**

Run:

```bash
gh issue close 113 --repo basefoundry/base-demo --comment "Closing as already resolved on current main. \`demo/demo.sh\` Step 1 runs \`basectl repo check .\`, asserts \`Repository baseline\`, and \`tests/demo_test.bats\` verifies the command."
```

- [ ] **Step 3: Close #114 as resolved by existing activation coverage**

Run:

```bash
gh issue close 114 --repo basefoundry/base-demo --comment "Closing as already resolved on current main. \`demo/demo.sh\` re-runs both \`basectl check\` and \`basectl doctor\` after activation, and \`tests/demo_test.bats\` verifies each command is called twice."
```

### Task 1: Update CI Base Version Prerequisite

**Files:**
- Modify: `.github/workflows/tests.yml`

- [ ] **Step 1: Create a branch**

Run:

```bash
git checkout -b chore/base-13-ci-prerequisite
```

- [ ] **Step 2: Update the Base checkout tag**

Change:

```yaml
      - name: Check out Base
        run: git clone --depth 1 --branch v0.4.4 https://github.com/basefoundry/base.git ../base
```

to:

```yaml
      - name: Check out Base
        run: git clone --depth 1 --branch v1.3.0 https://github.com/basefoundry/base.git ../base
```

- [ ] **Step 3: Validate**

Run:

```bash
./tests/validate.sh
bats tests/demo_test.bats
git diff --check
```

Expected: all pass.

- [ ] **Step 4: Commit and PR**

Run:

```bash
git add .github/workflows/tests.yml
git commit -m "Pin base-demo CI to Base v1.3.0"
git push -u origin chore/base-13-ci-prerequisite
gh pr create --repo basefoundry/base-demo --base main --head chore/base-13-ci-prerequisite --title "Pin base-demo CI to Base v1.3.0" --body $'## Summary\n- Update the Base checkout used by CI from v0.4.4 to v1.3.0 so new manifest fields are validated against the Base version they target.\n\n## Validation\n- ./tests/validate.sh\n- bats tests/demo_test.bats\n- git diff --check'
```

---

## Train A: Runtime And Health Manifest Fields (#108, #109)

Implement `python.requires_python` and a baseline port health check together because both affect `basectl check` and `basectl doctor`.

**Files:**
- Modify: `base_manifest.yaml`
- Modify: `README.md`
- Modify: `.ai-context/manifest.md`
- Modify: `demo/demo.sh`
- Modify: `tests/validate.sh`
- Modify: `tests/demo_test.bats`

### Task 2: Add Failing Validation Guards

- [ ] **Step 1: Add `tests/validate.sh` guards**

Add guards near the existing manifest checks:

```bash
grep -Fq 'requires_python: "3.13"' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare python.requires_python 3.13.\n' >&2
  exit 1
}

grep -Fq 'required_ports:' base_manifest.yaml && grep -Fq 'name: go-api' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the go-api required port health check.\n' >&2
  exit 1
}

grep -Fq 'python.requires_python' README.md || {
  printf 'README.md does not document python.requires_python.\n' >&2
  exit 1
}

grep -Fq 'health.required_ports' README.md || {
  printf 'README.md does not document health.required_ports.\n' >&2
  exit 1
}
```

- [ ] **Step 2: Run validation and confirm it fails**

Run:

```bash
./tests/validate.sh
```

Expected: fails with `base_manifest.yaml does not declare python.requires_python 3.13.`

### Task 3: Implement Manifest Runtime And Port Fields

- [ ] **Step 1: Update `base_manifest.yaml`**

Change:

```yaml
health:
  required_env:
    - BASE_DEMO_ENV
```

to:

```yaml
health:
  required_env:
    - BASE_DEMO_ENV
  required_ports:
    - name: go-api
      host: 127.0.0.1
      port: 8010
      state: free

python:
  requires_python: "3.13"
```

Use `go-api` port `8010` instead of PostgreSQL `5432`; `5432` is commonly occupied on developer machines and would make the green-path demo brittle.

- [ ] **Step 2: Update README contract map**

Add rows after `health.required_env` and `mise`:

```markdown
| `health.required_ports` | `basectl check base-demo` | Declares that the baseline `go-api` port 8010 should be free before services are started. |
| `python.requires_python` | `basectl check base-demo` | Lets Base verify Python 3.13 independently of the mise installer declaration. |
```

- [ ] **Step 3: Update `.ai-context/manifest.md`**

Add matching rows:

```markdown
| `health.required_ports` | `basectl check` / `doctor` | Baseline `go-api` port 8010 is expected to be free before services are started |
| `python.requires_python` | `basectl check` / `doctor` | Base validates Python 3.13 separately from mise installing it |
```

- [ ] **Step 4: Update demo manifest step**

Add these `grep` commands to `manifest_step()`:

```bash
  run_command grep -n "required_ports:" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "requires_python:" "$BASE_DEMO_ROOT/base_manifest.yaml"
```

- [ ] **Step 5: Update fake demo output if needed**

If `tests/demo_test.bats` fake check/doctor output is too generic, include port/Python text:

```bash
printf 'ok     Python runtime satisfies python.requires_python 3.13.\n'
printf 'ok     Port go-api 127.0.0.1:8010 is free.\n'
```

- [ ] **Step 6: Validate**

Run:

```bash
./tests/validate.sh
bats tests/demo_test.bats
/Users/rameshhp/work/base/bin/basectl check base-demo --manifest ./base_manifest.yaml
/Users/rameshhp/work/base/bin/basectl doctor base-demo --manifest ./base_manifest.yaml
git diff --check
```

Expected: local checks pass unless port `8010` is already in use. If it is in use locally, verify in CI and note the local port collision in the PR body.

---

## Train B: Build Target Working Directory (#111)

Keep the standalone service build script intact for direct testing, but make the Base build target demonstrate `working_dir`.

**Files:**
- Modify: `base_manifest.yaml`
- Modify: `README.md`
- Modify: `.ai-context/manifest.md`
- Modify: `tests/validate.sh`
- Modify: `tests/go_api_test.bats`

### Task 4: Add Working Directory To `go-api` Build Target

- [ ] **Step 1: Add failing guards**

Add to `tests/validate.sh`:

```bash
grep -Fq 'working_dir: services/go-api' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare working_dir for the go-api build target.\n' >&2
  exit 1
}

grep -Fq 'build.targets[*].working_dir' README.md || {
  printf 'README.md does not document build target working_dir.\n' >&2
  exit 1
}
```

- [ ] **Step 2: Run validation and confirm failure**

Run:

```bash
./tests/validate.sh
```

Expected: fails with the missing `working_dir` message.

- [ ] **Step 3: Update `base_manifest.yaml`**

Change:

```yaml
    go-api:
      description: Build the Go API service.
      command: ./services/go-api/build.sh
```

to:

```yaml
    go-api:
      description: Build the Go API service.
      working_dir: services/go-api
      command: CGO_ENABLED=0 go build -o build/go-api .
```

- [ ] **Step 4: Keep `services/go-api/build.sh` unchanged**

Do not remove its `cd` logic. The script remains the direct service build entrypoint used outside Base.

- [ ] **Step 5: Update docs**

Add a README contract map row:

```markdown
| `build.targets[*].working_dir` | `basectl build base-demo go-api` | Runs the Go build from `services/go-api` without the command needing to `cd` itself. |
```

Add a matching `.ai-context/manifest.md` row.

- [ ] **Step 6: Add BATS coverage**

In `tests/go_api_test.bats`, add:

```bash
@test "go api build target declares working_dir" {
  grep -Fq "working_dir: services/go-api" "$TEST_ROOT/base_manifest.yaml"
  grep -Fq "command: CGO_ENABLED=0 go build -o build/go-api ." "$TEST_ROOT/base_manifest.yaml"
}
```

- [ ] **Step 7: Validate**

Run:

```bash
./tests/validate.sh
bats tests/go_api_test.bats
/Users/rameshhp/work/base/bin/basectl build base-demo go-api --workspace ..
test -x services/go-api/build/go-api
git diff --check
```

Expected: binary exists at `services/go-api/build/go-api`.

---

## Train C: uv Runner Demonstration (#112)

Add a separate uv-backed command rather than routing `python-info` through uv. `python-info` should stay focused on Base's project wrapper and `base_cli`.

**Files:**
- Modify: `Brewfile`
- Modify: `base_manifest.yaml`
- Create: `src/uv-info.py`
- Modify: `README.md`
- Modify: `.ai-context/manifest.md`
- Modify: `demo/demo.sh`
- Modify: `tests/validate.sh`
- Modify: `tests/demo_test.bats`

### Task 5: Add A uv-Backed Command

- [ ] **Step 1: Add failing guards**

Add to `tests/validate.sh`:

```bash
grep -Fq 'brew "uv"' Brewfile || {
  printf 'Brewfile does not include uv for the runner demo.\n' >&2
  exit 1
}

grep -Fq 'uv-info:' base_manifest.yaml && grep -Fq 'runner: uv' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare a uv-backed command.\n' >&2
  exit 1
}
```

- [ ] **Step 2: Create `src/uv-info.py`**

```python
#!/usr/bin/env python3
"""Tiny uv-runner command for the Base demo."""

from __future__ import annotations

import sys


def main() -> int:
    print("base-demo uv runner")
    print(f"python={sys.version_info.major}.{sys.version_info.minor}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 3: Make it executable**

Run:

```bash
chmod +x src/uv-info.py
```

- [ ] **Step 4: Update `Brewfile`**

Add:

```ruby
brew "uv"
```

- [ ] **Step 5: Update `base_manifest.yaml`**

Change `commands:` from scalar-only style for this new command:

```yaml
  uv-info:
    command: python src/uv-info.py
    runner: uv
```

- [ ] **Step 6: Update demo command discovery and inspection**

Add `uv-info` to:

- `manifest_step()` grep list.
- `command_discovery_step()` `require_contains` list.
- `inspection_step()` as a short command after `python-info`.

Use:

```bash
  uv_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" uv-info)"
  printf '%s\n' "$uv_output"
  require_contains "uv command" "$uv_output" "base-demo uv runner"
```

- [ ] **Step 7: Update fake `basectl` in `tests/demo_test.bats`**

Add list output:

```bash
printf 'uv-info     python src/uv-info.py [runner: uv]\n'
```

Add command output:

```bash
run\ base-demo\ --workspace\ *\ uv-info)
  printf 'base-demo uv runner\n'
  printf 'python=3.13\n'
  ;;
```

Add state-file assertion:

```bash
grep -Eq "^basectl run base-demo --workspace .+ uv-info$" "$state_file"
```

- [ ] **Step 8: Validate**

Run:

```bash
./tests/validate.sh
bats tests/demo_test.bats
/Users/rameshhp/work/base/bin/basectl setup base-demo --manifest ./base_manifest.yaml --dry-run --no-notify
/Users/rameshhp/work/base/bin/basectl run base-demo --workspace .. uv-info
git diff --check
```

Expected: `basectl run ... uv-info` prints `base-demo uv runner`.

---

## Train D: IDE Manifest Demonstration (#120)

Add project IDE intent, but do not make CI install or require VS Code.

**Files:**
- Modify: `base_manifest.yaml`
- Modify: `README.md`
- Modify: `.ai-context/manifest.md`
- Modify: `tests/validate.sh`
- Modify: `.github/workflows/tests.yml`

### Task 6: Add VS Code IDE Manifest With CI Opt-Out

- [ ] **Step 1: Add failing guards**

Add to `tests/validate.sh`:

```bash
grep -Fq 'ide:' base_manifest.yaml && grep -Fq 'ms-python.python' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the VS Code IDE block.\n' >&2
  exit 1
}

grep -Fq 'python.defaultInterpreterPath: auto' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare automatic VS Code Python interpreter resolution.\n' >&2
  exit 1
}
```

- [ ] **Step 2: Update `base_manifest.yaml`**

Add:

```yaml
ide:
  vscode:
    install: false
    extensions:
      - ms-python.python
      - ms-python.vscode-pylance
    settings:
      python.defaultInterpreterPath: auto
```

- [ ] **Step 3: Update docs**

Add README contract map row:

```markdown
| `ide.vscode` | `basectl setup base-demo` | Declares VS Code Python extensions and auto-injects the project venv as `python.defaultInterpreterPath` when IDE setup is enabled. |
```

Add a matching `.ai-context/manifest.md` row.

- [ ] **Step 4: Disable IDE checks in CI user config**

After `Set up Base` in `.github/workflows/tests.yml`, add:

```yaml
      - name: Disable IDE setup in CI
        run: |
          mkdir -p ~/.base.d
          {
            printf '\nide:\n'
            printf '  enabled: false\n'
          } >> ~/.base.d/config.yaml
```

This preserves the project manifest demonstration while preventing headless CI from failing because `code` is not on `PATH`.

- [ ] **Step 5: Validate**

Run locally without disabling IDE:

```bash
/Users/rameshhp/work/base/bin/basectl setup base-demo --manifest ./base_manifest.yaml --dry-run --no-notify
```

Expected dry-run output includes `code --install-extension ms-python.python`, `code --install-extension ms-python.vscode-pylance`, or IDE settings merge output.

Then run:

```bash
./tests/validate.sh
git diff --check
```

Expected: pass.

---

## Train E: Walkthrough Observability And Workspace Coverage (#115, #116, #117, #118)

Keep this as one demo-only PR because all four issues touch `demo/demo.sh` and `tests/demo_test.bats`.

**Files:**
- Create: `workspace.yaml.example`
- Modify: `README.md`
- Modify: `demo/demo.sh`
- Modify: `tests/demo_test.bats`
- Modify: `tests/validate.sh`

### Task 7: Add Workspace Manifest Example

- [ ] **Step 1: Create `workspace.yaml.example`**

```yaml
schema_version: 1

workspace:
  name: base-demo-reference

repos:
  - name: base
    url: https://github.com/basefoundry/base.git
    default_branch: main
    required: true

  - name: base-demo
    url: https://github.com/basefoundry/base-demo.git
    default_branch: main
    required: true

  - name: base-bash-libs
    url: https://github.com/basefoundry/base-bash-libs.git
    default_branch: main
    required: false
```

- [ ] **Step 2: Add validation guard**

Add to `tests/validate.sh`:

```bash
grep -Fq 'workspace:' workspace.yaml.example && grep -Fq 'base-demo-reference' workspace.yaml.example || {
  printf 'workspace.yaml.example does not declare the base-demo reference workspace.\n' >&2
  exit 1
}
```

### Task 8: Add Workspace Status And Config Show

- [ ] **Step 1: Update `discovery_step()`**

Use the repo-owned example when present:

```bash
  if [[ -f "$BASE_DEMO_ROOT/workspace.yaml.example" ]]; then
    output="$(capture_command "$BASE_DEMO_BASECTL" workspace status --workspace "$BASE_DEMO_WORKSPACE" --manifest "$BASE_DEMO_ROOT/workspace.yaml.example")"
    printf '%s\n' "$output"
    require_contains "workspace status" "$output" "base-demo"
  else
    run_observed_command "$BASE_DEMO_BASECTL" workspace status --workspace "$BASE_DEMO_WORKSPACE"
  fi
```

- [ ] **Step 2: Update `inspection_step()`**

Add local Base config inspection:

```bash
  printf '\nInspecting machine-local Base configuration.\n'
  config_output="$(capture_command "$BASE_DEMO_BASECTL" config show)"
  printf '%s\n' "$config_output"
  require_contains "config show" "$config_output" "workspace"
```

Add `config_output` to the local variable list.

### Task 9: Add Logs, History, And Export Context Steps

- [ ] **Step 1: Add `observability_step()` after `test_step()`**

```bash
observability_step() {
  local logs_output history_output

  step 12 "Observability"
  printf 'Showing the recent Base command log index.\n'
  logs_output="$(capture_command "$BASE_DEMO_BASECTL" logs --limit 3)"
  printf '%s\n' "$logs_output"
  require_contains "logs command" "$logs_output" "base"

  printf '\nShowing recent command history for this project.\n'
  history_output="$(capture_command "$BASE_DEMO_BASECTL" history --project "$BASE_DEMO_PROJECT" --limit 5)"
  printf '%s\n' "$history_output"
  require_contains "history command" "$history_output" "$BASE_DEMO_PROJECT"
  pause
}
```

- [ ] **Step 2: Add `export_context_step()` after `demo_step()`**

Use `--print` to avoid writing generated files into the repo:

```bash
export_context_step() {
  local output

  step 15 "AI Context Export"
  output="$(capture_command "$BASE_DEMO_BASECTL" export-context "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" --format markdown --print)"
  printf '%s\n' "$output"
  require_contains "export-context" "$output" "$BASE_DEMO_PROJECT"
  require_contains "export-context" "$output" ".ai-context"
  pause
}
```

- [ ] **Step 3: Update `main()` order**

Call:

```bash
  test_step
  observability_step
  build_step
  demo_step
  export_context_step
```

The step numbers will naturally advance through the shared `step()` helper.

- [ ] **Step 4: Update fake `basectl` and BATS assertions**

Add fake cases:

```bash
  workspace\ status\ --workspace\ *\ --manifest\ *)
    printf 'WORKSPACE base-demo-reference\n'
    printf 'base-demo present healthy\n'
    ;;
  config\ show)
    printf '{\n  "workspace": {"root": "%s"}\n}\n' "${BASE_PROJECT_ROOT%/base-demo}"
    ;;
  logs\ --limit\ 3)
    printf 'base-demo.log basectl run base-demo hello\n'
    ;;
  history\ --project\ base-demo\ --limit\ 5)
    printf 'base-demo ok run hello\n'
    ;;
  export-context\ base-demo\ --workspace\ *\ --format\ markdown\ --print)
    printf '# AI Context Export: base-demo\n'
    printf '## .ai-context/manifest.md\n'
    ;;
```

Assert output includes:

```bash
[[ "$output" == *"Observability"* ]]
[[ "$output" == *"AI Context Export"* ]]
[[ "$output" == *"base-demo-reference"* ]]
[[ "$output" == *"workspace"* ]]
[[ "$output" == *"base-demo.log"* ]]
[[ "$output" == *"AI Context Export: base-demo"* ]]
```

Assert commands in state file:

```bash
grep -Eq "^basectl workspace status --workspace .+ --manifest .+/workspace.yaml.example$" "$state_file"
grep -Eq "^basectl config show$" "$state_file"
grep -Eq "^basectl logs --limit 3$" "$state_file"
grep -Eq "^basectl history --project base-demo --limit 5$" "$state_file"
grep -Eq "^basectl export-context base-demo --workspace .+ --format markdown --print$" "$state_file"
```

- [ ] **Step 5: Validate**

Run:

```bash
bats tests/demo_test.bats
./tests/validate.sh
/Users/rameshhp/work/base/bin/basectl demo base-demo --workspace .. -- --non-interactive
git diff --check
```

If local Base/project virtualenv drift causes the real demo run to fail, capture the exact warning and rely on BATS plus CI for the non-local path.

---

## Train F: Expand `base_demo_cli` (#119)

This is the largest new issue. Keep it separate so the Python CLI teaching surface can be reviewed without unrelated manifest/demo noise.

**Files:**
- Modify: `lib/python/base_demo_cli/__main__.py`
- Create: `lib/python/base_demo_cli/tests/test_cli.py`
- Modify: `bin/base-demo-python-info` only if needed
- Modify: `README.md`
- Modify: `.ai-context/manifest.md`
- Modify: `demo/demo.sh`
- Modify: `tests/demo_test.bats`
- Modify: `tests/validate.sh`
- Modify: `.github/workflows/tests.yml`

### Task 10: Add Python CLI Tests First

- [ ] **Step 1: Create `lib/python/base_demo_cli/tests/test_cli.py`**

```python
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
```

- [ ] **Step 2: Run the new tests and confirm failure**

Run:

```bash
PYTHONPATH=/Users/rameshhp/work/base/lib/python:/Users/rameshhp/work/base/cli/python:lib/python python -m unittest lib.python.base_demo_cli.tests.test_cli
```

Expected: fails because `info` and `env` subcommands do not exist yet.

### Task 11: Implement CLI Subcommands

- [ ] **Step 1: Replace flat command in `lib/python/base_demo_cli/__main__.py`**

```python
"""Entry point for the base-demo Python CLI."""

from __future__ import annotations

import os

import base_cli

app = base_cli.App(name="base_demo_cli")


@app.subcommand()
def info(ctx: base_cli.Context) -> int:
    """Show Base context values for base-demo."""
    ctx.log.debug("base_demo_cli info command")
    print("base-demo python cli")
    print(f"project_name={ctx.project_name}")
    print(f"project_root={ctx.project_root}")
    print(f"workspace_root={ctx.workspace_root}")
    return base_cli.ExitCode.SUCCESS


@app.subcommand()
def env(ctx: base_cli.Context) -> int:
    """Show BASE_* environment variables visible to the project command."""
    ctx.log.debug("base_demo_cli env command")
    for key in sorted(name for name in os.environ if name.startswith("BASE_")):
        print(f"{key}={os.environ[key]}")
    return base_cli.ExitCode.SUCCESS


@app.command()
def run(ctx: base_cli.Context) -> int:
    """Default to the info subcommand for backward-compatible invocation."""
    return info(ctx)


if __name__ == "__main__":
    app()
```

- [ ] **Step 2: Run Python tests**

Run:

```bash
PYTHONPATH=/Users/rameshhp/work/base/lib/python:/Users/rameshhp/work/base/cli/python:lib/python python -m unittest lib.python.base_demo_cli.tests.test_cli
```

Expected: pass.

- [ ] **Step 3: Add the test file to `tests/validate.sh` required files**

Add:

```bash
  lib/python/base_demo_cli/tests/test_cli.py
```

Then add a validation command:

```bash
PYTHONPATH="/Users/rameshhp/work/base/lib/python:/Users/rameshhp/work/base/cli/python:lib/python" \
  python -m unittest lib.python.base_demo_cli.tests.test_cli || exit 1
```

If absolute Base paths are not acceptable in CI, use the checked-out Base path in workflow-only validation and keep local `validate.sh` focused on file presence plus existing smoke tests.

### Task 12: Update Demo And CI For CLI Subcommands

- [ ] **Step 1: Update `demo/demo.sh`**

Change the existing `python-info` inspection command to call `info`:

```bash
  python_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" python-info -- info)"
  printf '%s\n' "$python_output"
  require_contains "python command" "$python_output" "project_name=base-demo"
```

Add the env subcommand:

```bash
  python_env_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" python-info -- env)"
  printf '%s\n' "$python_env_output"
  require_contains "python env command" "$python_env_output" "BASE_PROJECT=base-demo"
```

Add the debug example:

```bash
  run_observed_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" python-info -- --debug info
```

- [ ] **Step 2: Update `tests/demo_test.bats` fake basectl**

Add cases for:

```bash
run\ base-demo\ --workspace\ *\ python-info\ --\ info)
  printf 'base-demo python cli\n'
  printf 'project_name=base-demo\n'
  printf 'project_root=%s\n' "${BASE_PROJECT_ROOT:?}"
  printf 'workspace_root=%s\n' "$(dirname "${BASE_PROJECT_ROOT:?}")"
  ;;
run\ base-demo\ --workspace\ *\ python-info\ --\ env)
  printf 'BASE_PROJECT=base-demo\n'
  printf 'BASE_DEMO_ENV=%s\n' "${BASE_DEMO_ENV:-unset}"
  ;;
run\ base-demo\ --workspace\ *\ python-info\ --\ --debug\ info)
  printf 'DEBUG base_demo_cli info command\n' >&2
  printf 'project_name=base-demo\n'
  ;;
```

Keep the no-args `python-info` fake case during transition if other tests still expect it.

- [ ] **Step 3: Update CI command**

Change:

```yaml
      - name: Run base-demo Python command
        run: ../base/bin/basectl run base-demo --workspace .. python-info
```

to:

```yaml
      - name: Run base-demo Python info command
        run: ../base/bin/basectl run base-demo --workspace .. python-info -- info

      - name: Run base-demo Python env command
        run: ../base/bin/basectl run base-demo --workspace .. python-info -- env
```

- [ ] **Step 4: Validate**

Run:

```bash
PYTHONPATH=/Users/rameshhp/work/base/lib/python:/Users/rameshhp/work/base/cli/python:lib/python python -m unittest lib.python.base_demo_cli.tests.test_cli
bats tests/demo_test.bats
./tests/validate.sh
/Users/rameshhp/work/base/bin/basectl run base-demo --workspace .. python-info -- info
/Users/rameshhp/work/base/bin/basectl run base-demo --workspace .. python-info -- env
/Users/rameshhp/work/base/bin/basectl run base-demo --workspace .. python-info -- --debug info
git diff --check
```

Expected: all pass; debug output goes to stderr.

---

## Recommended PR Order

1. Close #110, #113, #114 as already resolved.
2. Merge the Base v1.3.0 CI prerequisite.
3. Implement #108 and #109 together.
4. Implement #111.
5. Implement #112.
6. Implement #120.
7. Implement #115, #116, #117, and #118 together.
8. Implement #119 last.

This order keeps the risky surfaces isolated: CI/Base version first, manifest checks before demo additions, uv as its own dependency change, IDE with explicit CI opt-out, then the Python CLI refactor.

## Validation Baseline For Every PR

Run these before opening each PR:

```bash
./tests/validate.sh
bats tests/demo_test.bats
git diff --check
```

For PRs touching Java or full service coverage, also run:

```bash
env GRADLE_USER_HOME=/private/tmp/base-demo-gradle-89 bats tests/*.bats
```

For manifest-field PRs, also run the relevant Base commands through the local Base checkout:

```bash
/Users/rameshhp/work/base/bin/basectl setup base-demo --manifest ./base_manifest.yaml --dry-run --no-notify
/Users/rameshhp/work/base/bin/basectl check base-demo --manifest ./base_manifest.yaml
/Users/rameshhp/work/base/bin/basectl doctor base-demo --manifest ./base_manifest.yaml
```

If the local project venv is stale because of Homebrew Python drift, record that as a local environment limitation and rely on BATS plus GitHub Actions for the final gate.
