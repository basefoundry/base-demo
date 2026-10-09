# Base capability and evidence matrix

This matrix is the compact release-review view of what `base-demo` proves about
Base. It is intentionally curated: it records user-facing capability evidence
and known boundaries without copying Base's internal test suite or inventing
evidence that this repository does not execute.

Current Base release: `1.9.0`  
Planned Base release: `1.10.0`

The stable CI lane exercises the immutable Base `v1.9.0` compatibility pin. A
separate advisory lane exercises the exact Base `v1.10.0` candidate commit; it
is useful release evidence, but does not establish released compatibility until
Base publishes `v1.10.0` and the final downstream BOM is verified. A moving
local Base checkout is useful for development, but does not by itself establish
either claim.

## Capability matrix

| Capability | Base release | Demo scenario and executable evidence | Platform boundary | Status | Owner | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| Bootstrap, project discovery, and guided onboarding | `1.9.0` | Quick Start and onboarding commands in [`README.md`](../README.md); repository and demo assertions in [`tests/demo_test.bats`](../tests/demo_test.bats) and [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) | Full setup and interactive demo on macOS; Base setup and read-only project health on Ubuntu/Debian | Demonstrated | Base + base-demo | Keep the command sequence aligned with Base's onboarding contract. |
| Manifest command review, explicit trust, and command execution | `1.9.0` | The trust boundary is documented in [`docs/contracts.md`](contracts.md) and exercised by the review, trust, run, build, and test steps in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) | macOS full loop; Linux CI uses the read-only and dry-run portions | Demonstrated | Base + base-demo | Preserve review-before-trust ordering when commands change. |
| Workspace onboarding, agent handoff, and AI context | `1.9.0` | Workspace onboarding and agent-brief JSON are checked in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml); the project context is indexed by [`.ai-context/overview.md`](../.ai-context/overview.md) | Workspace paths must be inside the configured workspace; WSL2 follows the Linux boundary | Demonstrated | Base + base-demo | Add a row when a new handoff artifact becomes user-facing. |
| Representative build, test, service, environment, and non-interactive demo loop | `1.9.0` | The manifest targets in [`base_manifest.yaml`](../base_manifest.yaml), baseline gate in [`tests/validate.sh`](../tests/validate.sh), and focused suites in [`tests/services_test.bats`](../tests/services_test.bats), [`tests/environments_test.bats`](../tests/environments_test.bats), and [`tests/demo_test.bats`](../tests/demo_test.bats) | Full project loop is macOS; Ubuntu/Debian validates Base setup and project health only | Demonstrated | base-demo | Add executable evidence before calling a new service or command demonstrated. |
| Linux and WSL2 read-only support boundary | `1.9.0` | The supported commands and explicit native-Windows boundary are in [`README.md`](../README.md) and [`docs/contracts.md`](contracts.md); CI's Ubuntu path is in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) | Ubuntu/Debian and WSL2 use setup, dev-profile, check, and doctor/read-only paths; native Windows is excluded | Demonstrated | Base + base-demo | Keep platform claims tied to a hosted or repository-local check. |
| Base `1.9.0` released-compatibility pin and full Go/live-HTTP evidence | `1.9.0` | Structured pins in [supported inputs](../.release/supported-dependencies.json), verified by `bin/base-demo-dependencies`; full-language and live-HTTP gates run in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) | Exact macOS 14 full demo and Ubuntu 24.04 setup/read-only scope; no Linux full-demo claim | Demonstrated | Base + base-demo | Keep the stable pin unchanged until the final v1.10.0 release BOM is verified; candidate refresh is tracked by #324. |
| Workspace inventory, selected tests, targeted recovery and update preflight safety | `1.9.0` reports; exact `1.10.0` candidate | `tests/scenarios/workspace.py` and [workspace scenario guide](workspace-scenarios.md), run by isolated scenario CI; candidate fixtures cover dirty, ancestor-checkout and mismatched-upstream protection | macOS fixture lane; selection, update preflight and expanded recovery require the exact candidate | Demonstrated | Base + base-demo | Refresh candidate evidence before release; do not claim stable 1.10 support. |
| Trust lifecycle and separate runtime/IDE consent | `1.9.0` baseline; exact `1.10.0` candidate | `tests/scenarios/trust.py` and [trust scenario guide](trust-scenarios.md), executed by [isolated scenario CI](../.github/workflows/scenarios.yml) | macOS fixture lane; full historical revocation and runtime inspection require the pinned candidate | Demonstrated | Base + base-demo | Refresh exact candidate evidence before release; do not attribute candidate-only guarantees to v1.9.0. |
| Optional `test.requirements` | `1.10.0` candidate | The project selects `python.manager: uv` in [`base_manifest.yaml`](../base_manifest.yaml), with dependencies owned by [`pyproject.toml`](../pyproject.toml) and [`uv.lock`](../uv.lock); Base setup/check/doctor/test coverage already exercises that provider path | The baseline demo does not use a standalone requirements file; its Python environment remains uv-managed | Intentionally omitted | Base + base-demo | Keep this field out of the baseline manifest unless a non-uv test dependency contract is needed; reassess after Base v1.10.0 is published. |
| Base-managed uninstall guidance | `1.10.0` candidate | The supported preview and read-only verification commands are documented in [`README.md`](../README.md); CI does not execute destructive teardown against a developer workspace | Cleanup is local and review-gated; Base preserves the project checkout and manifest, while the full interactive path remains macOS | Intentionally omitted | Base + base-demo | Add an isolated `--verify` scenario before claiming teardown as demonstrated evidence. |
| Native Windows support | `1.11.0` (planned) | The current non-goal is recorded in [`README.md`](../README.md); the staged Base work is tracked by [base-demo#302](https://github.com/basefoundry/base-demo/issues/302) and Base [#2215](https://github.com/basefoundry/base/issues/2215) | Native Windows is not shipped; Git Bash and WSL2 do not count as native Windows evidence | Blocked upstream | Base + base-demo | Wait for the PowerShell-first Base contract and hosted Windows evidence. |
| First-class Base Docker-service contract | Future | The existing Compose fixture is documented in [`docs/tooling-testbed.md`](tooling-testbed.md) and [`infra/compose.yaml`](../infra/compose.yaml); adoption remains tracked by [base-demo#163](https://github.com/basefoundry/base-demo/issues/163) and Base [#124](https://github.com/basefoundry/base/issues/124) | Compose is a repository fixture; it does not establish a Base Docker-service contract | Blocked upstream | Base + base-demo | Do not make the future Base command a required demo dependency before Base publishes it. |

The matrix intentionally does not treat the advisory candidate lane as a stable
release or final BOM. Release publication and final evidence binding remain
separately tracked and must not be inferred from the capability statuses above.

## Release review checklist

Before a Base release or a base-demo capability change is declared aligned:

- confirm the current and planned Base release headings above are still true;
- check for stale rows whose evidence or follow-up no longer matches `main`;
- add or update a row when a user-facing command, platform boundary, or evidence
  path changes;
- keep every `Demonstrated` row linked to an executable repository check or
  hosted workflow step;
- explain every `Intentionally omitted` or `Blocked upstream` row and link the
  follow-up issue; and
- run `python3 tests/validate_capability_matrix.py` and the normal repository
  validation.

The structural check validates the table shape, status vocabulary, release
headings, local references, and links from the README, contracts registry, and
AI context. It deliberately does not compare prose or require a particular
wording for a row.
