#!/usr/bin/env bash

host_os="$(uname -s 2>/dev/null || printf 'unknown')"
case "$host_os" in
  Darwin)
    ;;
  Linux)
    printf 'Linux detected: tests/validate.sh runs repository-local checks; full Base setup/demo is macOS-only.\n'
    ;;
  *)
    printf 'Host OS %s detected: repository-local validation is supported, but full Base setup/demo is macOS-only.\n' "$host_os"
    ;;
esac

required_files=(
  README.md
  VERSION
  CHANGELOG.md
  CONTRIBUTING.md
  AGENTS.md
  skills.md
  LICENSE
  install.sh
  workspace.yaml.example
  docs/contracts.md
  docs/representative-environment.md
  docs/tooling-testbed.md
  base_manifest.yaml
  pyproject.toml
  uv.lock
  Brewfile
  justfile
  Taskfile.yml
  examples/tooling/env-dotfiles/README.md
  examples/tooling/env-dotfiles/direnv/envrc.example
  examples/tooling/env-dotfiles/asdf/tool-versions.example
  examples/tooling/env-dotfiles/chezmoi/dot_config/base-demo/base-demo.env.tmpl
  examples/tooling/env-dotfiles/dotbot/install.conf.yaml.example
  examples/tooling/multi-repo/README.md
  examples/tooling/multi-repo/mani/mani.yaml.example
  examples/tooling/multi-repo/gita/gita-commands.example
  examples/tooling/multi-repo/vcs2l/vcs2l.yaml.example
  examples/tooling/multi-repo/west/west.yml.example
  .mise.toml
  .base/activate.sh
  bin/base-demo-python-info
  bin/base-demo-services
  bin/base-demo-environments
  bin/base_demo_environment.py
  services/catalog.json
  infra/compose.yaml
  services/go-api/go.mod
  services/go-api/main.go
  services/go-api/server_test.go
  services/go-api/Dockerfile
  services/go-api/build.sh
  services/python-api/server.py
  services/python-api/build.sh
  services/python-api/test.sh
  services/java-gradle-api/settings.gradle
  services/java-gradle-api/build.gradle
  services/java-gradle-api/src/main/java/com/codeforester/basedemo/javagradle/JavaGradleApi.java
  services/java-gradle-api/src/test/java/com/codeforester/basedemo/javagradle/JavaGradleApiTest.java
  services/java-gradle-api/build.sh
  services/java-gradle-api/test.sh
  services/java-gradle-api/run.sh
  services/java-maven-api/pom.xml
  services/java-maven-api/src/main/java/com/codeforester/basedemo/javamaven/JavaMavenApi.java
  services/java-maven-api/src/test/java/com/codeforester/basedemo/javamaven/JavaMavenApiTest.java
  services/java-maven-api/build.sh
  services/java-maven-api/test.sh
  services/java-maven-api/run.sh
  services/c-service/Makefile
  services/c-service/main.c
  services/c-service/build.sh
  services/c-service/test.sh
  services/c-service/run.sh
  services/cpp-service/Makefile
  services/cpp-service/main.cpp
  services/cpp-service/build.sh
  services/cpp-service/test.sh
  services/cpp-service/run.sh
  services/demo-console/package.json
  services/demo-console/package-lock.json
  services/demo-console/index.html
  services/demo-console/vite.config.js
  services/demo-console/src/main.jsx
  services/demo-console/src/App.jsx
  services/demo-console/src/App.css
  services/demo-console/scripts/prepare-catalog.mjs
  services/demo-console/scripts/validate-source.mjs
  services/demo-console/public/service-catalog.json
  services/demo-console/build.sh
  services/demo-console/test.sh
  services/demo-console/run.sh
  environments/dev.json
  environments/staging.json
  environments/prod.json
  src/hello.sh
  src/env.sh
  src/manifest.sh
  src/build-info.sh
  src/uv-info.py
  lib/python/base_demo_cli/__init__.py
  lib/python/base_demo_cli/__main__.py
  lib/python/base_demo_cli/tests/test_cli.py
  demo/demo.sh
  tests/demo_test.bats
  tests/install_test.bats
  tests/services_test.bats
  tests/environments_test.bats
  tests/infra_test.bats
  tests/go_api_test.bats
  tests/python_api_test.py
  tests/python_api_test.bats
  tests/java_services_test.bats
  tests/native_services_test.bats
  tests/demo_console_test.bats
  .github/workflows/tests.yml
  .github/workflows/issue-branch-policy.yml
  .github/pull_request_template.md
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    printf 'Missing required file: %s\n' "$file" >&2
    exit 1
  }
done

for executable in tests/validate.sh install.sh .base/activate.sh bin/base-demo-python-info bin/base-demo-services bin/base-demo-environments src/hello.sh src/env.sh src/manifest.sh src/build-info.sh src/uv-info.py services/go-api/build.sh services/python-api/server.py services/python-api/build.sh services/python-api/test.sh services/java-gradle-api/build.sh services/java-gradle-api/test.sh services/java-gradle-api/run.sh services/java-maven-api/build.sh services/java-maven-api/test.sh services/java-maven-api/run.sh services/c-service/build.sh services/c-service/test.sh services/c-service/run.sh services/cpp-service/build.sh services/cpp-service/test.sh services/cpp-service/run.sh services/demo-console/build.sh services/demo-console/test.sh services/demo-console/run.sh demo/demo.sh; do
  [[ -x "$executable" ]] || {
    printf 'Required file is not executable: %s\n' "$executable" >&2
    exit 1
  }
done

grep -Fq 'name: base-demo' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare project name base-demo.\n' >&2
  exit 1
}

grep -Fq '  languages:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare project.languages.\n' >&2
  exit 1
}

for language in python go java c cpp javascript; do
  grep -Fxq "    - ${language}" base_manifest.yaml || {
    printf 'base_manifest.yaml does not declare project language: %s.\n' "$language" >&2
    exit 1
  }
done

grep -Fq 'command: ./tests/validate.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the validation test command.\n' >&2
  exit 1
}

grep -Fq '.base/activate.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the activation source.\n' >&2
  exit 1
}

stale_ref_scan_paths=(
  README.md
  install.sh
  .github
  services
  docs
  base_manifest.yaml
  CHANGELOG.md
  .ai-context
)
stale_github_refs="$(
  grep -RInE '(github\.com|raw\.githubusercontent\.com)/codeforester|codeforester/(base-demo|banyanlabs|base)([^[:alnum:]_.-]|$)' "${stale_ref_scan_paths[@]}" || true
)"
if [[ -n "$stale_github_refs" ]]; then
  printf 'Found stale codeforester GitHub references:\n%s\n' "$stale_github_refs" >&2
  exit 1
fi

