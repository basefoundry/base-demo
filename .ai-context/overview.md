# base-demo Overview

`base-demo` is the public reference project for Base-managed repositories.

It demonstrates the smallest useful Base project shape: a `base_manifest.yaml`
that declares every current Base contract, a set of runnable commands, a Python
CLI that uses `base_cli.App`, an interactive demo script, and a validation test.

## Purpose

- Show what a well-structured `base_manifest.yaml` looks like
- Demonstrate `basectl setup`, `check`, `doctor`, `run`, `test`, `build`, `activate`, and `demo`
- Provide a working end-to-end example that CI validates on every commit

## Key Files

| File | Role |
|---|---|
| `base_manifest.yaml` | Project contract Base reads |
| `.base/activate.sh` | Sets `BASE_DEMO_ENV=baseline` in the project shell |
| `src/hello.sh` | Simple `basectl run` target |
| `src/env.sh` | Shows Base project environment variables |
| `src/manifest.sh` | Prints manifest fields |
| `src/build-info.sh` | Build target: prints project and version |
| `bin/base-demo-python-info` | Bash launcher for the Python CLI |
| `lib/python/base_demo_cli/` | Python CLI using `base_cli.App` |
| `demo/demo.sh` | Interactive walkthrough |
| `tests/validate.sh` | Baseline validation (the declared test command) |

## Quick Loop

```bash
basectl setup base-demo
basectl check base-demo
basectl run base-demo hello
basectl build base-demo
basectl test base-demo
basectl activate base-demo
basectl demo base-demo
```
