# base-demo Manifest Contract

`base_manifest.yaml` is the project contract Base reads. Every field in
base-demo's manifest is intentional and maps to a visible Base workflow.

## Fields

| Field | Demonstrated by | Notes |
|---|---|---|
| `schema_version` | `basectl setup` | Manifest compatibility marker |
| `project.name` | `basectl projects list` | Stable name for all Base commands |
| `project.languages` | `basectl check` / `doctor` | Explicit normalized language taxonomy for the Python, Go, Java, C, C++, and JavaScript fixtures; metadata only, with no automatic toolchain provisioning |
| `brewfile` | `basectl setup` | Delegates ordinary macOS dependencies to `brew bundle`; currently includes mise, uv, Gradle, and Maven |
| `python.manager` | `basectl setup` / `check` / `doctor` | `uv` owns the project virtual environment; `pyproject.toml` and `uv.lock` are the dependency source of truth |
| `health.required_env` | `basectl check` / `doctor` | `BASE_DEMO_ENV=baseline` on the green path; missing before activation as a diagnostic example |
| `health.required_ports` | `basectl check` / `doctor` | Baseline `go-api` port 8010 is expected to be free before services are started |
| `mise` | `basectl setup` | Declares `.mise.toml`; setup installs Python 3.13 and Node 22.22.0 with bundled npm 10.9.4 via mise |
| `python.requires_python` | `basectl check` / `doctor` | Base validates Python 3.13 while uv enforces the matching project interpreter range |
| `activate.source` | `basectl activate` | Sources `.base/activate.sh` into the project shell |
| `ide.vscode` | `basectl setup` | Declares VS Code Python extensions and project venv auto-injection when IDE setup is enabled |
| `commands` | `basectl run --list` | Named commands: hello, env, manifest, python-info, uv-info, services, environments; `env` prints Base runtime metadata including `BASE_OS`, `BASE_PLATFORM`, `BASE_HOST_ENV`, and `BASE_HOST` |
| `commands[*].runner` | `basectl run base-demo uv-info` | Routes the uv-info command through `uv run --` alongside the project-wide uv manager |
| `build.targets` | `basectl build` | Default `info` target plus Go, Python, Java, C/C++, and demo-console service build targets |
| `build.targets[*].working_dir` | `basectl build base-demo go-api` | Runs the Go build from `services/go-api` without the command changing directories |
| `test.mise` | `basectl test` | Runs the mise `validate` task, which reconciles locked demo-console dependencies before `tests/validate.sh` |
| `demo.script` | `basectl demo` | Runs `demo/demo.sh` |
| `artifacts` | `basectl setup` | Requests the `bats-core` tool artifact; setup reports whether the Homebrew package is already current or would be installed |

## Design Intent

The current manifest keeps the baseline fast and inspectable. It uses shell
scripts, a small Python module, and explicit Base contracts so a fresh checkout
can prove setup, activation, run, build, test, and demo behavior quickly. The
`env` command makes the current Base runtime platform contract visible through
`BASE_OS`, `BASE_PLATFORM`, `BASE_HOST_ENV`, and `BASE_HOST`.

The representative environment is now part of the committed manifest surface.
The `services` command reads `services/catalog.json`, applies the same structural
and typed-field schema to canonical and custom catalogs before lifecycle work,
reports catalog health, and exercises dry-run startup
through `BASE_DEMO_SERVICES_DRY_RUN=1`. Process state and logs are private,
contained children of `BASE_DEMO_SERVICES_STATE_DIR` (or `var/services`).
Lifecycle starts fail closed, roll back invocation-owned resources after a
later failure, and never restart after process-ownership or safe-stop failure.
Compose-backed infrastructure lives in `infra/compose.yaml`.
Current multi-language service fixtures live under `services/`.
The React/Vite console provides the catalog UI. The `environments` command
validates URLs, logging, service overrides, infrastructure flags/ports, and
catalog/Compose references in the `dev`/`staging`/`prod` configuration model
while keeping only local `dev` operational by default. `BASE_DEMO_ENV=baseline`
is the manifest health marker set by activation and CI; `services --env dev` is
the separate default selector for representative service configuration.