if grep -Fq 'raw.githubusercontent.com/basefoundry/base/master/' install.sh; then
  printf 'install.sh must not use Base master branch raw URLs.\n' >&2
  exit 1
fi

floating_actions_refs="$(
  grep -RInE 'uses:[[:space:]]+actions/[^@]+@v[0-9]+' .github/workflows || true
)"
if [[ -n "$floating_actions_refs" ]]; then
  printf 'Found floating GitHub Action refs; pin actions to full commit SHAs:\n%s\n' "$floating_actions_refs" >&2
  exit 1
fi

grep -Fq 'pull_request_target:' .github/workflows/issue-branch-policy.yml || {
  printf '.github/workflows/issue-branch-policy.yml does not validate pull_request_target events.\n' >&2
  exit 1
}

grep -Fq 'POLICY_CONTEXT: base/issue-branch-policy' .github/workflows/issue-branch-policy.yml || {
  printf '.github/workflows/issue-branch-policy.yml does not publish the Base issue-branch policy context.\n' >&2
  exit 1
}

base_release_pin_count="$(
  grep -Fc 'git -C ../base fetch --depth 1 origin 26b9af5dee16efcb47e652513ce734b3ae9bc920' .github/workflows/tests.yml || true
)"
if [[ "$base_release_pin_count" -ne 3 ]]; then
  printf '.github/workflows/tests.yml must pin every Base checkout to the immutable v1.8.0 release commit.\n' >&2
  exit 1
fi

if grep -Fq '591e34a8fed6ce9cbe27f483f852bec81153f3eb' .github/workflows/tests.yml; then
  printf '.github/workflows/tests.yml must not fetch the old unreleased language-profile commit.\n' >&2
  exit 1
fi

base_bash_libs_pin_count="$(
  grep -Fc 'ref: b4243765726c133499feeabdc50154f99c0fec12' .github/workflows/tests.yml || true
)"
if [[ "$base_bash_libs_pin_count" -ne 3 ]]; then
  printf '.github/workflows/tests.yml must pin every base-bash-libs checkout to the immutable v2.0.0 GA commit.\n' >&2
  exit 1
fi

grep -Fq 'Review base-demo manifest commands' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not review manifest-declared commands before trusting them.\n' >&2
  exit 1
}

grep -Fq 'basectl test base-demo --workspace .. --dry-run' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not dry-run the manifest test command before trust.\n' >&2
  exit 1
}

grep -Fq 'basectl trust allow base-demo --workspace ..' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not allow the base-demo manifest before executing trusted commands.\n' >&2
  exit 1
}

grep -Fq 'validate-ubuntu:' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not declare the Ubuntu read-only validation job.\n' >&2
  exit 1
}

grep -Fq 'runs-on: ubuntu-latest' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run the Ubuntu validation job on ubuntu-latest.\n' >&2
  exit 1
}

grep -Fq 'python3 python3-venv python3-pip jq' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not install the Ubuntu CI prerequisites.\n' >&2
  exit 1
}

grep -Fq 'Set up Base on Ubuntu' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not set up Base through basectl on Ubuntu.\n' >&2
  exit 1
}

grep -Fq 'basectl setup base --yes --no-notify' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run the Ubuntu Base setup path with --yes.\n' >&2
  exit 1
}

grep -Fq 'Validate Ubuntu dev profile setup' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not validate the Ubuntu dev profile setup path.\n' >&2
  exit 1
}

grep -Fq 'basectl setup base --profile dev --yes --no-notify' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run the Ubuntu dev profile setup path with --yes.\n' >&2
  exit 1
}

for ubuntu_dev_tool in 'bats --version' 'gh --version' 'shellcheck --version'; do
  grep -Fq "$ubuntu_dev_tool" .github/workflows/tests.yml || {
    printf '.github/workflows/tests.yml does not verify Ubuntu dev tool: %s.\n' "$ubuntu_dev_tool" >&2
    exit 1
  }
done

if grep -Fq 'python3 -m venv "$HOME/.base.d/base/.venv"' .github/workflows/tests.yml; then
  printf '.github/workflows/tests.yml must not bootstrap the Ubuntu Base venv manually.\n' >&2
  exit 1
fi

if grep -Fq 'requirements-dev.txt' .github/workflows/tests.yml; then
  printf '.github/workflows/tests.yml must not install Base Python requirements manually on Ubuntu.\n' >&2
  exit 1
fi

grep -Fq 'basectl check --ci base-demo --manifest ./base_manifest.yaml --format json' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run base-demo read-only CI JSON validation on Ubuntu.\n' >&2
  exit 1
}

grep -Fq 'uv sync --locked' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not materialize the uv project environment.\n' >&2
  exit 1
}

grep -Fq 'validate-base-cli-source:' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not define the base-cli source compatibility job.\n' >&2
  exit 1
}

grep -Fq 'BASE_CLI_SOURCE_DIR: ${{ github.workspace }}/../base-cli/lib/python' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not configure the base-cli source root for compatibility CI.\n' >&2
  exit 1
}

grep -Fq 'git clone --depth 1 --branch v0.4.2 https://github.com/basefoundry/base-cli.git ../base-cli' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not pin the source compatibility checkout to base-cli v0.4.2.\n' >&2
  exit 1
}

grep -Fq 'git -C ../base fetch --depth 1 origin 26b9af5dee16efcb47e652513ce734b3ae9bc920' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not pin the source compatibility job to the Base v1.8.0 release commit.\n' >&2
  exit 1
}

grep -Fq 'ref: b4243765726c133499feeabdc50154f99c0fec12' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not use the v2.0.0 GA base-bash-libs source required by the Base v1.8.0 release.\n' >&2
  exit 1
}

grep -Fq "grep -Fq 'BASE_CLI_SOURCE=explicit'" .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not verify the explicit base-cli source provider.\n' >&2
  exit 1
}

grep -Fq "jq -e '.status'" .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not verify the Ubuntu CI JSON status field.\n' >&2
  exit 1
}

grep -Fq 'hello: ./src/hello.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the hello command.\n' >&2
  exit 1
}

grep -Fq 'env: ./src/env.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the env command.\n' >&2
  exit 1
}

grep -Fq 'print_var BASE_OS' src/env.sh || {
  printf 'src/env.sh does not print BASE_OS.\n' >&2
  exit 1
}

grep -Fq 'print_var BASE_PLATFORM' src/env.sh || {
  printf 'src/env.sh does not print BASE_PLATFORM.\n' >&2
  exit 1
}

grep -Fq 'print_var BASE_HOST_ENV' src/env.sh || {
  printf 'src/env.sh does not print BASE_HOST_ENV.\n' >&2
  exit 1
}

