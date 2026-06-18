#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-services-test.XXXXXX")"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
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
  run "$TEST_ROOT/bin/base-demo-services" check

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
