# base-demo

Reference Base-managed project and representative demo environment.

This repository is the public reference project for Base-managed repositories.
It demonstrates Base on a compact but credible project shape: small enough to
inspect in one sitting, but substantial enough to represent the tools and
runtime variety found in a medium-sized engineering organization.

The long-term direction is documented in
[Representative Environment Design](docs/representative-environment.md).
`base-demo` is intentionally positioned between a toy sample and
[`banyanlabs`](https://github.com/basefoundry/banyanlabs): it borrows the
shape of a realistic platform environment while keeping each service shallow so
Base orchestration remains the point.

Binding promises between the manifest, demo, services, installer, CI, and docs
are tracked in [Contracts](docs/contracts.md). Update that registry whenever a
new invariant becomes part of the reference project.

The external tooling direction is tracked in
[Tooling Test Bed](docs/tooling-testbed.md). That matrix separates active
baseline tools from optional wrappers, reference-only examples, and future Base
contracts so `base-demo` can test adoption paths without hiding new
requirements in the default demo.

## Platform Requirements

macOS is the supported platform for the full interactive demo: setup,
activation, human-readable check/doctor output, build/test orchestration, and
the project-owned walkthrough.

Ubuntu/Debian CI validates Base runtime setup through
`basectl setup base --yes --no-notify`, dev-profile prerequisites through
`basectl setup base --profile dev --yes --no-notify`, and the base-demo
read-only project health check through
`basectl check --ci base-demo --format json`. That proves Base can bootstrap on
Ubuntu/Debian and install apt-backed dev tools (`bats`, `gh`, and `shellcheck`)
without Homebrew. It does not make the full base-demo project setup,
activation, build, test, or demo loop a Linux contract; those remain macOS
paths in this repository.

Ubuntu/Debian under WSL2 follows the same Base Linux contract when the `base`
and `base-demo` checkouts live inside the WSL filesystem, for example under
`~/work`, not under `/mnt/c/...`. A WSL2 smoke check should run
`basectl setup base --yes --no-notify`,
`basectl setup base --profile dev --yes --no-notify`,
`BASE_DEMO_ENV=baseline basectl check --ci base-demo --format json`, and
`BASE_DEMO_ENV=baseline basectl doctor --ci base-demo --format json`; keep full
base-demo setup, activation, build, test, and demo expectations out of scope.
Base should report `BASE_PLATFORM=linux-debian` with `BASE_HOST_ENV=wsl2`.
Native Windows support remains out of scope.

For the full Base platform policy, see
[`docs/linux-support.md`](https://github.com/basefoundry/base/blob/main/docs/linux-support.md)
in the Base repository.

## Quick Start

Clone `base` and `base-demo` as peer directories:

```bash
git clone https://github.com/basefoundry/base.git
git clone https://github.com/basefoundry/base-demo.git
```

For a first Base setup, `basectl onboard base-demo` is the recommended guided path.
It wraps the setup, profile, doctor, and project-discovery flow for new Base
users. Run `basectl onboard base-demo --dry-run` to preview the steps without
changing local state.

CI executes `basectl onboard base-demo --dry-run` and asserts the preview reaches
the Check, Setup, Projects, and Trust stages. Until
[`base#1887`](https://github.com/basefoundry/base/issues/1887) is fixed, a real
non-dry-run onboarding attempt can stop early when `basectl doctor` reports a
finding; if that happens, continue with the explicit commands below.

From the `base-demo` repository root on a machine where Base is already set up:

```bash
basectl projects list
basectl setup base-demo  # macOS only
basectl activate base-demo  # macOS only
basectl check base-demo  # macOS interactive path
basectl doctor base-demo  # macOS interactive path
basectl check --ci base-demo --format json  # Ubuntu/Debian read-only project health
basectl repo check .
basectl repo init base-demo --path . --agent-ready --no-configure --dry-run
basectl repo check . --agent-ready
basectl workspace status --manifest workspace.yaml.example
basectl workspace onboarding --manifest workspace.yaml.example
basectl workspace agent-brief --manifest workspace.yaml.example
basectl devcontainer base-demo --format json
basectl devenv-report base-demo --format json
basectl trust status base-demo
basectl run base-demo --list
basectl build base-demo --list
basectl test base-demo --dry-run
basectl trust allow base-demo
basectl run base-demo hello
basectl run base-demo env
basectl run base-demo python-info -- info
basectl run base-demo python-info -- env
basectl run base-demo services -- status
basectl run base-demo environments -- list
basectl test base-demo
basectl logs --limit 3
basectl history --project base-demo --limit 5
basectl history --project base-demo --limit 5 --report
basectl build base-demo
basectl demo base-demo  # macOS only
basectl docs --show-url
basectl export-context base-demo --format markdown --print
```

If `just` or Task are already installed, optional wrappers are available:

```bash
just check
just ci-check
task check
task ci-check
```

Those wrappers delegate to `basectl`; installing `just` or Task is not required
for setup, validation, CI, or the baseline demo.

## Python CLI Provider Policy

`base-demo` declares `base-cli==0.4.2` in `pyproject.toml` and `uv.lock`. That
released package is the default provider for the project-owned uv environment,
local `uv sync --locked`, and the normal wheel-based CI path. Keeping the
published dependency locked makes the reference project reproducible for new
users.

Base launchers have a separate provider-resolution contract for commands that
run through `base-wrapper`:

1. an explicit `BASE_CLI_SOURCE_DIR` source root;
2. a `base-cli` checkout next to the Base checkout at
   `$BASE_HOME/../base-cli/lib/python`;
3. the installed `base-cli` distribution in the selected environment.

The peer checkout is therefore an opt-in development and compatibility path
for `base-demo`; `base-demo` does not silently replace its locked uv
dependency when a nearby repository happens to exist. With the recommended
peer layout (`base`, `base-cli`, and `base-demo` under one workspace), run the
source-provider check explicitly from the `base-demo` checkout:

```bash
BASE_CLI_SOURCE_DIR="$PWD/../base-cli/lib/python" \
  ../base/bin/basectl run base-demo --workspace .. python-info -- env
```

The output should include `BASE_CLI_SOURCE=explicit`. The compatibility CI job
performs this check against the released `base-cli` source tag while the main
validation jobs continue to exercise the locked wheel path.

## Contribution Workflow Helpers

base-demo uses an issue-first, worktree-per-PR workflow. Base's GitHub helpers
make that workflow inspectable when the GitHub CLI is authenticated:

```text
basectl gh issue readiness <issue-number> --repo basefoundry/base-demo --project-owner basefoundry --project-number 9 --format json
basectl gh branch stale --days 14 --format json
```

`basectl gh issue readiness` checks whether an issue has the sections and
Project metadata expected before agentic implementation work. `basectl gh
branch stale` reports old local and origin branches from the current checkout so
cleanup can be reviewed deliberately. These commands are contributor workflow
helpers, not setup requirements or CI gates.

The commands above exercise the complete Base project loop:

- `basectl projects list` proves the repository is discoverable from the
  workspace.
- `basectl setup base-demo` reconciles the project manifest, Brewfile, and
  project virtual environment on macOS.
- `basectl activate base-demo` starts a macOS project shell with the activation
  source applied.
- `basectl check base-demo` and `basectl doctor base-demo` validate the local
  project environment from that activated macOS shell.
- `basectl check --ci base-demo --format json` returns machine-readable project
  health for read-only CI pipelines, including the Ubuntu/Debian project health
  check that runs after Base setup and the Base dev-profile setup.
- `basectl repo check .` validates the standard repository baseline files.
- `basectl repo init base-demo --path . --agent-ready --no-configure --dry-run`
  previews the Base generator for repo-local agent guidance without changing
  files or GitHub settings.
- `basectl repo check . --agent-ready` verifies the standard baseline plus the
  repo-local `AGENTS.md`, `skills.md`, and AI-context guidance contract.
- `basectl workspace status --manifest workspace.yaml.example` shows a
  workspace-level view of the expected `base`, `base-demo`, optional
  `base-platform-tools`, and optional `base-bash-libs` peer repositories.
- `basectl workspace onboarding --manifest workspace.yaml.example` summarizes
  first-day readiness, setup, validation, test, and clone guidance for the
  peer-checkout workspace.
- `basectl workspace agent-brief --manifest workspace.yaml.example` reports
  agent handoff readiness for expected peer repositories and nearby local Base
  projects.
- `basectl devcontainer base-demo --format json` previews the Dev Containers
  metadata Base can derive from the manifest without writing `.devcontainer/`.
- `basectl devenv-report base-demo --format json` reports how the manifest maps
  to Nix/devenv-style environment concepts without requiring Nix or devenv.
- `basectl trust status base-demo` shows whether the current manifest is already
  approved for project-owned command execution on this machine.
- `basectl run base-demo --list`, `basectl build base-demo --list`, and
  `basectl test base-demo --dry-run` are safe inspection commands before trust is
  granted.
- `basectl trust allow base-demo` records local approval for the reviewed
  manifest so Base can execute `run`, `test`, `build`, `demo`, and `activate`
  commands declared by this repository. Re-run the review and approval step
  after changing `base_manifest.yaml`.
- `basectl run base-demo hello` runs the `hello` command from the project root.
- `basectl run base-demo env` shows Base runtime metadata such as `BASE_OS`,
  `BASE_PLATFORM`, `BASE_HOST_ENV`, and `BASE_HOST` alongside project
  activation values.
- `basectl run base-demo python-info -- info` shows Base context values from
  `base_cli.Context`.
- `basectl run base-demo python-info -- env` shows the documented public
  `BASE_*` diagnostics visible to the Python command. Secret-looking names are
  retained with a `[REDACTED]` value, and other undeclared `BASE_*` variables
  are omitted rather than turning the command into a general environment dump.
- `basectl run base-demo services -- status` shows the representative service
  catalog and current health state.
- `basectl run base-demo environments -- list` shows the modeled
  `dev`/`staging`/`prod` configuration set.
- `basectl test base-demo` runs the manifest-declared test command.
- `basectl logs --limit 3`, `basectl history --project base-demo --limit 5`,
  and `basectl history --project base-demo --limit 5 --report` show the local
  audit trail and privacy-conscious activity report for recent Base activity.
- `basectl build base-demo` runs the default build target (`info`) declared in the manifest.
- `basectl demo base-demo` runs the macOS project-owned walkthrough.
- `basectl docs --show-url` prints the Base documentation home page URL without opening a browser.
- `basectl export-context base-demo --format markdown --print` prints the
  repository AI context bundle for assistant handoff.

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
uv-info              uv run -- python src/uv-info.py
services             ./bin/base-demo-services
environments         ./bin/base-demo-environments

$ basectl run base-demo hello
hello from base-demo
BASE_PROJECT=base-demo
BASE_DEMO_ENV=baseline

$ basectl run base-demo env
BASE_PROJECT=base-demo
BASE_PROJECT_ROOT=/path/to/base-demo
BASE_PROJECT_MANIFEST=/path/to/base-demo/base_manifest.yaml
BASE_PROJECT_VENV_DIR=/path/to/base-demo/.venv
BASE_OS=macos
BASE_PLATFORM=macos
BASE_HOST_ENV=native
BASE_HOST=dev-host
BASE_DEMO_ENV=baseline
BASE_DEMO_ACTIVATED=true
BASE_DEMO_PROJECT_KIND=reference-demo

$ basectl run base-demo python-info -- info
base-demo python cli
project_name=base-demo
project_root=/path/to/base-demo
workspace_root=/path/to/work

$ basectl run base-demo python-info -- env
BASE_PROJECT=base-demo
BASE_DEMO_ENV=baseline

$ basectl test base-demo
Repository baseline is present.
```

The Python `env` subcommand exposes the same project and runtime diagnostics as
the shell `env` command. If a secret-bearing name such as
`BASE_PROJECT_TOKEN` is present, its value is printed as `[REDACTED]`; arbitrary
non-public `BASE_*` values are not printed. The walkthrough applies the same
redaction before displaying captured environment output.

## BASE_DEMO_ENV Health Check

Normal green path: run `basectl check base-demo` and
`basectl doctor base-demo` from the activated project shell, where
`BASE_DEMO_ENV=baseline` has been set by `.base/activate.sh`.

Pre-activation diagnostic: if `BASE_DEMO_ENV` is missing, `check` and `doctor`
can report that finding intentionally. That output teaches how
`health.required_env` works; it does not mean the repository is corrupt.
Activate the project shell, or export `BASE_DEMO_ENV=baseline`, before using
`check` and `doctor` as green-path validation commands.

CI sets BASE_DEMO_ENV=baseline at the workflow level so automated validation is
deterministic without needing an interactive activated shell.

## Repository Shape

- `base_manifest.yaml` declares the project name, the repository's explicit
  language taxonomy, activation source, command, test command, and Brewfile
  location using current Base contracts.
- `pyproject.toml` and `uv.lock` declare the dependency-manager-owned Python
  project environment. Its declared runtime dependencies are `base-cli==0.4.2`,
  Click, and PyYAML, which the Base-backed Python CLI requires; uv owns the
  environment while Base's Python runtime remains the command wrapper.
  If an older Base-managed environment exists at `~/.base.d/base-demo/.venv`,
  Base reports it as stale and ignores it; remove it manually after confirming
  the repo-local `.venv` is healthy.
- `Brewfile` is the Homebrew-owned place for ordinary macOS tools. The
  Brewfile currently installs mise, uv, Gradle, and Maven so setup can
  demonstrate host tool-version management, the uv-managed project
  environment, command runners, and representative Java build tools.
- `.base/activate.sh` demonstrates project activation state.
- `src/hello.sh`, `src/env.sh`, `src/manifest.sh`, and `src/build-info.sh` are
  tiny command and build targets for `basectl run` and `basectl build`;
  `src/env.sh` also exposes Base runtime metadata such as `BASE_OS`,
  `BASE_PLATFORM`, `BASE_HOST_ENV`, and `BASE_HOST`.
- `lib/python/base_demo_cli` is a tiny Python command target that runs inside
  the Base-managed project environment.
- `bin/base-demo-python-info` is the Bash launcher that delegates the Python
  package to `base-wrapper`.
- `src/uv-info.py` is a tiny Python command routed through `runner: uv`; the
  project environment itself is owned by the manifest's `python.manager: uv`.
- `services/go-api` is a tiny Go HTTP API with `/healthz`, `/hello`, and
  `/info` endpoints. It is also the representative Dockerized app service.
- `services/python-api` is a tiny standard-library Python HTTP API with the
  same health, hello, and info surface on port 8020.
- `services/java-gradle-api` and `services/java-maven-api` are tiny Java HTTP
  APIs that keep Gradle and Maven visible as representative build tools.
- `services/c-service` and `services/cpp-service` are tiny native compiled
  process fixtures with Makefile-backed builds. They intentionally claim no
  network port; lifecycle health requires a matching live process-state record.
- `services/demo-console` is a small React/Vite operational console that reads
  the service catalog and shows the representative stack. Its build is a real
  production compilation gate: use Node 22.22.0 with npm 10.9.4, run `npm ci`
  in `services/demo-console`, and then run `npm run build` plus `npm run audit`.
  The audit gate fails at moderate severity or higher, and a successful build
  must create `dist/index.html` plus a JavaScript asset.
- `bin/base-demo-services` reads `services/catalog.json` and provides the
  `services` lifecycle command for the representative environment.
- `bin/base-demo-environments` lists, shows, and validates environment
  configuration.
- `services/catalog.json` is the initial catalog for representative services,
  infrastructure, and lifecycle checks.
- `infra/compose.yaml` defines local Postgres, MySQL, Redis, and the
  Dockerized Go API for the representative dev environment.
- `environments/dev.json`, `environments/staging.json`, and
  `environments/prod.json` model environment-specific configuration. Only
  `dev` is operational by default.
- `.mise.toml` declares the host tool versions (Python 3.13) managed by mise;
  uv uses that supported Python range for the project virtual environment.
- `justfile` and `Taskfile.yml` provide optional task-runner wrappers that
  delegate to Base commands without replacing the `basectl` contract.
- `examples/tooling/env-dotfiles/` contains reference-only direnv, asdf,
  chezmoi, and dotbot examples that are not active in the default checkout.
- `examples/tooling/multi-repo/` contains read-only mani, gita, vcs2l, and west
  examples aligned to `workspace.yaml.example`.
- `docs/tooling-testbed.md` defines how base-demo represents tools such as
  direnv, asdf, chezmoi, dotbot, just, Taskfile, mani, gita, vcs2l, west,
  devcontainers, Nix/devenv, and future Docker service support.
- `demo/demo.sh` is the interactive walkthrough.
- `tests/validate.sh` verifies that the repository baseline is intact.

## Manifest Contract Map

`base_manifest.yaml` is the project contract Base reads. In this repository,
each field maps to a visible Base workflow:

| Manifest field | Demonstrated by | Purpose |
| --- | --- | --- |
| `schema_version` | `basectl setup base-demo` | Declares the manifest contract version Base should parse. |
| `project.name` | `basectl projects list` | Gives Base the stable project name used by setup, check, doctor, run, test, activate, and demo. |
| `project.languages` | `basectl check base-demo` | Records the normalized Python, Go, Java, C, C++, and JavaScript profile represented by the service fixtures; this is taxonomy only and does not provision toolchains. |
| `brewfile` | `basectl setup base-demo` | Delegates ordinary Homebrew dependencies to `brew bundle`; currently installs mise, uv, Gradle, and Maven. |
| `python.manager` | `basectl setup`, `basectl check`, and `basectl doctor` | Delegates the project virtual environment to uv; `pyproject.toml` and `uv.lock` are the dependency source of truth. |
| `health.required_env` | `basectl check base-demo` | Declares env vars that must be set; green in an activated shell and intentionally reported missing as a pre-activation diagnostic. |
| `health.required_ports` | `basectl check base-demo` | Declares that the baseline `go-api` port 8010 should be free before services are started. |
| `mise` | `basectl setup base-demo` | Points to `.mise.toml` so Base installs declared tool versions (Python 3.13) via mise. |
| `python.requires_python` | `basectl check base-demo` | Lets Base verify Python 3.13 while uv enforces the matching project interpreter range. |
| `activate.source` | `basectl activate base-demo` | Sources project-owned shell state into the activated project shell. |
| `ide.vscode` | `basectl setup base-demo` | Declares VS Code Python extensions and auto-injects the project venv as `python.defaultInterpreterPath` when IDE setup is enabled. |
| `commands` | `basectl run base-demo --list` | Declares named project commands such as `hello`, `env`, `manifest`, `python-info`, `uv-info`, `services`, and `environments`. |
| `commands[*].runner` | `basectl run base-demo uv-info` | Keeps command-level `uv run --` selection visible alongside the project-wide uv environment manager. |
| `build.targets` | `basectl build base-demo` | Declares build targets; the `info` target runs `src/build-info.sh`. |
| `build.targets[*].working_dir` | `basectl build base-demo go-api` | Runs the Go build from `services/go-api` without the target command needing to change directories itself. |
| `test.command` | `basectl test base-demo` | Defines the project-owned validation command. |
| `demo.script` | `basectl demo base-demo` | Defines the project-owned interactive walkthrough. |
| `artifacts` | `basectl setup base-demo` | Requests the `bats-core` tool artifact; the project setup layer reports whether Homebrew already has it or would install it. |

The demo now includes a shallow but representative environment: multi-language
service fixtures, one Dockerized app service, a React/Vite UI, Compose-backed
local databases and cache, and a lightweight `dev`/`staging`/`prod`
configuration model. The services stay intentionally small and readable; deeper
product and platform complexity belongs in Banyan Labs.

The environment model is present now:

```bash
basectl run base-demo environments -- list
basectl run base-demo environments -- show dev
basectl run base-demo environments -- validate --all
```

`dev` is the runnable local environment. `staging` and `prod` are modeled
configuration examples that are validated structurally but not deployed. The
`services` command applies each environment's service, requiredness, and
infrastructure selection to status, checks, lifecycle actions, and logs. It
rejects `start`, `stop`, and `restart` for non-operational environments before
running Docker Compose or a local process.

The first representative-environment command is:

```bash
basectl run base-demo services -- status
basectl run base-demo services -- check
BASE_DEMO_SERVICES_DRY_RUN=1 basectl run base-demo services -- start
```

It reads `services/catalog.json` and reports the current catalog health. Local
Postgres, MySQL, Redis, and the Dockerized Go API are declared through
`infra/compose.yaml`; the Python API is managed as a local process by the same
`services` command, as are the Java Gradle, Java Maven, C, C++, and React/Vite
console services. They are representative dependencies and services, and they
are optional in `services check` until started.

Compose publishes every development port on `127.0.0.1`; it does not expose
these fixtures to the LAN. The checked-in Postgres and MySQL passwords and the
unauthenticated Redis service are deliberately disposable local examples, not
credentials or configurations for shared, remote, staging, or production use.
Destroy and recreate the containers instead of preserving data that matters.

The `services` command derives a stable Compose project name from the resolved
checkout path and active environment. Separate worktrees therefore get separate
container identities, while `stop` and `logs` stay scoped to the worktree that
invoked them. Automation may set `BASE_DEMO_COMPOSE_PROJECT` to a valid explicit
lowercase Compose project name. The published host ports remain fixed, so only
one checkout can bind a given port at a time.

The public infrastructure images intentionally track narrow development tags
(`postgres:16-alpine`, `mysql:8.4`, and `redis:7-alpine`) instead of checked-in
platform-specific digests. Refresh them by pulling during normal dependency
maintenance and validate `docker compose -f infra/compose.yaml config` plus the
full repository suite before accepting an image update. Production consumers
must define their own immutable image and provenance policy.

Both Gradle and Maven are present intentionally. They are common enough in real
enterprise Java estates that a medium-shaped demo should exercise both build
tool contracts, even when the service behavior stays hello-world small.

For CI or scripted validation, run the walkthrough without prompts:

```bash
basectl demo base-demo -- --non-interactive
```

CI also runs the representative BATS suites, validates every environment JSON
file, checks the service catalog, and exercises service startup through
`BASE_DEMO_SERVICES_DRY_RUN=1`. Docker and language-toolchain-heavy runtime
checks remain optional locally so the baseline stays useful on a fresh machine.

## License

base-demo is licensed under the MIT License so it can be freely copied as a
small reference project for Base-managed workflows. See [LICENSE](LICENSE) for
the full terms.