grep -Fq 'print_var BASE_HOST' src/env.sh || {
  printf 'src/env.sh does not print BASE_HOST.\n' >&2
  exit 1
}

grep -Fq 'require_contains "env command" "$env_output" "BASE_HOST_ENV="' demo/demo.sh || {
  printf 'demo/demo.sh does not assert BASE_HOST_ENV in env command output.\n' >&2
  exit 1
}

grep -Fq 'require_contains "env command" "$env_output" "BASE_HOST="' demo/demo.sh || {
  printf 'demo/demo.sh does not assert BASE_HOST in env command output.\n' >&2
  exit 1
}

grep -Fq 'manifest: ./src/manifest.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the manifest command.\n' >&2
  exit 1
}

grep -Fq 'python-info: ./bin/base-demo-python-info' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the python-info command.\n' >&2
  exit 1
}

grep -Fq '@app.subcommand()' lib/python/base_demo_cli/__main__.py || {
  printf 'base_demo_cli does not declare subcommands.\n' >&2
  exit 1
}

grep -Fq 'base_cli.testing' lib/python/base_demo_cli/tests/test_cli.py || {
  printf 'base_demo_cli tests do not use base_cli.testing.\n' >&2
  exit 1
}

raw_lifecycle_exit_returns="$(
  grep -nE 'return [012]($|[[:space:]])' bin/base-demo-services bin/base-demo-environments || true
)"
if [[ -n "$raw_lifecycle_exit_returns" ]]; then
  printf 'Lifecycle scripts must use named exit code constants instead of raw return literals:\n%s\n' "$raw_lifecycle_exit_returns" >&2
  exit 1
fi

grep -Fq 'services: ./bin/base-demo-services' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the services command.\n' >&2
  exit 1
}

grep -Fq 'environments: ./bin/base-demo-environments' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the environments command.\n' >&2
  exit 1
}

grep -Fq 'script: ./demo/demo.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the demo script.\n' >&2
  exit 1
}

grep -Fq '"name": "project-baseline"' services/catalog.json || {
  printf 'services/catalog.json does not declare the project-baseline entry.\n' >&2
  exit 1
}

python3 - "$PWD/services/catalog.json" <<'PY'
import json
import sys

catalog_path = sys.argv[1]
with open(catalog_path, encoding="utf-8") as handle:
    catalog = json.load(handle)

services = catalog.get("services", [])
baseline = next((service for service in services if service.get("name") == "project-baseline"), None)
if baseline is None:
    raise SystemExit("services/catalog.json does not declare project-baseline.")
if baseline.get("required") is not True:
    raise SystemExit("project-baseline must remain required: true.")

missing_health_url = [
    service.get("name", "<unnamed>")
    for service in services
    if service.get("check", {}).get("type") == "http" and not service.get("health_url")
]
if missing_health_url:
    raise SystemExit(
        "HTTP service checks must declare health_url: " + ", ".join(missing_health_url)
    )
PY

for service in postgres mysql redis; do
  grep -Fq "\"name\": \"$service\"" services/catalog.json || {
    printf 'services/catalog.json does not declare %s.\n' "$service" >&2
    exit 1
  }
  grep -Fq "  $service:" infra/compose.yaml || {
    printf 'infra/compose.yaml does not declare %s.\n' "$service" >&2
    exit 1
  }
done

grep -Fq '"name": "go-api"' services/catalog.json || {
  printf 'services/catalog.json does not declare go-api.\n' >&2
  exit 1
}

grep -Fq '  go-api:' infra/compose.yaml || {
  printf 'infra/compose.yaml does not declare go-api.\n' >&2
  exit 1
}

if grep -Fq 'container_name:' infra/compose.yaml; then
  printf 'infra/compose.yaml must let Compose derive worktree-scoped container names.\n' >&2
  exit 1
fi

compose_port_count="$(grep -Ec '^[[:space:]]+- "127\.0\.0\.1:[0-9]+:[0-9]+"$' infra/compose.yaml || true)"
if [[ "$compose_port_count" -ne 4 ]]; then
  printf 'infra/compose.yaml must bind all four published ports to 127.0.0.1.\n' >&2
  exit 1
fi

if grep -Eq '^[[:space:]]+- "[0-9]+:[0-9]+"$' infra/compose.yaml; then
  printf 'infra/compose.yaml contains a published port without an explicit loopback host.\n' >&2
  exit 1
fi

for compose_contract in compose_project_name BASE_DEMO_COMPOSE_PROJECT checkout_digest; do
  grep -Fq "$compose_contract" bin/base-demo-services || {
    printf 'bin/base-demo-services does not declare Compose isolation contract: %s.\n' "$compose_contract" >&2
    exit 1
  }
done

grep -Fq '`compose-local-isolation`' docs/contracts.md || {
  printf 'docs/contracts.md does not register the Compose local-isolation contract.\n' >&2
  exit 1
}

grep -Fq 'compose_project=base-demo-dev-' demo/demo.sh || {
  printf 'demo/demo.sh does not demonstrate worktree-scoped Compose project naming.\n' >&2
  exit 1
}

if command -v go >/dev/null 2>&1; then
  (cd services/go-api && CGO_ENABLED=0 go test ./...) || exit 1
else
  printf 'Skipping go-api tests because go is not available.\n'
fi

grep -Fq '"name": "python-api"' services/catalog.json || {
  printf 'services/catalog.json does not declare python-api.\n' >&2
  exit 1
}

grep -Fq '"port": 8020' services/catalog.json || {
  printf 'services/catalog.json does not declare python-api port 8020.\n' >&2
  exit 1
}

services/python-api/test.sh || exit 1

for service in java-gradle-api java-maven-api; do
  grep -Fq "\"name\": \"$service\"" services/catalog.json || {
    printf 'services/catalog.json does not declare %s.\n' "$service" >&2
    exit 1
  }
done

if command -v javac >/dev/null 2>&1; then
  services/java-gradle-api/build.sh || exit 1
  services/java-maven-api/build.sh || exit 1
else
  printf 'Skipping Java service builds because javac is not available.\n'
fi

for service in c-service cpp-service; do
  grep -Fq "\"name\": \"$service\"" services/catalog.json || {
    printf 'services/catalog.json does not declare %s.\n' "$service" >&2
    exit 1
  }
done

if command -v make >/dev/null 2>&1 && command -v cc >/dev/null 2>&1 && command -v c++ >/dev/null 2>&1; then
  services/c-service/build.sh || exit 1
  services/c-service/test.sh || exit 1
  services/cpp-service/build.sh || exit 1
  services/cpp-service/test.sh || exit 1
else
  printf 'Skipping native service builds because make, cc, or c++ is not available.\n'
fi

grep -Fq '"name": "demo-console"' services/catalog.json || {
  printf 'services/catalog.json does not declare demo-console.\n' >&2
  exit 1
}

