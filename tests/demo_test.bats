#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-test.XXXXXX")"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "demo script is declared and executable" {
  grep -Fq "script: ./demo/demo.sh" "$TEST_ROOT/base_manifest.yaml"
  [ -x "$TEST_ROOT/demo/demo.sh" ]
}

@test "demo script prints help" {
  run "$TEST_ROOT/demo/demo.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Run the base-demo interactive walkthrough."* ]]
}

@test "demo script exits nonzero when a step validation fails" {
  local fake_bin="$TEST_TMPDIR/bin"

  mkdir -p "$fake_bin"
  cat > "$fake_bin/basectl" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  repo\ check\ .)
    printf 'Repository baseline: all 12 required files present.\n'
    ;;
  projects\ list\ --workspace\ *)
    printf 'PROJECT     PATH\n'
    printf 'other-demo  /tmp/other-demo\n'
    ;;
  *)
    printf 'unexpected basectl args: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$fake_bin/basectl"

  run env \
    BASE_PROJECT=base-demo \
    BASE_PROJECT_ROOT="$TEST_ROOT" \
    BASE_DEMO_BASECTL="$fake_bin/basectl" \
    "$TEST_ROOT/demo/demo.sh" --non-interactive

  [ "$status" -ne 0 ]
  [[ "$output" == *"Workspace Discovery"* ]]
  [[ "$output" != *"base-demo walkthrough complete."* ]]
}

