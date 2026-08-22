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

write_checkout_fixture() {
  local checkout_root="$1"
  mkdir -p "$checkout_root/environments" "$checkout_root/infra"
  cp "$TEST_ROOT/environments/dev.json" "$checkout_root/environments/dev.json"
  cp "$TEST_ROOT/environments/staging.json" "$checkout_root/environments/staging.json"
  cp "$TEST_ROOT/infra/compose.yaml" "$checkout_root/infra/compose.yaml"
}

compose_project_from_output() {
  sed -n 's/.* -p \([^ ]*\) .*/\1/p' | head -n 1
}

@test "compose infrastructure files and catalog entries are present" {
  [ -f "$TEST_ROOT/infra/compose.yaml" ]
  grep -Fq '"name": "postgres"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"name": "mysql"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"name": "redis"' "$TEST_ROOT/services/catalog.json"
}

@test "compose publishes every development port only on loopback" {
  [ "$(grep -Ec '^[[:space:]]+- "127\.0\.0\.1:[0-9]+:[0-9]+"$' "$TEST_ROOT/infra/compose.yaml")" -eq 4 ]
  ! grep -Eq '^[[:space:]]+- "[0-9]+:[0-9]+"$' "$TEST_ROOT/infra/compose.yaml"
}

@test "rendered compose configuration keeps every published port on loopback" {
  if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
    skip "docker compose is not available"
  fi

  run docker compose -f "$TEST_ROOT/infra/compose.yaml" config --format json
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" > "$TEST_TMPDIR/compose-config.json"

  run python3 - "$TEST_TMPDIR/compose-config.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    config = json.load(handle)

ports = [
    port
    for service in config["services"].values()
    for port in service.get("ports", [])
]
if len(ports) != 4 or any(port.get("host_ip") != "127.0.0.1" for port in ports):
    raise SystemExit("rendered Compose ports are not all loopback-only")
PY
  [ "$status" -eq 0 ]
}

@test "compose does not fix container names" {
  ! grep -Fq 'container_name:' "$TEST_ROOT/infra/compose.yaml"
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

@test "two checkout roots derive stable distinct compose projects" {
  local checkout_one="$TEST_TMPDIR/checkout-one"
  local checkout_two="$TEST_TMPDIR/checkout-two"
  local first_output second_output repeated_output first_project second_project repeated_project
  write_checkout_fixture "$checkout_one"
  write_checkout_fixture "$checkout_two"

  run env BASE_PROJECT_ROOT="$checkout_one" BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_ROOT/services/catalog.json" start
  [ "$status" -eq 0 ]
  first_output="$output"
  first_project="$(printf '%s\n' "$first_output" | compose_project_from_output)"

  run env BASE_PROJECT_ROOT="$checkout_two" BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_ROOT/services/catalog.json" start
  [ "$status" -eq 0 ]
  second_output="$output"
  second_project="$(printf '%s\n' "$second_output" | compose_project_from_output)"

  run env BASE_PROJECT_ROOT="$checkout_one" BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_ROOT/services/catalog.json" start
  [ "$status" -eq 0 ]
  repeated_output="$output"
  repeated_project="$(printf '%s\n' "$repeated_output" | compose_project_from_output)"

  [[ "$first_project" == base-demo-dev-* ]]
  [[ "$second_project" == base-demo-dev-* ]]
  [ "$first_project" != "$second_project" ]
  [ "$first_project" = "$repeated_project" ]

  run env BASE_PROJECT_ROOT="$checkout_one" BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_ROOT/services/catalog.json" stop
  [ "$status" -eq 0 ]
  [[ "$output" == *" -p $first_project stop postgres mysql redis go-api"* ]]

  run env BASE_PROJECT_ROOT="$checkout_two" BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_ROOT/services/catalog.json" logs
  [ "$status" -eq 0 ]
  [[ "$output" == *" -p $second_project logs --tail 50 postgres mysql redis go-api"* ]]
}

@test "compose project includes the active environment" {
  run "$TEST_ROOT/bin/base-demo-services" --env staging status

  [ "$status" -eq 0 ]
  [[ "$output" == *"compose_project=base-demo-staging-"* ]]
}

@test "compose project override scopes stop and logs for automation" {
  run env BASE_DEMO_COMPOSE_PROJECT=base-demo-ci BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" stop

  [ "$status" -eq 0 ]
  [[ "$output" == *" -p base-demo-ci stop postgres mysql redis go-api"* ]]

  run env BASE_DEMO_COMPOSE_PROJECT=base-demo-ci BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" logs

  [ "$status" -eq 0 ]
  [[ "$output" == *" -p base-demo-ci logs --tail 50 postgres mysql redis go-api"* ]]
}

@test "invalid compose project override fails before lifecycle effects" {
  run env BASE_DEMO_COMPOSE_PROJECT='Base Demo!' BASE_DEMO_SERVICES_DRY_RUN=1 \
    "$TEST_ROOT/bin/base-demo-services" start

  [ "$status" -eq 2 ]
  [[ "$output" == *"BASE_DEMO_COMPOSE_PROJECT must start with"* ]]
  [[ "$output" != *"DRY-RUN"* ]]
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
