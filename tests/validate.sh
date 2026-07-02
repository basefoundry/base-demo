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
  base_manifest.yaml
  Brewfile
  .mise.toml
  .base/activate.sh
  bin/base-demo-python-info
  bin/base-demo-services
  bin/base-demo-environments
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

grep -Fq -- '--branch v1.5.0' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not pin the Base checkout to v1.5.0.\n' >&2
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

grep -Fq 'Prepare Base runtime' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not prepare the Base runtime for Ubuntu CI.\n' >&2
  exit 1
}

grep -Fq 'python3 -m venv "$HOME/.base.d/base/.venv"' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not create the Base runtime venv for Ubuntu CI.\n' >&2
  exit 1
}

grep -Fq 'requirements-dev.txt' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not install the pinned Base Python requirements for Ubuntu CI.\n' >&2
  exit 1
}

if grep -Fq 'basectl setup base --no-notify --yes' .github/workflows/tests.yml; then
  printf '.github/workflows/tests.yml must not pass --yes to the pinned Base v1.5.0 setup command.\n' >&2
  exit 1
fi

grep -Fq 'basectl ci check base-demo --manifest ./base_manifest.yaml --format json' .github/workflows/tests.yml || {
  printf '.github/workflows/tests.yml does not run base-demo read-only CI JSON validation on Ubuntu.\n' >&2
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

grep -Fq 'print_var BASE_HOST' src/env.sh || {
  printf 'src/env.sh does not print BASE_HOST.\n' >&2
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

if command -v node >/dev/null 2>&1; then
  services/demo-console/build.sh || exit 1
else
  printf 'Skipping demo-console validation because node is not available.\n'
fi

for environment in dev staging prod; do
  grep -Fq "\"name\": \"$environment\"" "environments/$environment.json" || {
    printf 'environments/%s.json does not declare matching environment name.\n' "$environment" >&2
    exit 1
  }
done

grep -Fq 'REQUIRED_FIELDS = ("name", "mode", "operational", "base_url", "logging", "services", "infrastructure")' bin/base-demo-environments || {
  printf 'bin/base-demo-environments does not declare the expected environment schema fields.\n' >&2
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

grep -Fq 'ci check "$BASE_DEMO_PROJECT" --format json' demo/demo.sh || {
  printf 'demo/demo.sh does not include the basectl ci check JSON walkthrough step.\n' >&2
  exit 1
}

grep -Fq 'basectl ci check base-demo --format json' README.md || {
  printf 'README.md does not document the basectl ci check JSON command.\n' >&2
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

grep -Fq 'Ubuntu' README.md && grep -Fq 'read-only CI mode' README.md || {
  printf 'README.md does not document the Ubuntu/Linux read-only CI boundary.\n' >&2
  exit 1
}

grep -Fq 'docs/linux-support.md' README.md || {
  printf 'README.md does not reference Base docs/linux-support.md.\n' >&2
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

for contract in \
  project-baseline-required \
  http-health-url \
  non-interactive-demo \
  environment-schema \
  uv-runner-command \
  activation-owned-env \
  manifest-artifacts \
  runtime-platform-env \
  installer-checksum \
  service-log-permissions \
  ci-pinned-dependencies \
  ubuntu-ci \
  platform-boundary \
  ci-json-check
do
  grep -Fq "| \`$contract\` |" docs/contracts.md || {
    printf 'docs/contracts.md does not list contract %s.\n' "$contract" >&2
    exit 1
  }
done

grep -Fq 'BASE_OS' README.md && grep -Fq 'BASE_PLATFORM' README.md && grep -Fq 'BASE_HOST' README.md || {
  printf 'README.md does not document the env command BASE_OS/BASE_PLATFORM/BASE_HOST output.\n' >&2
  exit 1
}

grep -Fq 'BASE_OS' .ai-context/manifest.md && grep -Fq 'BASE_PLATFORM' .ai-context/manifest.md && grep -Fq 'BASE_HOST' .ai-context/manifest.md || {
  printf '.ai-context/manifest.md does not document the env command BASE_OS/BASE_PLATFORM/BASE_HOST output.\n' >&2
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

grep -Fq 'required_ports:' base_manifest.yaml && grep -Fq 'name: go-api' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the go-api required port health check.\n' >&2
  exit 1
}

grep -Fq 'python.requires_python' README.md || {
  printf 'README.md does not document python.requires_python.\n' >&2
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

grep -Fq 'build:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare build targets.\n' >&2
  exit 1
}

grep -Fq 'mise:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare mise configuration.\n' >&2
  exit 1
}

printf 'Repository baseline is present.\n'
