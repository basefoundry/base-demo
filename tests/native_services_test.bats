#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-native-services-test.XXXXXX")"
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

@test "native service files and catalog entries are present" {
  [ -f "$TEST_ROOT/services/c-service/Makefile" ]
  [ -f "$TEST_ROOT/services/c-service/main.c" ]
  [ -x "$TEST_ROOT/services/c-service/build.sh" ]
  [ -x "$TEST_ROOT/services/c-service/test.sh" ]
  [ -x "$TEST_ROOT/services/c-service/run.sh" ]

  [ -f "$TEST_ROOT/services/cpp-service/Makefile" ]
  [ -f "$TEST_ROOT/services/cpp-service/main.cpp" ]
  [ -x "$TEST_ROOT/services/cpp-service/build.sh" ]
  [ -x "$TEST_ROOT/services/cpp-service/test.sh" ]
  [ -x "$TEST_ROOT/services/cpp-service/run.sh" ]

  grep -Fq '"name": "c-service"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"port": 8050' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"name": "cpp-service"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"port": 8060' "$TEST_ROOT/services/catalog.json"
}

@test "services status shows native service fixtures" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"c-service"* ]]
  [[ "$output" == *"native-c"* ]]
  [[ "$output" == *"8050"* ]]
  [[ "$output" == *"cpp-service"* ]]
  [[ "$output" == *"native-cpp"* ]]
  [[ "$output" == *"8060"* ]]
}

@test "services lifecycle dry-run includes native process commands" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN start c-service"* ]]
  [[ "$output" == *"services/c-service/run.sh"* ]]
  [[ "$output" == *"DRY-RUN start cpp-service"* ]]
  [[ "$output" == *"services/cpp-service/run.sh"* ]]
}

@test "native service build scripts and command health checks pass" {
  run "$TEST_ROOT/services/c-service/build.sh"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/services/c-service/test.sh"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/services/cpp-service/build.sh"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/services/cpp-service/test.sh"
  [ "$status" -eq 0 ]

  write_fake_docker_without_compose_state "$TEST_TMPDIR/bin"
  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" PATH="$TEST_TMPDIR/bin:$PATH" "$TEST_ROOT/bin/base-demo-services" check
  [ "$status" -eq 0 ]
  [[ "$output" == *"c-service ok"* ]]
  [[ "$output" == *"cpp-service ok"* ]]
}
