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

From a machine where Base is already set up:

```bash
basectl projects list
basectl setup base-demo
basectl check base-demo
basectl doctor base-demo
basectl run base-demo hello
basectl test base-demo
```

## Repository Shape

- `base_manifest.yaml` declares the project name, activation source, command,
  test command, and Brewfile location using current Base contracts.
- `Brewfile` is the Homebrew-owned place for ordinary macOS tools.
- `.base/activate.sh` demonstrates project activation state.
- `src/hello.sh` is a tiny command target for `basectl run`.
- `tests/validate.sh` verifies that the repository baseline is intact.

The interactive `basectl demo base-demo` walkthrough lands in a follow-up change
after the Base demo command is available in a released Base version.