@test "demo script runs in non-interactive mode" {
  local fake_bin="$TEST_TMPDIR/bin"
  local state_file="$TEST_TMPDIR/state"

  mkdir -p "$fake_bin"
  cat > "$fake_bin/basectl" <<'EOF'
#!/usr/bin/env bash
printf 'basectl %s\n' "$*" >> "${BASE_DEMO_TEST_STATE:?}"
case "$*" in
  repo\ check\ .)
    printf 'Repository baseline: all 12 required files present.\n'
    ;;
  projects\ list\ --workspace\ *)
    printf 'PROJECT     PATH\n'
    printf 'base-demo   %s\n' "${BASE_PROJECT_ROOT:?}"
    ;;
  setup\ base-demo\ --manifest\ *\ --dry-run\ --no-notify)
    printf '[DRY-RUN] Would reconcile base_manifest.yaml, Brewfile, mise, project virtualenv, and bats-core artifact.\n'
    ;;
  check\ base-demo\ --manifest\ *)
    printf 'Base CLI environment check passed.\n'
    ;;
  doctor\ base-demo\ --manifest\ *)
    printf 'Base doctor\n'
    printf 'ok     project base-demo is healthy.\n'
    ;;
  run\ base-demo\ --workspace\ *\ --list)
    printf 'hello       ./src/hello.sh\n'
    printf 'env         ./src/env.sh\n'
    printf 'manifest    ./src/manifest.sh\n'
    printf 'python-info ./bin/base-demo-python-info\n'
    printf 'uv-info     uv run -- python src/uv-info.py\n'
    printf 'services    ./bin/base-demo-services\n'
    printf 'environments ./bin/base-demo-environments\n'
    ;;
  run\ base-demo\ --workspace\ *\ hello)
    printf 'hello from base-demo\n'
    printf 'BASE_PROJECT=base-demo\n'
    printf 'BASE_DEMO_ENV=%s\n' "${BASE_DEMO_ENV:-unset}"
    ;;
  run\ base-demo\ --workspace\ *\ env)
    printf 'BASE_PROJECT=base-demo\n'
    printf 'BASE_DEMO_PROJECT_KIND=%s\n' "${BASE_DEMO_PROJECT_KIND:-unset}"
    ;;
  run\ base-demo\ --workspace\ *\ manifest)
    printf 'base-demo manifest\n'
    printf 'commands:\n'
    ;;
  run\ base-demo\ --workspace\ *\ python-info)
    printf 'base-demo python cli\n'
    printf 'BASE_PROJECT=base-demo\n'
    ;;
  run\ base-demo\ --workspace\ *\ uv-info)
    printf 'base-demo uv runner\n'
    printf 'python=3.13\n'
    ;;
  run\ base-demo\ --workspace\ *\ services\ --\ status)
    printf 'environment=dev\n'
    printf 'mode=operational\n'
    printf 'NAME              KIND     RUNTIME  PORT  HEALTH                   STATE    SINCE  LOGS\n'
    printf 'project-baseline  project  base     -     file:base_manifest.yaml  healthy  -      -\n'
    printf 'postgres          database compose  5432  compose:postgres         stopped  -      docker compose logs postgres\n'
    printf 'mysql             database compose  3306  compose:mysql            stopped  -      docker compose logs mysql\n'
    printf 'redis             cache    compose  6379  compose:redis            stopped  -      docker compose logs redis\n'
    printf 'go-api            service  docker   8010  http://127.0.0.1:8010/healthz stopped  -      docker compose logs go-api\n'
    printf 'python-api        service  python   8020  http://127.0.0.1:8020/healthz stopped  -      var/services/python-api.log\n'
    printf 'java-gradle-api   service  java-gradle 8030 http://127.0.0.1:8030/healthz stopped  -      var/services/java-gradle-api.log\n'
    printf 'java-maven-api    service  java-maven 8040 http://127.0.0.1:8040/healthz stopped  -      var/services/java-maven-api.log\n'
    printf 'c-service         service  native-c 8050 command:./services/c-service/build/c-service --healthz stopped - var/services/c-service.log\n'
    printf 'cpp-service       service  native-cpp 8060 command:./services/cpp-service/build/cpp-service --healthz stopped - var/services/cpp-service.log\n'
    printf 'demo-console      ui       react-vite 8070 http://127.0.0.1:8070 stopped - var/services/demo-console.log\n'
    ;;
  run\ base-demo\ --workspace\ *\ services\ --\ check)
    printf 'project-baseline ok\n'
    printf 'postgres skip optional compose:postgres unavailable\n'
    printf 'mysql skip optional compose:mysql unavailable\n'
    printf 'redis skip optional compose:redis unavailable\n'
    printf 'go-api skip optional http:http://127.0.0.1:8010/healthz\n'
    printf 'python-api skip optional http:http://127.0.0.1:8020/healthz\n'
    printf 'java-gradle-api skip optional http:http://127.0.0.1:8030/healthz\n'
    printf 'java-maven-api skip optional http:http://127.0.0.1:8040/healthz\n'
    printf 'c-service ok\n'
    printf 'cpp-service ok\n'
    printf 'demo-console ok\n'
    ;;
  run\ base-demo\ --workspace\ *\ services\ --\ start)
    printf 'DRY-RUN docker compose -f infra/compose.yaml -p base-demo up -d postgres mysql redis go-api\n'
    printf 'DRY-RUN start python-api: python3 services/python-api/server.py\n'
    printf 'DRY-RUN start java-gradle-api: ./services/java-gradle-api/run.sh\n'
    printf 'DRY-RUN start java-maven-api: ./services/java-maven-api/run.sh\n'
    printf 'DRY-RUN start c-service: ./services/c-service/run.sh\n'
    printf 'DRY-RUN start cpp-service: ./services/cpp-service/run.sh\n'
    printf 'DRY-RUN start demo-console: ./services/demo-console/run.sh\n'
    ;;
  run\ base-demo\ --workspace\ *\ environments\ --\ list)
    printf 'NAME     MODE         OPERATIONAL  BASE_URL\n'
    printf 'dev      operational  true         http://127.0.0.1\n'
    printf 'staging  modeled      false        https://staging.base-demo.example.invalid\n'
    printf 'prod     modeled      false        https://base-demo.example.invalid\n'
    ;;
  run\ base-demo\ --workspace\ *\ environments\ --\ validate\ --all)
    printf 'dev ok\n'
    printf 'staging ok\n'
    printf 'prod ok\n'
    ;;
  test\ base-demo\ --workspace\ *)
    printf 'Repository baseline is present.\n'
    ;;
  build\ base-demo\ --workspace\ *\ --list)
    printf 'info   Print project build info.\n'
    printf 'go-api Build the Go API service.\n'
    printf 'python-api Validate the Python API service.\n'
    printf 'java-gradle-api Build the Java Gradle API service.\n'
    printf 'java-maven-api Build the Java Maven API service.\n'
    printf 'c-service Build the native C service.\n'
    printf 'cpp-service Build the native C++ service.\n'
    printf 'demo-console Build the React/Vite demo console.\n'
    ;;
  build\ base-demo\ python-api\ --workspace\ *)
    printf 'python-api build target validated\n'
    ;;
  build\ base-demo\ --workspace\ *)
    printf 'project=base-demo\n'
    printf 'version=0.1.0\n'
    printf 'build-target=info\n'
    ;;
  demo\ base-demo\ --workspace\ *\ --dry-run\ --\ --non-interactive)
    printf '[DRY-RUN] Would run demo for project base-demo.\n'
    ;;
  *)
    printf 'unexpected basectl args: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$fake_bin/basectl"

  run env \
    BASE_PROJECT=base-demo \
    BASE_PROJECT_ROOT="$TEST_ROOT" \
    BASE_DEMO_BASECTL="$fake_bin/basectl" \
    BASE_DEMO_TEST_STATE="$state_file" \
    "$TEST_ROOT/demo/demo.sh" --non-interactive

  [ "$status" -eq 0 ]
  [[ "$output" == *"base-demo Walkthrough"* ]]
  [[ "$output" == *"Workspace Discovery"* ]]
  [[ "$output" == *"Setup Contract"* ]]
  [[ "$output" == *"bats-core"* ]]
  [[ "$output" == *"required_ports:"* ]]
  [[ "$output" == *"requires_python:"* ]]
  [[ "$output" == *"working_dir: services/go-api"* ]]
  [[ "$output" == *"uv-info:"* ]]
  [[ "$output" == *"runner: uv"* ]]
  [[ "$output" == *"Project Diagnostics"* ]]
  [[ "$output" == *"post-activation green path"* ]]
  [[ "$output" == *"Declared Commands"* ]]
  [[ "$output" == *"services    ./bin/base-demo-services"* ]]
  [[ "$output" == *"environments ./bin/base-demo-environments"* ]]
  [[ "$output" == *"uv-info     uv run -- python src/uv-info.py"* ]]
  [[ "$output" == *"Inspection Commands"* ]]
  [[ "$output" == *"Inspecting activation and manifest environment values."* ]]
  [[ "$output" == *"Reading the manifest summary command."* ]]
  [[ "$output" == *"Checking representative service health."* ]]
  [[ "$output" == *"Representative Environment"* ]]
  [[ "$output" == *"Dry-running service startup without launching dependencies."* ]]
  [[ "$output" == *"DRY-RUN docker compose"* ]]
  [[ "$output" == *"c-service ok"* ]]
  [[ "$output" == *"cpp-service ok"* ]]
  [[ "$output" == *"demo-console ok"* ]]
  [[ "$output" == *"dev ok"* ]]
  [[ "$output" == *"prod ok"* ]]
  [[ "$output" == *"BASE_DEMO_ENV=baseline"* ]]
  [[ "$output" == *"BASE_DEMO_PROJECT_KIND=reference-demo"* ]]
  [[ "$output" == *"hello from base-demo"* ]]
  [[ "$output" == *"base-demo manifest"* ]]
  [[ "$output" == *"base-demo python cli"* ]]
  [[ "$output" == *"base-demo uv runner"* ]]
  [[ "$output" == *"project-baseline"* ]]
  [[ "$output" == *"postgres"* ]]
  [[ "$output" == *"mysql"* ]]
  [[ "$output" == *"redis"* ]]
  [[ "$output" == *"go-api"* ]]
  [[ "$output" == *"python-api"* ]]
  [[ "$output" == *"java-gradle-api"* ]]
  [[ "$output" == *"java-maven-api"* ]]
  [[ "$output" == *"c-service"* ]]
  [[ "$output" == *"cpp-service"* ]]
  [[ "$output" == *"demo-console"* ]]
  [[ "$output" == *"8010"* ]]
  [[ "$output" == *"8020"* ]]
  [[ "$output" == *"8030"* ]]
  [[ "$output" == *"8040"* ]]
  [[ "$output" == *"8050"* ]]
  [[ "$output" == *"8060"* ]]
  [[ "$output" == *"8070"* ]]
  [[ "$output" == *"healthy"* ]]
  [[ "$output" == *"staging"* ]]
  [[ "$output" == *"modeled"* ]]
  [[ "$output" == *"Repository baseline is present."* ]]
  [[ "$output" == *"Build Targets"* ]]
  [[ "$output" == *"project=base-demo"* ]]
  [[ "$output" == *"python-api build target validated"* ]]
  [[ "$output" == *"Manifest fields exercised:"* ]]
  [[ "$output" == *"docs/representative-environment.md"* ]]
  [[ "$output" == *"banyanlabs"* ]]
  [[ "$output" == *"base-demo walkthrough complete."* ]]
  grep -Eq "^basectl repo check \\.$" "$state_file"
  grep -Fq "basectl projects list --workspace " "$state_file"
  grep -Eq "^basectl setup base-demo --manifest .+/base_manifest.yaml --dry-run --no-notify$" "$state_file"
  grep -Eq "^basectl check base-demo --manifest .+/base_manifest.yaml$" "$state_file"
  grep -Eq "^basectl doctor base-demo --manifest .+/base_manifest.yaml$" "$state_file"
  [ "$(grep -Ec "^basectl check base-demo --manifest .+/base_manifest.yaml$" "$state_file")" -eq 2 ]
  [ "$(grep -Ec "^basectl doctor base-demo --manifest .+/base_manifest.yaml$" "$state_file")" -eq 2 ]
  grep -Eq "^basectl run base-demo --workspace .+ --list$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ hello$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ env$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ manifest$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ python-info$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ uv-info$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ services -- status$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ services -- check$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ services -- start$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ environments -- list$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ environments -- validate --all$" "$state_file"
  grep -Eq "^basectl test base-demo --workspace .+$" "$state_file"
  grep -Eq "^basectl build base-demo --workspace .+ --list$" "$state_file"
  grep -Eq "^basectl build base-demo --workspace .+$" "$state_file"
  grep -Eq "^basectl build base-demo python-api --workspace .+$" "$state_file"
  grep -Eq "^basectl demo base-demo --workspace .+ --dry-run -- --non-interactive$" "$state_file"
}
