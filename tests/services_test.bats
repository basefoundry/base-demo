#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-services-test.XXXXXX")"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

write_optional_file_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "optional-file",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "lifecycle": {
        "type": "process",
        "command": [
          "python3",
          "-c",
          "import time; time.sleep(60)"
        ]
      },
      "check": {
        "type": "file",
        "path": "missing.optional"
      },
      "logs": "var/services/optional-file.log"
    }
  ]
}
EOF
}

write_optional_compose_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "optional-compose",
      "kind": "service",
      "runtime": "compose",
      "port": null,
      "health_url": null,
      "required": false,
      "compose_service": "optional-compose",
      "check": {
        "type": "compose",
        "service": "optional-compose"
      },
      "logs": "docker compose logs optional-compose"
    }
  ]
}
EOF
}

write_missing_http_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "missing-http",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "check": {
        "type": "http"
      },
      "logs": null
    }
  ]
}
EOF
}

write_fake_docker_with_stopped_compose_service() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/docker" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"ps --services --status running"* ]]; then
  exit 0
fi
if [[ "$*" == *"ps --services --all"* ]]; then
  printf 'optional-compose\n'
  exit 0
fi
exit 0
EOF
  chmod +x "$bin_dir/docker"
}

@test "services command is declared and executable" {
  grep -Fq "services: ./bin/base-demo-services" "$TEST_ROOT/base_manifest.yaml"
  [ -x "$TEST_ROOT/bin/base-demo-services" ]
  [ -f "$TEST_ROOT/services/catalog.json" ]
}

@test "services status shows catalog entries" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"NAME"* ]]
  [[ "$output" == *"project-baseline"* ]]
  [[ "$output" == *"project"* ]]
  [[ "$output" == *"base"* ]]
  [[ "$output" == *"healthy"* ]]
}

@test "services check passes for healthy required entries" {
  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" check

  [ "$status" -eq 0 ]
  [[ "$output" == *"project-baseline ok"* ]]
}

@test "services check fails for unhealthy required entries" {
  local catalog="$TEST_TMPDIR/catalog.json"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "missing-required",
      "kind": "service",
      "runtime": "test",
      "port": 9999,
      "health_url": null,
      "required": true,
      "check": {
        "type": "file",
        "path": "missing.file"
      },
      "logs": null
    }
  ]
}
EOF

  run "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" check

  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-required fail"* ]]
  [[ "$output" == *"file:missing.file"* ]]
}

@test "services status keeps never-started optional services stopped" {
  local catalog="$TEST_TMPDIR/catalog.json"
  write_optional_file_catalog "$catalog"

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"optional-file"*"stopped"* ]]
  [[ "$output" != *"optional-file"*"error"* ]]
}

@test "services status marks started optional services with failing checks as error" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  write_optional_file_catalog "$catalog"
  mkdir -p "$state_dir"
  cat > "$state_dir/optional-file.json" <<EOF
{
  "pid": 999999,
  "started_at": "2026-06-20T12:00:00+00:00",
  "command": ["python3", "-c", "import time; time.sleep(60)"],
  "log": "$state_dir/optional-file.log"
}
EOF

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"optional-file"*"error"*"2026-06-20T12:00:00+00:00"* ]]
}

@test "services check reports started optional service errors" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  write_optional_file_catalog "$catalog"
  mkdir -p "$state_dir"
  cat > "$state_dir/optional-file.json" <<EOF
{
  "pid": 999999,
  "started_at": "2026-06-20T12:00:00+00:00",
  "command": ["python3", "-c", "import time; time.sleep(60)"],
  "log": "$state_dir/optional-file.log"
}
EOF

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" check

  [ "$status" -eq 1 ]
  [[ "$output" == *"optional-file error file:missing.optional"* ]]
}

@test "services status marks optional compose services with existing state as error" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local fake_bin="$TEST_TMPDIR/bin"
  write_optional_compose_catalog "$catalog"
  write_fake_docker_with_stopped_compose_service "$fake_bin"

  run env PATH="$fake_bin:$PATH" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"optional-compose"*"error"* ]]
}

@test "services status and check use the same missing http target detail" {
  local catalog="$TEST_TMPDIR/catalog.json"
  write_missing_http_catalog "$catalog"

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"missing-http"*"http:<missing health_url>"* ]]

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" check

  [ "$status" -eq 0 ]
  [[ "$output" == *"missing-http skip optional http:<missing health_url>"* ]]
}
