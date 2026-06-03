# base-demo

Reference Base-managed project and interactive demo.

This repository is the public reference project for Base-managed repositories.
It starts with a small, inspectable baseline before the interactive walkthrough
is layered in.

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
- `basectl activate base-demo` starts a project shell with the activation
  source applied.
- `basectl demo base-demo` runs the project-owned walkthrough.

Expected command output includes:

```text
$ basectl run base-demo --list
Commands for project 'base-demo'

test                 ./tests/validate.sh
hello                ./src/hello.sh
env                  ./src/env.sh
manifest             ./src/manifest.sh
python-info          PYTHONPATH=lib/python python -m base_demo_cli

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
- `src/hello.sh`, `src/env.sh`, and `src/manifest.sh` are tiny command targets
  for `basectl run`.
- `lib/python/base_demo_cli` is a tiny Python command target that runs inside
  the Base-managed project environment.
- `demo/demo.sh` is the interactive walkthrough.
- `tests/validate.sh` verifies that the repository baseline is intact.

## Manifest Contract Map

`base_manifest.yaml` is the project contract Base reads. In this repository,
each field maps to a visible Base workflow:

| Manifest field | Demonstrated by | Purpose |
| --- | --- | --- |
| `schema_version` | `basectl setup base-demo` | Declares the manifest contract version Base should parse. |
| `project.name` | `basectl projects list` | Gives Base the stable project name used by setup, check, doctor, run, test, activate, and demo. |
| `brewfile` | `basectl setup base-demo` | Delegates ordinary Homebrew dependencies to `brew bundle`. This demo keeps the Brewfile empty on purpose. |
| `activate.source` | `basectl activate base-demo` | Sources project-owned shell state into the activated project shell. |
| `commands` | `basectl run base-demo --list` | Declares named project commands such as `hello`, `env`, `manifest`, and `python-info`. |
| `test.command` | `basectl test base-demo` | Defines the project-owned validation command. |
| `demo.script` | `basectl demo base-demo` | Defines the project-owned interactive walkthrough. |
| `artifacts` | `basectl setup base-demo` | Lists Base-managed artifacts. The baseline demo uses an empty list to avoid unnecessary installs. |

The demo intentionally uses shell scripts, one standard-library Python module,
and no external runtime dependencies.
More specialized examples, such as Python, Go, Docker, or service demos, should
stay small or move into separate demo repositories when they need their own
setup story.

For CI or scripted validation, run the walkthrough without prompts:

```bash
basectl demo base-demo -- --non-interactive
```
