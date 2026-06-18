# Changelog

All notable changes to base-demo will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions are tracked in the repo-root `VERSION` file.

## [Unreleased]

### Added

- Added `docs/representative-environment.md` to define the reduced-scale
  medium-company environment direction and issue train.
- Added the `services` manifest command backed by `services/catalog.json` for
  representative environment lifecycle status and checks.
- Added JSON-modeled `dev`, `staging`, and `prod` environment configuration
  with an `environments` inspection and validation command.
- Added `infra/compose.yaml` with representative Postgres, MySQL, and Redis
  dependencies managed through the `services` command.
- Added `services/go-api` as a tiny Go HTTP API and the representative
  Dockerized app service on port 8010.
- Added `services/python-api` as a tiny standard-library Python HTTP API on
  port 8020, including native process lifecycle wiring in the `services`
  command.
- Added Java Gradle and Maven HTTP API fixtures on ports 8030 and 8040, with
  Brewfile, service catalog, lifecycle, and build target wiring.
- Added native C and C++ service fixtures on ports 8050 and 8060 with
  Makefile-backed build scripts and command health checks.
- Added `services/demo-console`, a React/Vite operational UI on port 8070 for
  browsing the representative service catalog.
- Integrated the representative environment into the main `basectl demo`
  walkthrough with service checks, dry-run startup, environment validation, and
  expanded build-target discovery.
- Documented the MIT license decision in the README.
- Added repo-local agent guidance, a project skills index, and a reusable
  Base-backed installer script.
- Added `health.required_env: [BASE_DEMO_ENV]` to the manifest; `basectl check`
  now reports the variable missing until `basectl activate` is run.
- Added `.ai-context/` directory for `basectl export-context` with overview and
  manifest contract documentation.
- Added build section to the manifest with an `info` target backed by
  `src/build-info.sh`; demonstrated in the build-target demo step.
- Added `.mise.toml` declaring Python 3.13 and a `validate` task; wired into the
  manifest via `mise: .mise.toml` so `basectl setup` installs tool versions.
- Added `.github/pull_request_template.md` for consistent PR descriptions.

### Changed

- Clarified the `BASE_DEMO_ENV` health-check story across README, demo text,
  and AI context: activated shells and CI are the green path, while missing
  pre-activation state is an intentional diagnostic example.
- Rewrote `lib/python/base_demo_cli/__main__.py` to use the `base_cli.App`
  pattern (`@app.command()`, `base_cli.Context`) instead of raw Click.

### Fixed

- Fixed `src/manifest.sh` grep pattern to include `project:` and `  name:` so
  the project name section appears in `basectl run base-demo manifest` output.
- Fixed `demo/demo.sh` function definition order so `discovery_step` and
  `diagnostics_step` are defined before `activation_step` calls them.

### CI

- Pinned Base clone to `v0.4.4` tag to prevent master HEAD changes from
  breaking CI.
- Added `brew install bash` before `basectl setup` to satisfy the Bash 4.2+
  requirement on macOS GitHub Actions runners.
- Replaced feature-detection gate with unconditional Base-backed validation steps.
- Added `BASE_DEMO_ENV: baseline` to the CI job environment so `basectl check`
  passes without requiring an activated shell.
- Added `--manifest ./base_manifest.yaml` to `setup`, `check`, and `doctor`
  commands so they work without workspace configuration on CI runners.
- Added CI coverage for the representative service, environment,
  infrastructure, language fixture, UI, and dry-run startup contracts.

## [0.1.0] - 2026-06-12

### Added

- Initialized the repository with the Base-managed repo baseline.
- Added a Base manifest, Brewfile, activation source, example command, and
  baseline validation script.
- Added the interactive `basectl demo base-demo` walkthrough and BATS coverage.
- Expanded GitHub Actions validation for the demo script and Base-backed demo
  flow.