grep -Fq '"runtime": "react-vite"' services/catalog.json || {
  printf 'services/catalog.json does not declare demo-console runtime react-vite.\n' >&2
  exit 1
}

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  printf 'Node and npm are required to validate the demo console build.\n' >&2
  exit 1
fi

services/demo-console/build.sh || exit 1

[[ -f services/demo-console/dist/index.html ]] || {
  printf 'demo-console validation did not create dist/index.html.\n' >&2
  exit 1
}

find services/demo-console/dist/assets -type f -name '*.js' -print -quit | grep -q . || {
  printf 'demo-console validation did not create a JavaScript entry artifact.\n' >&2
  exit 1
}

grep -Fq '"lockfileVersion": 3' services/demo-console/package-lock.json || {
  printf 'demo-console package-lock.json must use the npm 10 lockfile format.\n' >&2
  exit 1
}

for frontend_ci_contract in \
  'actions/setup-node@820762786026740c76f36085b0efc47a31fe5020' \
  'node-version: 22.22.0' \
  'run: npm ci' \
  'npm run build' \
  'npm run audit'; do
  frontend_ci_count="$(grep -Fc "$frontend_ci_contract" .github/workflows/tests.yml || true)"
  if [[ "$frontend_ci_count" -lt 2 ]]; then
    printf '.github/workflows/tests.yml must enforce frontend contract in macOS and Ubuntu CI: %s.\n' "$frontend_ci_contract" >&2
    exit 1
  fi
done

if grep -Fq 'Skipping demo-console Vite build' services/demo-console/build.sh; then
  printf 'demo-console build must not skip Vite compilation.\n' >&2
  exit 1
fi

for environment in dev staging prod; do
  grep -Fq "\"name\": \"$environment\"" "environments/$environment.json" || {
    printf 'environments/%s.json does not declare matching environment name.\n' "$environment" >&2
    exit 1
  }
done

for environment_field in name mode operational base_url logging services infrastructure; do
  grep -Fq "\"$environment_field\"" bin/base_demo_environment.py || {
    printf 'bin/base_demo_environment.py does not declare expected environment field: %s.\n' "$environment_field" >&2
    exit 1
  }
done

for environment_contract in \
  LOG_LEVELS \
  LOG_FORMATS \
  SERVICE_OVERRIDE_FIELDS \
  INFRASTRUCTURE_OVERRIDE_FIELDS \
  valid_http_url \
  catalog_contract \
  compose_service_names; do
  grep -Fq "$environment_contract" bin/base_demo_environment.py || {
    printf 'bin/base_demo_environment.py does not enforce environment contract: %s.\n' "$environment_contract" >&2
    exit 1
  }
done

for environment_contract_path in \
  'services.python-api.required' \
  'infrastructure.postgres.port' \
  'services.missing-api' \
  'infrastructure.rabbitmq'; do
  grep -Fq "$environment_contract_path" tests/environments_test.bats || {
    printf 'tests/environments_test.bats does not cover nested environment path: %s.\n' "$environment_contract_path" >&2
    exit 1
  }
done

for environment_contract_doc in \
  README.md \
  .ai-context/overview.md \
  .ai-context/manifest.md \
  docs/representative-environment.md \
  demo/demo.sh; do
  grep -Fq 'BASE_DEMO_ENV=baseline' "$environment_contract_doc" || {
    printf '%s does not document the Base environment health marker.\n' "$environment_contract_doc" >&2
    exit 1
  }
  grep -Fq 'services --env dev' "$environment_contract_doc" || {
    printf '%s does not distinguish the representative service selector.\n' "$environment_contract_doc" >&2
    exit 1
  }
done

grep -Fq 'base-cli==0.4.2' .ai-context/overview.md || {
  printf '.ai-context/overview.md does not match the locked base-cli version.\n' >&2
  exit 1
}

if grep -Rq 'base-cli==0.4.1' .ai-context; then
  printf '.ai-context still contains the stale base-cli==0.4.1 claim.\n' >&2
  exit 1
fi

if grep -Fq 'separation of ports' docs/representative-environment.md; then
  printf 'docs/representative-environment.md still claims modeled port separation.\n' >&2
  exit 1
fi

grep -Fq 'load_validated_environment' bin/base-demo-services || {
  printf 'bin/base-demo-services does not reuse validated environment loading.\n' >&2
  exit 1
}

grep -Fq 'required_env:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare health.required_env.\n' >&2
  exit 1
}

grep -Fq 'export BASE_DEMO_ENV="${BASE_DEMO_ENV:-baseline}"' .base/activate.sh || {
  printf '.base/activate.sh does not own the BASE_DEMO_ENV=baseline default.\n' >&2
  exit 1
}

grep -Fq 'Normal green path' README.md || {
  printf 'README.md does not document the BASE_DEMO_ENV normal green path.\n' >&2
  exit 1
}

grep -Fq 'Pre-activation diagnostic' README.md || {
  printf 'README.md does not document the BASE_DEMO_ENV pre-activation diagnostic.\n' >&2
  exit 1
}

grep -Fq 'CI sets BASE_DEMO_ENV=baseline' README.md || {
  printf 'README.md does not document the CI BASE_DEMO_ENV contract.\n' >&2
  exit 1
}

grep -Fq 'check --ci "$BASE_DEMO_PROJECT" --format json' demo/demo.sh || {
  printf 'demo/demo.sh does not include the basectl check --ci JSON walkthrough step.\n' >&2
  exit 1
}

grep -Fq 'basectl check --ci base-demo --format json' README.md || {
  printf 'README.md does not document the basectl check --ci JSON command.\n' >&2
  exit 1
}

grep -Fq 'basectl trust status base-demo' README.md || {
  printf 'README.md does not document the manifest trust status command.\n' >&2
  exit 1
}

grep -Fq 'basectl build base-demo --list' README.md || {
  printf 'README.md does not document build target inspection before trust.\n' >&2
  exit 1
}

grep -Fq 'basectl test base-demo --dry-run' README.md || {
  printf 'README.md does not document test dry-run inspection before trust.\n' >&2
  exit 1
}

grep -Fq 'basectl history --project base-demo --limit 5 --report' README.md || {
  printf 'README.md does not document the history report command.\n' >&2
  exit 1
}

grep -Fq 'history --project "$BASE_DEMO_PROJECT" --limit 5 --report' demo/demo.sh || {
  printf 'demo/demo.sh does not exercise the history report command.\n' >&2
  exit 1
}

grep -Fq 'history-report-observability' docs/contracts.md || {
  printf 'docs/contracts.md does not register the history report observability contract.\n' >&2
  exit 1
}

