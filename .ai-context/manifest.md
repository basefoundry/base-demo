# base-demo Manifest Contract

`base_manifest.yaml` is the project contract Base reads. Every field in
base-demo's manifest is intentional and maps to a visible Base workflow.

## Fields

| Field | Demonstrated by | Notes |
|---|---|---|
| `schema_version` | `basectl setup` | Manifest compatibility marker |
| `project.name` | `basectl projects list` | Stable name for all Base commands |
| `brewfile` | `basectl setup` | Delegates ordinary macOS dependencies to `brew bundle`; currently includes mise, uv, Gradle, and Maven |
| `health.required_env` | `basectl check` / `doctor` | `BASE_DEMO_ENV=baseline` on the green path; missing before activation as a diagnostic example |
| `health.required_ports` | `basectl check` / `doctor` | Baseline `go-api` port 8010 is expected to be free before services are started |
| `mise` | `basectl setup` | Declares `.mise.toml`; setup installs tool versions (Python 3.13) via mise |
| `python.requires_python` | `basectl check` / `doctor` | Base validates Python 3.13 separately from mise installing it |
| `activate.source` | `basectl activate` | Sources `.base/activate.sh` into the project shell |
| `commands` | `basectl run --list` | Named commands: hello, env, manifest, python-info, uv-info, services, environments |
| `commands[*].runner` | `basectl run base-demo uv-info` | Routes only the uv-info command through `uv run --` |
| `build.targets` | `basectl build` | `info` target runs `src/build-info.sh` |
| `build.targets[*].working_dir` | `basectl build base-demo go-api` | Runs the Go build from `services/go-api` without the command changing directories |
| `test.command` | `basectl test` | Runs `tests/validate.sh` |
| `demo.script` | `basectl demo` | Runs `demo/demo.sh` |
| `artifacts` | `basectl setup` | Requests the `bats-core` tool artifact; setup reports whether the Homebrew package is already current or would be installed |

## Design Intent

The current manifest keeps the baseline fast and inspectable. It uses shell
scripts, a small Python module, and explicit Base contracts so a fresh checkout
can prove setup, activation, run, build, test, and demo behavior quickly.

The representative environment direction will add service, infrastructure, UI,
and environment-modeling commands in focused slices while preserving this
readable manifest contract.
