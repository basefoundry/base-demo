# Tooling Test Bed

`base-demo` is the reference project for Base-managed repositories and the
place where Base proves how it coexists with common local development tools.
This document defines the adapter boundary for that test bed.

Base remains the operator-facing entry point. External tools can be represented
in this repository when they teach a real adoption path, but they should not
become hidden requirements for the baseline demo unless Base itself owns that
contract.

## Boundary Rules

- Baseline tools are allowed in root-level active configuration when they are
  already part of the supported Base path and are validated by CI.
- Optional live tools may add convenience wrappers or generated artifacts, but
  they must delegate back to `basectl` and remain optional for the default
  validation loop.
- Reference-only tools live under examples or docs until there is a deliberate
  decision to make them active. Do not add root-level files that can change a
  developer shell, home directory, checkout graph, or package manager behavior
  without a separate issue.
- External tool configuration remains authoritative to the external tool. Base
  can check, report, generate, or invoke it; Base should not silently import or
  synchronize that state.
- The macOS full-demo path and the Ubuntu/Debian/WSL2 read-only health path are
  the current platform boundary. Native Windows and future Docker service
  support should stay explicitly scoped until Base publishes the contract.

## Adapter Matrix

| Layer | Tools | Current base-demo stance | Next action |
| --- | --- | --- | --- |
| Baseline | Brewfile, mise, uv, Docker Compose, VS Code manifest fields | Active. `Brewfile`, `.mise.toml`, command-level `runner: uv`, `infra/compose.yaml`, and `base_manifest.yaml` are part of the committed demo contract. | Keep validated through `tests/validate.sh`, BATS suites, and Base-backed CI. |
| Base-generated environment views | `basectl devcontainer`, `basectl devenv-report`, Nix/devenv policy | CI-visible read-only reports. Base previews Dev Containers metadata and classifies Nix/devenv mappings without writing generated files or requiring Docker, Nix, or devenv. | Keep the reports in JSON-mode CI and avoid committing `.devcontainer/` or generated Nix/devenv files by default. |
| Optional live task wrappers | just, Taskfile | Active but optional. `justfile` and `Taskfile.yml` expose ergonomic aliases for check, CI check, test, build, demo, and service status while delegating to `basectl`. | Keep wrappers thin and validation-only; do not make `just` or Task required for baseline CI. |
| Reference-only shell and dotfile tools | direnv, asdf, chezmoi, dotbot | Present under `examples/tooling/env-dotfiles/` only. No root `.envrc`, `.tool-versions`, chezmoi source tree, or dotbot installer is active by default. | Keep examples inactive until a separate issue promotes a tool into the baseline. |
| Reference-only multi-repo managers | mani, gita, vcs2l, west | Present under `examples/tooling/multi-repo/` only. Base's current workspace view remains `workspace.yaml.example`; these managers illustrate coexistence without owning checkout synchronization. | Keep examples read-only unless Base gains an explicit adapter contract. |
| Future Docker service | `basectl docker-service` | Blocked upstream. `base-demo` already has Compose-backed services, but it should not invent a Base docker-service contract before Base lands it. | Issue #163 remains blocked on basefoundry/base#124. |

## PR Train

| Order | Issue | Purpose | Expected PR shape |
| --- | --- | --- | --- |
| 1 | #178 | Define the tooling adapter matrix. | Docs, contract registry, AI context, and validation guards. |
| 2 | #182 | Demonstrate Base-generated environment reports. | Run `devcontainer` and `devenv-report` as dry-run JSON checks in CI. |
| 3 | #180 | Add optional task-runner aliases. | Add `just` and Taskfile wrappers that delegate to `basectl` and are not required for baseline CI. |
| 4 | #179 | Add reference env and dotfile examples. | Add inactive examples for `direnv`, `asdf`, `chezmoi`, and `dotbot` with docs that explain trust and activation boundaries. |
| 5 | #181 | Add read-only multi-repo manager examples. | Add inactive examples for `mani`, `gita`, `vcs2l`, and `west` aligned to `workspace.yaml.example`. |
| Hold | #163 | Adopt future Base Docker service support. | Wait for basefoundry/base#124, then wire the contract through service docs and validation. |

## Acceptance Policy

A new tool graduates into the baseline only when all of these are true:

- Base has a documented contract for the behavior.
- `base-demo` can demonstrate it without requiring privileged local state or a
  long-running service by default.
- README, AI context, and `docs/contracts.md` describe the same boundary.
- `tests/validate.sh` or a focused test fails when the contract drifts.

Until then, the tool belongs in optional wrappers, generated artifacts, or
reference-only examples.

## Base-Generated Environment Reports

`basectl devcontainer base-demo --format json` is a dry-run preview by default.
It reports the `.devcontainer/devcontainer.json` target path and the manifest
fields Base can safely translate, such as VS Code extensions and settings. It
also reports unsupported or ambiguous fields instead of inventing a container
policy for Brewfile, mise, artifacts, health checks, commands, activation, test,
or build targets.

`basectl devenv-report base-demo --format json` is read-only. It classifies
manifest fields for Nix/devenv adoption as supported, unsupported, lossy, or
project-owned, then leaves generation decisions to a future explicit policy.

Both commands are exercised in CI with `--workspace ..` and JSON assertions.
They are compatibility evidence, not a requirement that Docker, VS Code, Nix, or
devenv be installed for the baseline demo.

## Optional Task-Runner Wrappers

`justfile` and `Taskfile.yml` are optional live wrappers for developers who
already use `just` or Task. They intentionally expose only thin aliases:
`check`, `ci-check`, `test`, `build`, `demo`, and `services`.

Every wrapper command delegates to `basectl`. The files do not introduce a
second task contract, and baseline validation checks their contents without
requiring either task runner to be installed.

## Reference Shell And Dotfile Examples

`examples/tooling/env-dotfiles/` contains inactive examples for `direnv`,
`asdf`, `chezmoi`, and `dotbot`.

These files can help adopters map their existing shell and dotfile habits onto
Base, but they are not part of setup or CI. Keep root `.envrc`, `.tool-versions`,
chezmoi source trees, and dotbot installer files out of the repository unless a
future issue intentionally promotes one of those tools into the active
baseline.

## Reference Multi-Repo Examples

`examples/tooling/multi-repo/` contains read-only examples for `mani`, `gita`,
`vcs2l`, and `west`.

Those tools can materialize or inspect repository sets before Base discovers
opted-in projects. Base does not import or synchronize these formats today, and
`workspace.yaml.example` remains the Base-owned expected-set example.
