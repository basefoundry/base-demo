# base-demo Overview

`base-demo` is the public reference project and representative environment for
Base-managed repositories.

It includes the Base project shape plus a reduced-scale representative
environment: a `base_manifest.yaml` that declares every current Base contract,
runnable commands, a Python CLI that uses `base_cli.App`, an interactive demo
script, validation tests, multiple language services, common build tools, one
Dockerized service, one React/Vite UI, local databases and cache through
Compose, and JSON-modeled `dev`, `staging`, and `prod` configuration. Only local
`dev` is operational by default; staging and prod are configuration examples.

This makes `base-demo` a bridge between a tiny sample and Banyan Labs. Base owns
workspace orchestration, `base-demo` proves the representative shape, and
Banyan Labs remains the full platform engineering lab.

## Purpose

- Show what a well-structured `base_manifest.yaml` looks like
- Demonstrate `basectl setup`, `check`, `doctor`, `run`, `test`, `build`, `activate`, and `demo`
- Provide a working end-to-end example that CI validates on every commit
- Build confidence for larger Banyan Labs work without duplicating Banyan Labs
  product or platform complexity

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
| `bin/base-demo-services` | Service lifecycle command backed by `services/catalog.json` |
| `bin/base-demo-environments` | Environment configuration inspection and validation command |
| `services/catalog.json` | Representative environment service catalog |
| `services/go-api/` | Tiny Go HTTP API and Dockerized service fixture |
| `services/python-api/` | Tiny standard-library Python HTTP API fixture |
| `services/java-gradle-api/` | Tiny Java HTTP API fixture built with Gradle |
| `services/java-maven-api/` | Tiny Java HTTP API fixture built with Maven |
| `services/c-service/` | Tiny native C fixture built with make |
| `services/cpp-service/` | Tiny native C++ fixture built with make |
| `services/demo-console/` | React/Vite operational console for the service catalog |
| `infra/compose.yaml` | Local Postgres, MySQL, Redis, and Go API Compose fixtures |
| `environments/*.json` | `dev`, `staging`, and `prod` environment configuration |
| `lib/python/base_demo_cli/` | Python CLI using `base_cli.App` |
| `demo/demo.sh` | Interactive walkthrough |
| `tests/validate.sh` | Baseline validation (the declared test command) |
| `docs/representative-environment.md` | Direction for the multi-language representative environment |

## Quick Loop

```bash
basectl setup base-demo
basectl activate base-demo
basectl check base-demo
basectl run base-demo hello
basectl build base-demo
basectl test base-demo
basectl demo base-demo
```

`BASE_DEMO_ENV=baseline` is the green-path health-check value. It is set by
`.base/activate.sh` in the activated project shell and by CI at the workflow
level. Running `check` or `doctor` before activation can intentionally report
the missing variable as a diagnostic example.