grep -Fq 'basectl gh issue readiness <issue-number> --repo basefoundry/base-demo --project-owner basefoundry --project-number 9 --format json' AGENTS.md || {
  printf 'AGENTS.md does not document the Base issue readiness helper.\n' >&2
  exit 1
}

grep -Fq 'basectl gh branch stale --days 14 --format json' AGENTS.md || {
  printf 'AGENTS.md does not document the Base stale branch helper.\n' >&2
  exit 1
}

grep -Fq 'basectl gh issue readiness <issue-number> --repo basefoundry/base-demo --project-owner basefoundry --project-number 9 --format json' README.md || {
  printf 'README.md does not document the Base issue readiness helper.\n' >&2
  exit 1
}

grep -Fq 'basectl gh branch stale --days 14 --format json' README.md || {
  printf 'README.md does not document the Base stale branch helper.\n' >&2
  exit 1
}

grep -Fq 'GitHub workflow hygiene is documented in `AGENTS.md` and README.' .ai-context/overview.md || {
  printf '.ai-context/overview.md does not summarize GitHub workflow hygiene.\n' >&2
  exit 1
}

grep -Fq 'github-workflow-hygiene' docs/contracts.md || {
  printf 'docs/contracts.md does not register the GitHub workflow hygiene contract.\n' >&2
  exit 1
}

grep -Fq 'basectl trust allow base-demo' README.md || {
  printf 'README.md does not document the manifest trust approval command.\n' >&2
  exit 1
}

grep -Fq 'safe inspection commands before trust is' README.md || {
  printf 'README.md does not explain the safe pre-trust inspection path.\n' >&2
  exit 1
}

grep -Fq 'run`, `test`, `build`, `demo`, and `activate`' README.md || {
  printf 'README.md does not name the trusted manifest execution surfaces.\n' >&2
  exit 1
}

grep -Fq '## Platform Requirements' README.md || {
  printf 'README.md does not include a Platform Requirements section.\n' >&2
  exit 1
}

grep -Fq 'macOS is the supported platform for the full interactive demo' README.md || {
  printf 'README.md does not document the macOS full-demo platform boundary.\n' >&2
  exit 1
}

grep -Fq 'Ubuntu/Debian CI validates Base runtime setup' README.md || {
  printf 'README.md does not document the Ubuntu/Debian Base setup CI boundary.\n' >&2
  exit 1
}

grep -Fq 'basectl setup base --yes --no-notify' README.md || {
  printf 'README.md does not document the Ubuntu/Debian Base setup command.\n' >&2
  exit 1
}

grep -Fq 'basectl setup base --profile dev --yes --no-notify' README.md || {
  printf 'README.md does not document the Ubuntu/Debian dev profile setup command.\n' >&2
  exit 1
}

grep -Fq 'read-only project health check' README.md || {
  printf 'README.md does not document the Ubuntu/Debian read-only project health boundary.\n' >&2
  exit 1
}

grep -Fq 'Ubuntu/Debian under WSL2' README.md || {
  printf 'README.md does not document the WSL2 readiness path.\n' >&2
  exit 1
}

grep -Fq '/mnt/c/...' README.md || {
  printf 'README.md does not warn WSL2 users away from /mnt/c checkouts.\n' >&2
  exit 1
}

grep -Fq 'BASE_HOST_ENV=wsl2' README.md || {
  printf 'README.md does not document expected WSL2 host metadata.\n' >&2
  exit 1
}

grep -Fq 'doctor --ci base-demo --format json' README.md || {
  printf 'README.md does not include doctor in the WSL2 smoke checklist.\n' >&2
  exit 1
}

grep -Fq 'basectl onboard base-demo --dry-run' README.md || {
  printf 'README.md does not document the onboard dry-run preview command.\n' >&2
  exit 1
}

grep -Fq 'base#1887' README.md || {
  printf 'README.md does not document the current onboard Doctor-stop limitation.\n' >&2
  exit 1
}

onboard_preview_count="$(
  grep -Fc '../base/bin/basectl onboard base-demo --dry-run' .github/workflows/tests.yml || true
)"
if [[ "$onboard_preview_count" -ne 2 ]]; then
  printf '.github/workflows/tests.yml must run onboard dry-run in both validation jobs.\n' >&2
  exit 1
fi

for onboard_preview_assertion in \
  "[DRY-RUN] Would run basectl check base-demo" \
  "[DRY-RUN] Would run basectl setup base-demo --dry-run" \
  "Projects" \
  "[DRY-RUN] Would run basectl projects list" \
  "Trust" \
  "[DRY-RUN] Would run basectl trust status"; do
  grep -Fq "$onboard_preview_assertion" .github/workflows/tests.yml || {
    printf '.github/workflows/tests.yml does not assert onboard dry-run output: %s.\n' "$onboard_preview_assertion" >&2
    exit 1
  }
done

grep -Fq 'onboard-dry-run-preview' docs/contracts.md || {
  printf 'docs/contracts.md does not register the onboard dry-run preview contract.\n' >&2
  exit 1
}

grep -Fq 'Native Windows support remains out of scope.' README.md || {
  printf 'README.md does not keep native Windows out of the WSL2 support claim.\n' >&2
  exit 1
}

grep -Fq 'Ubuntu/Debian under WSL2 uses the same Base Linux path' CONTRIBUTING.md || {
  printf 'CONTRIBUTING.md does not document the WSL2 platform boundary.\n' >&2
  exit 1
}

grep -Fq 'BASE_HOST_ENV=wsl2' .ai-context/overview.md || {
  printf '.ai-context/overview.md does not document the WSL2 host metadata boundary.\n' >&2
  exit 1
}

grep -Fq 'docs/linux-support.md' README.md || {
  printf 'README.md does not reference Base docs/linux-support.md.\n' >&2
  exit 1
}

grep -Fq '## Future Go/Cobra CLI Boundary' docs/representative-environment.md || {
  printf 'docs/representative-environment.md does not document the future Go/Cobra CLI boundary.\n' >&2
  exit 1
}

grep -Fq 'base-demo-go' docs/representative-environment.md || {
  printf 'docs/representative-environment.md does not name base-demo-go as the future Go/Cobra split option.\n' >&2
  exit 1
}

grep -Fq 'does not belong in the current baseline demo' docs/representative-environment.md || {
  printf 'docs/representative-environment.md does not keep Go/Cobra out of the current baseline demo.\n' >&2
  exit 1
}

grep -Fq 'basectl setup base-demo  # macOS only' README.md || {
  printf 'README.md does not annotate setup as macOS-only in Quick Start.\n' >&2
  exit 1
}

grep -Fq 'basectl onboard base-demo' README.md || {
  printf 'README.md does not document basectl onboard in Quick Start.\n' >&2
  exit 1
}

