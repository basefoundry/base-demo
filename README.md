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
hello

$ basectl run base-demo hello
hello from base-demo
BASE_PROJECT=base-demo
BASE_DEMO_ENV=baseline

$ basectl test base-demo
Repository baseline is present.
```

## Repository Shape

- `base_manifest.yaml` declares the project name, activation source, command,
  test command, and Brewfile location using current Base contracts.
- `Brewfile` is the Homebrew-owned place for ordinary macOS tools.
- `.base/activate.sh` demonstrates project activation state.
- `src/hello.sh` is a tiny command target for `basectl run`.
- `demo/demo.sh` is the interactive walkthrough.
- `tests/validate.sh` verifies that the repository baseline is intact.

For CI or scripted validation, run the walkthrough without prompts:

```bash
basectl demo base-demo -- --non-interactive
```
