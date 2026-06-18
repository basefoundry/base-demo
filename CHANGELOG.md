# Changelog

All notable changes to base-demo will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions are tracked in the repo-root `VERSION` file.

## [Unreleased]

### Added

- Added `docs/representative-environment.md` to define the reduced-scale
  medium-company environment direction and issue train.
- Documented the MIT license decision in the README.
- Added repo-local agent guidance, a project skills index, and a reusable
  Base-backed installer script.
- Added `health.required_env: [BASE_DEMO_ENV]` to the manifest; `basectl check`
  now reports the variable missing until `basectl activate` is run.
- Added `.ai-context/` directory for `basectl export-context` with overview and
  manifest contract documentation.
- Added build section to the manifest with an `info` target backed by
  `src/build-info.sh`; demonstrated in demo step 10.
- Added `.mise.toml` declaring Python 3.13 and a `validate` task; wired into the
  manifest via `mise: .mise.toml` so `basectl setup` installs tool versions.
- Added `.github/pull_request_template.md` for consistent PR descriptions.

### Changed

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

## [0.1.0] - 2026-06-12

### Added

- Initialized the repository with the Base-managed repo baseline.
- Added a Base manifest, Brewfile, activation source, example command, and
  baseline validation script.
- Added the interactive `basectl demo base-demo` walkthrough and BATS coverage.
- Expanded GitHub Actions validation for the demo script and Base-backed demo
  flow.