grep -Fq 'basectl onboard base-demo --dry-run' README.md || {
  printf 'README.md does not document basectl onboard --dry-run in Quick Start.\n' >&2
  exit 1
}

grep -Fq 'recommended guided path' README.md || {
  printf 'README.md does not describe basectl onboard as the recommended guided path.\n' >&2
  exit 1
}

grep -Fq 'basectl docs --show-url' README.md || {
  printf 'README.md does not document basectl docs --show-url in Quick Start.\n' >&2
  exit 1
}

grep -Fq 'Show Base docs URL' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not show the Base docs URL in CI.\n' >&2
  exit 1
}

grep -Fq 'basectl docs --show-url' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run basectl docs --show-url in CI.\n' >&2
  exit 1
}

grep -Fq 'basectl repo init base-demo --path . --agent-ready --no-configure --dry-run' README.md || {
  printf 'README.md does not document the agent-ready repo init dry-run preview.\n' >&2
  exit 1
}

grep -Fq 'basectl repo check . --agent-ready' README.md || {
  printf 'README.md does not document the agent-ready repo check.\n' >&2
  exit 1
}

grep -Fq 'repo init "$BASE_DEMO_PROJECT" --path "$BASE_DEMO_ROOT" --agent-ready --no-configure --dry-run' demo/demo.sh || {
  printf 'demo/demo.sh does not preview agent-ready repo init in dry-run mode.\n' >&2
  exit 1
}

grep -Fq 'repo check . --agent-ready' demo/demo.sh || {
  printf 'demo/demo.sh does not run the agent-ready repo check.\n' >&2
  exit 1
}

grep -Fq 'repo init base-demo --path . --agent-ready --no-configure --dry-run' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not preview agent-ready repo init through Base.\n' >&2
  exit 1
}

grep -Fq 'repo check . --agent-ready' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not check agent-ready repo guidance through Base.\n' >&2
  exit 1
}

grep -Fq 'agent-ready-repo-guidance' docs/contracts.md || {
  printf 'docs/contracts.md does not register the agent-ready repo guidance contract.\n' >&2
  exit 1
}

grep -Fq 'github.com/basefoundry/base' demo/demo.sh || {
  printf 'demo/demo.sh does not validate the Base docs URL host.\n' >&2
  exit 1
}

grep -Fq 'base-platform-tools' workspace.yaml.example || {
  printf 'workspace.yaml.example does not list base-platform-tools.\n' >&2
  exit 1
}

grep -Fq 'https://github.com/basefoundry/base-platform-tools.git' workspace.yaml.example || {
  printf 'workspace.yaml.example does not list the base-platform-tools GitHub URL.\n' >&2
  exit 1
}

grep -A4 'name: base-platform-tools' workspace.yaml.example | grep -Fq 'required: false' || {
  printf 'workspace.yaml.example does not mark base-platform-tools as optional.\n' >&2
  exit 1
}

grep -Fq 'base-platform-tools is an optional Base companion' demo/demo.sh || {
  printf 'demo/demo.sh does not explain the optional base-platform-tools companion.\n' >&2
  exit 1
}

grep -Fq 'base-platform-tools' README.md || {
  printf 'README.md does not document optional base-platform-tools workspace status.\n' >&2
  exit 1
}

grep -Fq 'basectl activate base-demo  # macOS only' README.md || {
  printf 'README.md does not annotate activate as macOS-only in Quick Start.\n' >&2
  exit 1
}

grep -Fq 'macOS/Ubuntu platform boundary' CONTRIBUTING.md || {
  printf 'CONTRIBUTING.md does not document the macOS/Ubuntu platform boundary.\n' >&2
  exit 1
}

grep -Fq 'Base runtime setup, dev-profile prerequisites, and read-only project health checks' CONTRIBUTING.md || {
  printf 'CONTRIBUTING.md does not document the Ubuntu/Debian CI setup/dev-profile boundary.\n' >&2
  exit 1
}

grep -Fq 'basectl setup base --profile dev --yes --no-notify' docs/contracts.md || {
  printf 'docs/contracts.md does not bind Ubuntu dev-profile CI validation.\n' >&2
  exit 1
}

grep -Fq 'Linux detected: tests/validate.sh runs repository-local checks' tests/validate.sh || {
  printf 'tests/validate.sh does not document the Linux repository-local validation boundary.\n' >&2
  exit 1
}

grep -Fq 'docs/contracts.md' README.md || {
  printf 'README.md does not reference docs/contracts.md.\n' >&2
  exit 1
}

grep -Fq 'docs/contracts.md' CONTRIBUTING.md || {
  printf 'CONTRIBUTING.md does not reference docs/contracts.md.\n' >&2
  exit 1
}

grep -Fq 'basectl trust allow base-demo' CONTRIBUTING.md || {
  printf 'CONTRIBUTING.md does not include the manifest trust approval command in useful commands.\n' >&2
  exit 1
}

for contract in \
  project-baseline-required \
  http-health-url \
  non-interactive-demo \
  manifest-trust-flow \
  environment-schema \
  environment-aware-services \
  uv-project-manager \
  uv-runner-command \
  activation-owned-env \
  manifest-artifacts \
  runtime-platform-env \
  python-env-privacy \
  installer-checksum \
  service-log-permissions \
  service-state-containment \
  service-lifecycle-transactions \
  service-process-identity \
  ci-pinned-dependencies \
  ubuntu-ci \
  platform-boundary \
  ci-json-check \
  tooling-testbed-boundary \
  base-generated-environment-reports \
  optional-task-runner-wrappers \
  reference-env-dotfile-examples \
  reference-multirepo-examples
do
  grep -Fq "| \`$contract\` |" docs/contracts.md || {
    printf 'docs/contracts.md does not list contract %s.\n' "$contract" >&2
    exit 1
  }
done

for forbidden_active_multirepo_file in mani.yaml vcs2l.yaml west.yml; do
  if [[ -e "$forbidden_active_multirepo_file" ]]; then
    printf 'Reference multi-repo examples must not create active root file: %s.\n' "$forbidden_active_multirepo_file" >&2
    exit 1
  fi
done

grep -Fq 'examples/tooling/multi-repo/' README.md || {
  printf 'README.md does not document reference multi-repo examples.\n' >&2
  exit 1
}

for multirepo_token in mani gita vcs2l west 'workspace.yaml.example' 'read-only'; do
  grep -Fq "$multirepo_token" examples/tooling/multi-repo/README.md || {
    printf 'multi-repo README does not document token: %s.\n' "$multirepo_token" >&2
    exit 1
  }
done

for multirepo_example in \
  examples/tooling/multi-repo/mani/mani.yaml.example \
  examples/tooling/multi-repo/gita/gita-commands.example \
  examples/tooling/multi-repo/vcs2l/vcs2l.yaml.example \
  examples/tooling/multi-repo/west/west.yml.example
