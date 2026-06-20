#!/usr/bin/env bash

required_files=(
  README.md
  VERSION
  CHANGELOG.md
  CONTRIBUTING.md
  AGENTS.md
  skills.md
  LICENSE
  install.sh
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
  lib/python/base_demo_cli/__init__.py
  lib/python/base_demo_cli/__main__.py
  demo/demo.sh
  tests/demo_test.bats
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

for executable in tests/validate.sh install.sh .base/activate.sh bin/base-demo-python-info bin/base-demo-services bin/base-demo-environments src/hello.sh src/env.sh src/manifest.sh src/build-info.sh services/go-api/build.sh services/python-api/server.py services/python-api/build.sh services/python-api/test.sh services/java-gradle-api/build.sh services/java-gradle-api/test.sh services/java-gradle-api/run.sh services/java-maven-api/build.sh services/java-maven-api/test.sh services/java-maven-api/run.sh services/c-service/build.sh services/c-service/test.sh services/c-service/run.sh services/cpp-service/build.sh services/cpp-service/test.sh services/cpp-service/run.sh services/demo-console/build.sh services/demo-console/test.sh services/demo-console/run.sh demo/demo.sh; do
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

grep -Fq 'hello: ./src/hello.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the hello command.\n' >&2
  exit 1
}

grep -Fq 'env: ./src/env.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the env command.\n' >&2
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

grep -Fq 'required_env:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare health.required_env.\n' >&2
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

grep -Fq 'Brewfile currently installs mise, Gradle, and Maven' README.md || {
  printf 'README.md does not document current Brewfile dependencies.\n' >&2
  exit 1
}

grep -Fq 'currently includes mise, Gradle, and Maven' .ai-context/manifest.md || {
  printf '.ai-context/manifest.md does not document current Brewfile dependencies.\n' >&2
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
