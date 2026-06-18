# base-demo

Reference Base-managed project and representative demo environment.

This repository is the public reference project for Base-managed repositories.
It demonstrates Base on a compact but credible project shape: small enough to
inspect in one sitting, but substantial enough to represent the tools and
runtime variety found in a medium-sized engineering organization.

The long-term direction is documented in
[Representative Environment Design](docs/representative-environment.md).
`base-demo` is intentionally positioned between a toy sample and
[`banyanlabs`](https://github.com/codeforester/banyanlabs): it borrows the
shape of a realistic platform environment while keeping each service shallow so
Base orchestration remains the point.

## Quick Start

Clone `base` and `base-demo` as peer directories:

```bash
git clone https://github.com/codeforester/base.git
git clone https://github.com/codeforester/base-demo.git
```

From the `base-demo` repository root on a machine where Base is already set up:

```bash
basectl projects list
basectl setup base-demo
basectl check base-demo
basectl doctor base-demo
basectl repo check .
basectl run base-demo --list
basectl run base-demo hello
basectl test base-demo
basectl build base-demo
basectl activate base-demo
basectl demo base-demo
```

The commands above exercise the complete Base project loop:

- `basectl projects list` proves the repository is discoverable from the
  workspace.
- `basectl setup base-demo` reconciles the project manifest, Brewfile, and
  project virtual environment.
- `basectl check base-demo` and `basectl doctor base-demo` validate the local
  project environment.
- `basectl repo check .` validates the standard repository baseline files.
- `basectl run base-demo --list` shows the manifest-declared project commands.
- `basectl run base-demo hello` runs the `hello` command from the project root.
- `basectl test base-demo` runs the manifest-declared test command.
- `basectl build base-demo` runs the default build target (`info`) declared in the manifest.
- `basectl activate base-demo` starts a project shell with the activation
  source applied.
- `basectl demo base-demo` runs the project-owned walkthrough.

`basectl activate base-demo` spawns a new subshell, sources `.base/activate.sh`,
and updates the prompt to `[base-demo: <branch>] ~/path $`. Inside that shell,
`BASE_DEMO_ENV` is `baseline` (set by activate.sh). Run `exit` or press Ctrl-D
to return to the original shell. The environment changes disappear when the
subshell exits — no explicit deactivation is needed.

Expected command output includes:

```text
$ basectl run base-demo --list
Commands for project 'base-demo'

test                 ./tests/validate.sh
hello                ./src/hello.sh
env                  ./src/env.sh
manifest             ./src/manifest.sh
python-info          ./bin/base-demo-python-info

$ basectl run base-demo hello
hello from base-demo
BASE_PROJECT=base-demo
BASE_DEMO_ENV=unset

$ basectl test base-demo
Repository baseline is present.
```

`BASE_DEMO_ENV` becomes `baseline` inside `basectl activate base-demo`,
because activation sources `.base/activate.sh` into the project shell.

## Repository Shape

- `base_manifest.yaml` declares the project name, activation source, command,
  test command, and Brewfile location using current Base contracts.
- `Brewfile` is the Homebrew-owned place for ordinary macOS tools.
- `.base/activate.sh` demonstrates project activation state.
- `src/hello.sh`, `src/env.sh`, `src/manifest.sh`, and `src/build-info.sh` are
  tiny command and build targets for `basectl run` and `basectl build`.
- `lib/python/base_demo_cli` is a tiny Python command target that runs inside
  the Base-managed project environment.
- `bin/base-demo-python-info` is the Bash launcher that delegates the Python
  package to `base-wrapper`.
- `.mise.toml` declares tool versions (Python 3.13) managed by mise.
- `demo/demo.sh` is the interactive walkthrough.
- `tests/validate.sh` verifies that the repository baseline is intact.

## Manifest Contract Map

`base_manifest.yaml` is the project contract Base reads. In this repository,
each field maps to a visible Base workflow:

| Manifest field | Demonstrated by | Purpose |
| --- | --- | --- |
| `schema_version` | `basectl setup base-demo` | Declares the manifest contract version Base should parse. |
| `project.name` | `basectl projects list` | Gives Base the stable project name used by setup, check, doctor, run, test, activate, and demo. |
| `brewfile` | `basectl setup base-demo` | Delegates ordinary Homebrew dependencies to `brew bundle`. |
| `health.required_env` | `basectl check base-demo` | Declares env vars that must be set; reported missing until `basectl activate` sources `.base/activate.sh`. |
| `mise` | `basectl setup base-demo` | Points to `.mise.toml` so Base installs declared tool versions (Python 3.13) via mise. |
| `activate.source` | `basectl activate base-demo` | Sources project-owned shell state into the activated project shell. |
| `commands` | `basectl run base-demo --list` | Declares named project commands such as `hello`, `env`, `manifest`, and `python-info`. |
| `build.targets` | `basectl build base-demo` | Declares build targets; the `info` target runs `src/build-info.sh`. |
| `test.command` | `basectl test base-demo` | Defines the project-owned validation command. |
| `demo.script` | `basectl demo base-demo` | Defines the project-owned interactive walkthrough. |
| `artifacts` | `basectl setup base-demo` | Lists Base-managed artifacts. The baseline demo uses an empty list to avoid unnecessary installs. |

Today the demo intentionally starts from shell scripts, one standard-library
Python module, and a small Base manifest. The next implementation train expands
that baseline into a representative environment with multi-language service
fixtures, one Dockerized app service, a React/Vite UI, Compose-backed local
databases and cache, and a lightweight `dev`/`staging`/`prod` configuration
model. Those additions should stay shallow and readable; deeper product and
platform complexity belongs in Banyan Labs.

For CI or scripted validation, run the walkthrough without prompts:

```bash
basectl demo base-demo -- --non-interactive
```

## License

base-demo is licensed under the MIT License so it can be freely copied as a
small reference project for Base-managed workflows. See [LICENSE](LICENSE) for
the full terms.
