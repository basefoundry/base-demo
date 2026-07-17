# base-demo Contracts

base-demo contracts are binding promises that should fail loudly when
implementation, docs, demo behavior, or CI drift apart. This registry lists the
highest-value invariants for the reference project and points each one at its
source of truth and executable enforcement.

Update this file when adding a new durable invariant, expanding the
representative environment, or changing demo behavior that other docs or tests
depend on.

## Contract Registry

| Contract | Promise | Source of truth | Enforced by | Failure mode | Area |
| --- | --- | --- | --- | --- | --- |
| `project-baseline-required` | The `project-baseline` catalog entry remains present and `required: true`. | `services/catalog.json` | `tests/validate.sh`, `tests/services_test.bats` | The baseline project health entry can become optional or disappear, making service checks pass while the project shape is broken. | Services |
| `http-health-url` | Every service with `check.type == "http"` declares a non-empty `health_url`. | `services/catalog.json` | `tests/validate.sh`, `tests/services_test.bats` | HTTP checks cannot report a useful endpoint, or service status drifts from the catalog. | Services |
| `non-interactive-demo` | `demo/demo.sh --non-interactive` succeeds in the baseline CI environment. | `demo/demo.sh`, `base_manifest.yaml` `demo.script` | `tests/demo_test.bats`, `.github/workflows/tests.yml` | The project-owned walkthrough becomes stale, interactive-only, or unable to prove the documented Base loop. | Demo |
| `manifest-trust-flow` | The user-facing Base loop reviews safe list/dry-run surfaces before `basectl trust allow base-demo`, and only then executes project-owned manifest commands. | `README.md`, `.github/workflows/tests.yml` | `tests/validate.sh` | The Quick Start can drift from Base's fail-closed manifest-command trust model, causing first-run command execution to fail or encouraging unreviewed approval. | Security |
| `language-profile` | `project.languages` declares the normalized Python, Go, Java, C, C++, and JavaScript profile represented by the committed fixtures; the list is metadata-only. | `base_manifest.yaml`, `services/` | `tests/validate.sh`, `tests/demo_test.bats`, `.github/workflows/tests.yml` | The representative environment can drift away from the manifest taxonomy, or the manifest can imply unsupported automatic toolchain setup. | Manifest |
| `environment-schema` | Every `environments/*.json` file is validated against `REQUIRED_FIELDS` before use. | `bin/base-demo-environments`, `environments/*.json` | `tests/environments_test.bats`, `tests/validate.sh` | Modeled environments can omit required fields or become structurally invalid without being caught. | Environments |
| `uv-runner-command` | The `uv-info` command uses `runner: uv` in the manifest. | `base_manifest.yaml`, `src/uv-info.py` | `tests/validate.sh`, `tests/demo_test.bats` | The runner teaching surface silently becomes an ordinary command and no longer proves command-level runner selection. | Manifest |
| `activation-owned-env` | `.base/activate.sh` owns the `BASE_DEMO_ENV=baseline` default for the green path. | `.base/activate.sh`, `base_manifest.yaml` `health.required_env` | `tests/validate.sh`, `tests/demo_test.bats` | Health checks pass because unrelated shell state sets the variable, hiding activation drift. | Activation |
| `manifest-artifacts` | The manifest `artifacts` list stays non-empty and includes the `bats-core` tool artifact. | `base_manifest.yaml` | `tests/validate.sh`, `demo/demo.sh` | Setup no longer demonstrates artifact reconciliation or the test tool prerequisite. | Manifest |
| `runtime-platform-env` | The `env` command prints `BASE_OS`, `BASE_PLATFORM`, `BASE_HOST_ENV`, and `BASE_HOST` with the other Base runtime values. | `src/env.sh` | `tests/validate.sh`, `tests/demo_test.bats`, `demo/demo.sh` | Learners cannot discover the current Base runtime platform and host-environment contract from base-demo. | Runtime |
| `installer-checksum` | Downloaded Base installers are verified when `BASE_INSTALL_SHA256` is set and warn when it is empty. | `install.sh` | `tests/install_test.bats` | Pinned installer URLs can execute without checksum verification or a visible warning. | Security |
| `service-log-permissions` | Process-backed service log files are created or corrected to mode `0600` before writes. | `bin/base-demo-services` | `tests/services_test.bats` | Service logs can expose local process output through permissive file modes. | Security |
| `ci-pinned-dependencies` | CI uses a pinned Base v1.7.0 release checkout, a compatible SHA-pinned base-bash-libs checkout, and full SHA-pinned GitHub Actions. | `.github/workflows/tests.yml` | `tests/validate.sh` | CI can drift with Base `main` or mutable action tags instead of validating the intended capability contract. | CI |
| `ubuntu-ci` | The repository has an Ubuntu job that runs `basectl setup base --yes --no-notify`, validates `basectl setup base --profile dev --yes --no-notify`, verifies `bats`/`gh`/`shellcheck`, and runs `basectl check --ci base-demo --format json` against the pinned Base checkout. | `.github/workflows/tests.yml` | `tests/validate.sh`, GitHub Actions `validate-ubuntu` | Ubuntu support can drift from the documented Base setup, dev-profile, and read-only project health boundary. | CI |
| `platform-boundary` | README and CONTRIBUTING document macOS full-demo support plus Ubuntu/Debian and WSL2 support for Base setup, dev-profile prerequisites, read-only project health checks, repo-location guidance, and the native-Windows non-goal. | `README.md`, `CONTRIBUTING.md` | `tests/validate.sh` | Developers on Linux or WSL2 follow macOS-only project setup or demo steps without a documented boundary. | Docs |
| `ci-json-check` | The demo shows `basectl check --ci base-demo --format json` and asserts JSON status output. | `demo/demo.sh`, `README.md` | `tests/validate.sh`, `tests/demo_test.bats`, `.github/workflows/tests.yml` | The reference project stops demonstrating Base's CI-safe machine-readable check path. | CI |

## How To Use This Registry

When a change introduces a new promise between files, add a row here and make
sure `tests/validate.sh` or a focused BATS test fails if the promise drifts.
When deleting or changing a contract, update this registry in the same pull
request as the implementation and documentation changes.
