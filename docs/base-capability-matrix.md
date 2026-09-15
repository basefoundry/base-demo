# Base capability and evidence matrix

This matrix is the compact release-review view of what `base-demo` proves about
Base. It is intentionally curated: it records user-facing capability evidence
and known boundaries without copying Base's internal test suite or inventing
evidence that this repository does not execute.

Current Base release: `1.9.0`  
Planned Base release: `1.10.0`

The repository's CI still exercises the immutable Base `v1.8.0` compatibility
pin. That is recorded as a gap below until the compatibility train updates the
pin and adds the release-specific evidence. A moving local Base checkout is
useful for development, but does not by itself establish released compatibility.

## Capability matrix

| Capability | Base release | Demo scenario and executable evidence | Platform boundary | Status | Owner | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| Bootstrap, project discovery, and guided onboarding | `1.9.0` | Quick Start and onboarding commands in [`README.md`](../README.md); repository and demo assertions in [`tests/demo_test.bats`](../tests/demo_test.bats) and [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) | Full setup and interactive demo on macOS; Base setup and read-only project health on Ubuntu/Debian | Demonstrated | Base + base-demo | Keep the command sequence aligned with Base's onboarding contract. |
| Manifest command review, explicit trust, and command execution | `1.9.0` | The trust boundary is documented in [`docs/contracts.md`](contracts.md) and exercised by the review, trust, run, build, and test steps in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) | macOS full loop; Linux CI uses the read-only and dry-run portions | Demonstrated | Base + base-demo | Preserve review-before-trust ordering when commands change. |
| Workspace onboarding, agent handoff, and AI context | `1.9.0` | Workspace onboarding and agent-brief JSON are checked in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml); the project context is indexed by [`.ai-context/overview.md`](../.ai-context/overview.md) | Workspace paths must be inside the configured workspace; WSL2 follows the Linux boundary | Demonstrated | Base + base-demo | Add a row when a new handoff artifact becomes user-facing. |
| Representative build, test, service, environment, and non-interactive demo loop | `1.9.0` | The manifest targets in [`base_manifest.yaml`](../base_manifest.yaml), baseline gate in [`tests/validate.sh`](../tests/validate.sh), and focused suites in [`tests/services_test.bats`](../tests/services_test.bats), [`tests/environments_test.bats`](../tests/environments_test.bats), and [`tests/demo_test.bats`](../tests/demo_test.bats) | Full project loop is macOS; Ubuntu/Debian validates Base setup and project health only | Demonstrated | base-demo | Add executable evidence before calling a new service or command demonstrated. |
| Linux and WSL2 read-only support boundary | `1.9.0` | The supported commands and explicit native-Windows boundary are in [`README.md`](../README.md) and [`docs/contracts.md`](contracts.md); CI's Ubuntu path is in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) | Ubuntu/Debian and WSL2 use setup, dev-profile, check, and doctor/read-only paths; native Windows is excluded | Demonstrated | Base + base-demo | Keep platform claims tied to a hosted or repository-local check. |
| Base `1.9.0` released-compatibility pin and full Go/live-HTTP evidence | `1.9.0` | The current immutable compatibility evidence and its remaining gap are visible in [`.github/workflows/tests.yml`](../.github/workflows/tests.yml); the demo-side executable expansion is tracked by [base-demo#296](https://github.com/basefoundry/base-demo/issues/296) | Release-pinned CI must be refreshed before this row can claim Base `1.9.0` | Blocked upstream | Base + base-demo | Complete #296, then consume Base [#2290](https://github.com/basefoundry/base/issues/2290). |
| Workspace scenarios planned for the Base `1.10.0` train | `1.10.0` (planned) | The workspace manifest and current boundary are [`workspace.yaml.example`](../workspace.yaml.example) and [`README.md`](../README.md); the new scenario evidence is tracked by [base-demo#297](https://github.com/basefoundry/base-demo/issues/297) | Planned release work; no `1.10.0` claim is made by the current `main` branch | Blocked upstream | Base + base-demo | Implement #297 after the Base `1.10.0` workspace contract is fixed. |
| Trust and consent scenarios planned for the Base `1.10.0` train | `1.10.0` (planned) | Current trust documentation and CI ordering are in [`README.md`](../README.md), [`docs/contracts.md`](contracts.md), and [`.github/workflows/tests.yml`](../.github/workflows/tests.yml); the additional scenario is tracked by [base-demo#298](https://github.com/basefoundry/base-demo/issues/298) | Planned release work; current evidence remains the `1.9.0` boundary | Blocked upstream | Base + base-demo | Implement #298 after the Base trust/consent contract is stable. |
| Optional `test.requirements` and uninstall guidance | `1.9.0` | The manifest test entry and contributor setup guidance are [`base_manifest.yaml`](../base_manifest.yaml) and [`README.md`](../README.md) | Optional metadata is not required for the baseline demo contract | Intentionally omitted | base-demo | Revisit when Base publishes a stable user-facing contract and a concrete scenario. |
| Native Windows support | `1.11.0` (planned) | The current non-goal is recorded in [`README.md`](../README.md); the staged Base work is tracked by [base-demo#302](https://github.com/basefoundry/base-demo/issues/302) and Base [#2215](https://github.com/basefoundry/base/issues/2215) | Native Windows is not shipped; Git Bash and WSL2 do not count as native Windows evidence | Blocked upstream | Base + base-demo | Wait for the PowerShell-first Base contract and hosted Windows evidence. |
| First-class Base Docker-service contract | Future | The existing Compose fixture is documented in [`docs/tooling-testbed.md`](tooling-testbed.md) and [`infra/compose.yaml`](../infra/compose.yaml); adoption remains tracked by [base-demo#163](https://github.com/basefoundry/base-demo/issues/163) and Base [#124](https://github.com/basefoundry/base/issues/124) | Compose is a repository fixture; it does not establish a Base Docker-service contract | Blocked upstream | Base + base-demo | Do not make the future Base command a required demo dependency before Base publishes it. |

The matrix intentionally leaves release-process, BOM, and dependency alignment
implementation out of this train. Those lanes remain separately tracked and
must not be inferred from the capability statuses above.

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