do
  grep -Fq 'base' "$multirepo_example" || {
    printf '%s does not reference the Base repository name.\n' "$multirepo_example" >&2
    exit 1
  }
  grep -Fq 'base-demo' "$multirepo_example" || {
    printf '%s does not reference the base-demo repository name.\n' "$multirepo_example" >&2
    exit 1
  }
done

for forbidden_active_dotfile in .envrc .tool-versions install.conf.yaml; do
  if [[ -e "$forbidden_active_dotfile" ]]; then
    printf 'Reference shell/dotfile examples must not create active root file: %s.\n' "$forbidden_active_dotfile" >&2
    exit 1
  fi
done

grep -Fq 'examples/tooling/env-dotfiles/' README.md || {
  printf 'README.md does not document reference shell/dotfile examples.\n' >&2
  exit 1
}

for reference_dotfile_token in direnv asdf chezmoi dotbot 'reference-only'; do
  grep -Fq "$reference_dotfile_token" examples/tooling/env-dotfiles/README.md || {
    printf 'env-dotfiles README does not document token: %s.\n' "$reference_dotfile_token" >&2
    exit 1
  }
done

grep -Fq 'basectl activate base-demo' examples/tooling/env-dotfiles/direnv/envrc.example || {
  printf 'direnv example does not point back to Base activation.\n' >&2
  exit 1
}

grep -Fq 'python 3.13.0' examples/tooling/env-dotfiles/asdf/tool-versions.example || {
  printf 'asdf example does not mirror the reference Python version.\n' >&2
  exit 1
}

grep -Fq 'justfile' README.md && grep -Fq 'Taskfile.yml' README.md || {
  printf 'README.md does not document optional task-runner wrappers.\n' >&2
  exit 1
}

for task_runner_file in justfile Taskfile.yml; do
  for delegated_command in \
    'basectl check' \
    'basectl check --ci' \
    'basectl test' \
    'basectl build' \
    'basectl demo' \
    'basectl run'
  do
    grep -Fq "$delegated_command" "$task_runner_file" || {
      printf '%s does not delegate command to Base: %s.\n' "$task_runner_file" "$delegated_command" >&2
      exit 1
    }
  done
done

grep -Fq 'installing `just` or Task is not required' README.md || {
  printf 'README.md does not state that task runners are optional.\n' >&2
  exit 1
}

grep -Fq 'basectl devcontainer base-demo --format json' README.md || {
  printf 'README.md does not document the devcontainer report command.\n' >&2
  exit 1
}

grep -Fq 'basectl devenv-report base-demo --format json' README.md || {
  printf 'README.md does not document the devenv-report command.\n' >&2
  exit 1
}

for generated_report_command in \
  'basectl devcontainer base-demo --workspace .. --format json' \
  'basectl devenv-report base-demo --workspace .. --format json'
do
  grep -Fq "$generated_report_command" .github/workflows/tests.yml || {
    printf '.github/workflows/tests.yml does not run Base-generated report command: %s.\n' "$generated_report_command" >&2
    exit 1
  }
done

for generated_report_assertion in \
  '.write == false' \
  '.supported | index("ide.vscode.extensions")' \
  '.target == "nix/devenv"'
do
  grep -Fq "$generated_report_assertion" .github/workflows/tests.yml || {
    printf '.github/workflows/tests.yml does not assert Base-generated report field: %s.\n' "$generated_report_assertion" >&2
    exit 1
  }
done

grep -Fq 'docs/tooling-testbed.md' README.md || {
  printf 'README.md does not reference docs/tooling-testbed.md.\n' >&2
  exit 1
}

grep -Fq 'docs/tooling-testbed.md' .ai-context/overview.md || {
  printf '.ai-context/overview.md does not reference docs/tooling-testbed.md.\n' >&2
  exit 1
}

for tooling_section in Baseline 'Optional live' 'Reference-only'; do
  grep -Fq "$tooling_section" docs/tooling-testbed.md || {
    printf 'docs/tooling-testbed.md does not document tooling section: %s.\n' "$tooling_section" >&2
    exit 1
  }
done

for tooling_token in \
  direnv \
  asdf \
  chezmoi \
  dotbot \
  just \
  Taskfile \
  mani \
  gita \
  vcs2l \
  west \
  devcontainer \
  devenv-report \
  'Nix/devenv' \
  docker-service
do
  grep -Fq "$tooling_token" docs/tooling-testbed.md || {
    printf 'docs/tooling-testbed.md does not document tooling token: %s.\n' "$tooling_token" >&2
    exit 1
  }
done

grep -Fq 'BASE_OS' README.md && grep -Fq 'BASE_PLATFORM' README.md && grep -Fq 'BASE_HOST_ENV' README.md && grep -Fq 'BASE_HOST' README.md || {
  printf 'README.md does not document the env command BASE_OS/BASE_PLATFORM/BASE_HOST_ENV/BASE_HOST output.\n' >&2
  exit 1
}

grep -Fq 'BASE_OS' .ai-context/manifest.md && grep -Fq 'BASE_PLATFORM' .ai-context/manifest.md && grep -Fq 'BASE_HOST_ENV' .ai-context/manifest.md && grep -Fq 'BASE_HOST' .ai-context/manifest.md || {
  printf '.ai-context/manifest.md does not document the env command BASE_OS/BASE_PLATFORM/BASE_HOST_ENV/BASE_HOST output.\n' >&2
  exit 1
}

if grep -Fq 'will add service, infrastructure, UI' .ai-context/manifest.md; then
  printf '.ai-context/manifest.md still describes committed representative environment commands as future work.\n' >&2
  exit 1
fi

for ai_context_token in \
  'services/catalog.json' \
  'infra/compose.yaml' \
  'multi-language service fixtures' \
  'React/Vite console' \
  'BASE_DEMO_SERVICES_DRY_RUN=1'
do
  grep -Fq "$ai_context_token" .ai-context/manifest.md || {
    printf '.ai-context/manifest.md does not document current representative environment token: %s.\n' "$ai_context_token" >&2
    exit 1
  }
done

grep -Fq 'docs/tool-boundaries.md' .ai-context/overview.md || {
  printf '.ai-context/overview.md does not reference the Base tool-boundaries policy.\n' >&2
  exit 1
}

grep -Fq 'Brewfile currently installs mise, uv, Gradle, and Maven' README.md || {
  printf 'README.md does not document current Brewfile dependencies.\n' >&2
  exit 1
}

grep -Fq 'currently includes mise, uv, Gradle, and Maven' .ai-context/manifest.md || {
  printf '.ai-context/manifest.md does not document current Brewfile dependencies.\n' >&2
  exit 1
}

