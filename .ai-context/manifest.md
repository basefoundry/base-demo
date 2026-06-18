# base-demo Manifest Contract

`base_manifest.yaml` is the project contract Base reads. Every field in
base-demo's manifest is intentional and maps to a visible Base workflow.

## Fields

| Field | Demonstrated by | Notes |
|---|---|---|
| `schema_version` | `basectl setup` | Manifest compatibility marker |
| `project.name` | `basectl projects list` | Stable name for all Base commands |
| `brewfile` | `basectl setup` | Delegates ordinary macOS dependencies to `brew bundle`; currently includes `mise` |
| `health.required_env` | `basectl check` / `doctor` | `BASE_DEMO_ENV` missing until `activate` |
| `mise` | `basectl setup` | Declares `.mise.toml`; setup installs tool versions (Python 3.13) via mise |
| `activate.source` | `basectl activate` | Sources `.base/activate.sh` into the project shell |
| `commands` | `basectl run --list` | Named commands: hello, env, manifest, python-info |
| `build.targets` | `basectl build` | `info` target runs `src/build-info.sh` |
| `test.command` | `basectl test` | Runs `tests/validate.sh` |
| `demo.script` | `basectl demo` | Runs `demo/demo.sh` |
| `artifacts` | `basectl setup` | Empty — no external Python packages needed |

## Design Intent

The current manifest keeps the baseline fast and inspectable. It uses shell
scripts, a small Python module, and explicit Base contracts so a fresh checkout
can prove setup, activation, run, build, test, and demo behavior quickly.

The representative environment direction will add service, infrastructure, UI,
and environment-modeling commands in focused slices while preserving this
readable manifest contract.
