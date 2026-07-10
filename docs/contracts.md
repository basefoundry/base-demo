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
| `environment-schema` | Every `environments/*.json` file is validated against `REQUIRED_FIELDS` before use. | `bin/base-demo-environments`, `environments/*.json` | `tests/environments_test.bats`, `tests/validate.sh` | Modeled environments can omit required fields or become structurally invalid without being caught. | Environments |
| `uv-runner-command` | The `uv-info` command uses `runner: uv` in the manifest. | `base_manifest.yaml`, `src/uv-info.py` | `tests/validate.sh`, `tests/demo_test.bats` | The runner teaching surface silently becomes an ordinary command and no longer proves command-level runner selection. | Manifest |
| `activation-owned-env` | `.base/activate.sh` owns the `BASE_DEMO_ENV=baseline` default for the green path. | `.base/activate.sh`, `base_manifest.yaml` `health.required_env` | `tests/validate.sh`, `tests/demo_test.bats` | Health checks pass because unrelated shell state sets the variable, hiding activation drift. | Activation |
| `manifest-artifacts` | The manifest `artifacts` list stays non-empty and includes the `bats-core` tool artifact. | `base_manifest.yaml` | `tests/validate.sh`, `demo/demo.sh` | Setup no longer demonstrates artifact reconciliation or the test tool prerequisite. | Manifest |
| `runtime-platform-env` | The `env` command prints `BASE_OS`, `BASE_PLATFORM`, and `BASE_HOST` with the other Base runtime values. | `src/env.sh` | `tests/validate.sh`, `tests/demo_test.bats`, `demo/demo.sh` | Learners cannot discover the current Base runtime platform contract from base-demo. | Runtime |
| `installer-checksum` | Downloaded Base installers are verified when `BASE_INSTALL_SHA256` is set and warn when it is empty. | `install.sh` | `tests/install_test.bats` | Pinned installer URLs can execute without checksum verification or a visible warning. | Security |
| `service-log-permissions` | Process-backed service log files are created or corrected to mode `0600` before writes. | `bin/base-demo-services` | `tests/services_test.bats` | Service logs can expose local process output through permissive file modes. | Security |
| `ci-pinned-dependencies` | CI uses a pinned Base release and full SHA-pinned GitHub Actions. | `.github/workflows/tests.yml` | `tests/validate.sh` | CI can drift with Base `main` or mutable action tags instead of validating the intended release contract. | CI |
| `ubuntu-ci` | The repository has an Ubuntu read-only CI job that runs `basectl ci check base-demo --format json` against the pinned Base release. | `.github/workflows/tests.yml` | `tests/validate.sh`, GitHub Actions `validate-ubuntu` | Linux support can drift from the documented read-only CI boundary. | CI |
| `platform-boundary` | README and CONTRIBUTING document macOS full-demo support and Ubuntu/Linux read-only CI support. | `README.md`, `CONTRIBUTING.md` | `tests/validate.sh` | Developers on Linux follow macOS-only setup steps without a documented boundary. | Docs |
| `ci-json-check` | The demo shows `basectl ci check base-demo --format json` and asserts JSON status output. | `demo/demo.sh`, `README.md` | `tests/validate.sh`, `tests/demo_test.bats`, `.github/workflows/tests.yml` | The reference project stops demonstrating Base's CI-safe machine-readable check path. | CI |

## How To Use This Registry

When a change introduces a new promise between files, add a row here and make
sure `tests/validate.sh` or a focused BATS test fails if the promise drifts.
When deleting or changing a contract, update this registry in the same pull
request as the implementation and documentation changes.
