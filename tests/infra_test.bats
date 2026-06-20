#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-infra-test.XXXXXX")"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

write_fake_docker_without_compose_state() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/docker" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"ps --services --status running"* ]]; then
  exit 0
fi
if [[ "$*" == *"ps --services --all"* ]]; then
  exit 0
fi
exit 0
EOF
  chmod +x "$bin_dir/docker"
}

@test "compose infrastructure files and catalog entries are present" {
  [ -f "$TEST_ROOT/infra/compose.yaml" ]
  grep -Fq '"name": "postgres"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"name": "mysql"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"name": "redis"' "$TEST_ROOT/services/catalog.json"
}

@test "services status shows representative infrastructure" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"postgres"* ]]
  [[ "$output" == *"mysql"* ]]
  [[ "$output" == *"redis"* ]]
  [[ "$output" == *"database"* ]]
  [[ "$output" == *"cache"* ]]
}

@test "services start dry-run shows compose up command" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN docker compose"* ]]
  [[ "$output" == *"up -d postgres mysql redis"* ]]
}

@test "services stop dry-run shows compose stop command" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" stop

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN docker compose"* ]]
  [[ "$output" == *"stop postgres mysql redis go-api"* ]]
}

@test "services check does not require optional local infrastructure to be running" {
  write_fake_docker_without_compose_state "$TEST_TMPDIR/bin"
  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" PATH="$TEST_TMPDIR/bin:$PATH" "$TEST_ROOT/bin/base-demo-services" check

  [ "$status" -eq 0 ]
  [[ "$output" == *"project-baseline ok"* ]]
  [[ "$output" == *"postgres skip optional"* ]]
  [[ "$output" == *"mysql skip optional"* ]]
  [[ "$output" == *"redis skip optional"* ]]
}
