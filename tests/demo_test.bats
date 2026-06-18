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

@test "demo script runs in non-interactive mode" {
  local fake_bin="$TEST_TMPDIR/bin"
  local state_file="$TEST_TMPDIR/state"

  mkdir -p "$fake_bin"
  cat > "$fake_bin/basectl" <<'EOF'
#!/usr/bin/env bash
printf 'basectl %s\n' "$*" >> "${BASE_DEMO_TEST_STATE:?}"
case "$*" in
  projects\ list\ --workspace\ *)
    printf 'PROJECT     PATH\n'
    printf 'base-demo   %s\n' "${BASE_PROJECT_ROOT:?}"
    ;;
  check\ base-demo)
    printf 'Base CLI environment check passed.\n'
    ;;
  doctor\ base-demo)
    printf 'Base doctor\n'
    printf 'ok     project base-demo is healthy.\n'
    ;;
  run\ base-demo\ --workspace\ *\ --list)
    printf 'hello       ./src/hello.sh\n'
    printf 'env         ./src/env.sh\n'
    printf 'manifest    ./src/manifest.sh\n'
    printf 'python-info ./bin/base-demo-python-info\n'
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
  run\ base-demo\ --workspace\ *\ services\ --\ status)
    printf 'environment=dev\n'
    printf 'mode=operational\n'
    printf 'NAME              KIND     RUNTIME  PORT  HEALTH                   STATE    SINCE  LOGS\n'
    printf 'project-baseline  project  base     -     file:base_manifest.yaml  healthy  -      -\n'
    printf 'postgres          database compose  5432  compose:postgres         stopped  -      docker compose logs postgres\n'
    printf 'mysql             database compose  3306  compose:mysql            stopped  -      docker compose logs mysql\n'
    printf 'redis             cache    compose  6379  compose:redis            stopped  -      docker compose logs redis\n'
    printf 'go-api            service  docker   8010  http://127.0.0.1:8010/healthz stopped  -      docker compose logs go-api\n'
    ;;
  run\ base-demo\ --workspace\ *\ environments\ --\ list)
    printf 'NAME     MODE         OPERATIONAL  BASE_URL\n'
    printf 'dev      operational  true         http://127.0.0.1\n'
    printf 'staging  modeled      false        https://staging.base-demo.example.invalid\n'
    printf 'prod     modeled      false        https://base-demo.example.invalid\n'
    ;;
  test\ base-demo\ --workspace\ *)
    printf 'Repository baseline is present.\n'
    ;;
  build\ base-demo\ --workspace\ *\ --list)
    printf 'info   Print project build info.\n'
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
  [[ "$output" == *"Project Diagnostics"* ]]
  [[ "$output" == *"Declared Commands"* ]]
  [[ "$output" == *"services    ./bin/base-demo-services"* ]]
  [[ "$output" == *"environments ./bin/base-demo-environments"* ]]
  [[ "$output" == *"Inspection Commands"* ]]
  [[ "$output" == *"BASE_DEMO_ENV=baseline"* ]]
  [[ "$output" == *"BASE_DEMO_PROJECT_KIND=reference-demo"* ]]
  [[ "$output" == *"hello from base-demo"* ]]
  [[ "$output" == *"base-demo manifest"* ]]
  [[ "$output" == *"base-demo python cli"* ]]
  [[ "$output" == *"project-baseline"* ]]
  [[ "$output" == *"postgres"* ]]
  [[ "$output" == *"mysql"* ]]
  [[ "$output" == *"redis"* ]]
  [[ "$output" == *"go-api"* ]]
  [[ "$output" == *"8010"* ]]
  [[ "$output" == *"healthy"* ]]
  [[ "$output" == *"staging"* ]]
  [[ "$output" == *"modeled"* ]]
  [[ "$output" == *"Repository baseline is present."* ]]
  [[ "$output" == *"Build Targets"* ]]
  [[ "$output" == *"project=base-demo"* ]]
  [[ "$output" == *"base-demo walkthrough complete."* ]]
  grep -Fq "basectl projects list --workspace " "$state_file"
  grep -Fqx "basectl check base-demo" "$state_file"
  grep -Fqx "basectl doctor base-demo" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ --list$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ hello$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ env$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ manifest$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ python-info$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ services -- status$" "$state_file"
  grep -Eq "^basectl run base-demo --workspace .+ environments -- list$" "$state_file"
  grep -Eq "^basectl test base-demo --workspace .+$" "$state_file"
  grep -Eq "^basectl build base-demo --workspace .+ --list$" "$state_file"
  grep -Eq "^basectl build base-demo --workspace .+$" "$state_file"
  grep -Eq "^basectl demo base-demo --workspace .+ --dry-run -- --non-interactive$" "$state_file"
}