grep -Fq 'artifacts:' base_manifest.yaml && grep -Fq 'name: bats-core' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the bats-core artifact.\n' >&2
  exit 1
}

grep -Fq 'type: tool' base_manifest.yaml && grep -Fq 'version: latest' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the bats-core artifact as a latest tool artifact.\n' >&2
  exit 1
}

grep -Fq 'bats-core' README.md || {
  printf 'README.md does not document the demonstrated bats-core artifact.\n' >&2
  exit 1
}

grep -Fq 'bats-core' .ai-context/manifest.md || {
  printf '.ai-context/manifest.md does not document the demonstrated bats-core artifact.\n' >&2
  exit 1
}

grep -Fq 'requires_python: "3.13"' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare python.requires_python 3.13.\n' >&2
  exit 1
}

grep -Fq '  manager: uv' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare python.manager uv.\n' >&2
  exit 1
}

grep -Fq 'requires-python = ">=3.13,<3.14"' pyproject.toml || {
  printf 'pyproject.toml does not declare the supported Python 3.13 range.\n' >&2
  exit 1
}

grep -Fq 'dependencies = ["base-cli==0.4.2", "click", "PyYAML"]' pyproject.toml || {
  printf 'pyproject.toml does not declare the Base CLI runtime dependencies.\n' >&2
  exit 1
}

grep -Fq '## Python CLI Provider Policy' README.md || {
  printf 'README.md does not document the base-cli provider policy.\n' >&2
  exit 1
}

grep -Fq 'BASE_CLI_SOURCE_DIR="$PWD/../base-cli/lib/python"' README.md || {
  printf 'README.md does not document the explicit base-cli source checkout command.\n' >&2
  exit 1
}

grep -Fq 'package = false' pyproject.toml || {
  printf 'pyproject.toml must keep base-demo as a non-packaged uv project.\n' >&2
  exit 1
}

grep -Fq 'name = "base-demo"' uv.lock || {
  printf 'uv.lock does not contain the base-demo project package record.\n' >&2
  exit 1
}

grep -Fq 'name = "base-cli"' uv.lock && grep -Fq 'name = "click"' uv.lock && grep -Fq 'name = "pyyaml"' uv.lock || {
  printf 'uv.lock does not contain the Base CLI runtime dependencies.\n' >&2
  exit 1
}

grep -Fq 'project.languages' README.md || {
  printf 'README.md does not document project.languages.\n' >&2
  exit 1
}

grep -Fq 'project.languages' .ai-context/manifest.md || {
  printf '.ai-context/manifest.md does not document project.languages.\n' >&2
  exit 1
}

grep -Fq 'required_ports:' base_manifest.yaml && grep -Fq 'name: go-api' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the go-api required port health check.\n' >&2
  exit 1
}

grep -Fq 'python.requires_python' README.md || {
  printf 'README.md does not document python.requires_python.\n' >&2
  exit 1
}

grep -Fq 'python.manager' README.md || {
  printf 'README.md does not document python.manager.\n' >&2
  exit 1
}

grep -Fq 'python.manager' .ai-context/manifest.md || {
  printf '.ai-context/manifest.md does not document python.manager.\n' >&2
  exit 1
}

grep -Fq 'health.required_ports' README.md || {
  printf 'README.md does not document health.required_ports.\n' >&2
  exit 1
}

grep -Fq 'working_dir: services/go-api' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare working_dir for the go-api build target.\n' >&2
  exit 1
}

grep -Fq 'build.targets[*].working_dir' README.md || {
  printf 'README.md does not document build target working_dir.\n' >&2
  exit 1
}

grep -Fq 'brew "uv"' Brewfile || {
  printf 'Brewfile does not include uv for the runner demo.\n' >&2
  exit 1
}

grep -Fq 'uv-info:' base_manifest.yaml && grep -Fq 'runner: uv' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare a uv-backed command.\n' >&2
  exit 1
}

grep -Fq 'commands[*].runner' README.md || {
  printf 'README.md does not document command runner fields.\n' >&2
  exit 1
}

grep -Fq 'ide:' base_manifest.yaml && grep -Fq 'ms-python.python' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the VS Code IDE block.\n' >&2
  exit 1
}

grep -Fq 'python.defaultInterpreterPath: auto' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare automatic VS Code Python interpreter resolution.\n' >&2
  exit 1
}

grep -Fq 'ide.vscode' README.md || {
  printf 'README.md does not document ide.vscode.\n' >&2
  exit 1
}

grep -Fq 'workspace:' workspace.yaml.example && grep -Fq 'base-demo-reference' workspace.yaml.example || {
  printf 'workspace.yaml.example does not declare the base-demo reference workspace.\n' >&2
  exit 1
}

grep -Fq 'basectl workspace status --manifest workspace.yaml.example' README.md || {
  printf 'README.md does not document workspace status.\n' >&2
  exit 1
}

grep -Fq 'basectl export-context base-demo --format markdown --print' README.md || {
  printf 'README.md does not document export-context.\n' >&2
  exit 1
}

grep -Fq 'basectl workspace onboarding --manifest workspace.yaml.example' README.md || {
  printf 'README.md does not document workspace onboarding.\n' >&2
  exit 1
}

grep -Fq 'basectl workspace agent-brief --manifest workspace.yaml.example' README.md || {
  printf 'README.md does not document workspace agent-brief.\n' >&2
  exit 1
}

grep -Fq 'workspace onboarding --workspace "$BASE_DEMO_WORKSPACE" --manifest "$BASE_DEMO_ROOT/workspace.yaml.example"' demo/demo.sh || {
  printf 'demo/demo.sh does not run workspace onboarding against the example manifest.\n' >&2
  exit 1
}

grep -Fq 'workspace agent-brief --workspace "$BASE_DEMO_WORKSPACE" --manifest "$BASE_DEMO_ROOT/workspace.yaml.example"' demo/demo.sh || {
  printf 'demo/demo.sh does not run workspace agent-brief against the example manifest.\n' >&2
  exit 1
}

grep -Fq 'workspace onboarding --workspace .. --manifest ./workspace.yaml.example --format json' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run workspace onboarding in CI.\n' >&2
  exit 1
}

grep -Fq 'workspace agent-brief --workspace .. --manifest ./workspace.yaml.example --format json' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run workspace agent-brief in CI.\n' >&2
  exit 1
}

grep -Fq 'workspace-onboarding-agent-brief' docs/contracts.md || {
  printf 'docs/contracts.md does not register the workspace onboarding and agent-brief contract.\n' >&2
  exit 1
}

grep -Fq 'build:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare build targets.\n' >&2
  exit 1
}

grep -Fq 'mise:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare mise configuration.\n' >&2
  exit 1
}

printf 'Repository baseline is present.\n'
