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
  run\ base-demo\ hello)
    printf 'hello from base-demo\n'
    printf 'BASE_PROJECT=base-demo\n'
    printf 'BASE_DEMO_ENV=%s\n' "${BASE_DEMO_ENV:-unset}"
    ;;
  test\ base-demo)
    printf 'Repository baseline is present.\n'
    ;;
  demo\ base-demo\ --dry-run\ --\ --non-interactive)
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
  [[ "$output" == *"BASE_DEMO_ENV=baseline"* ]]
  [[ "$output" == *"hello from base-demo"* ]]
  [[ "$output" == *"Repository baseline is present."* ]]
  [[ "$output" == *"base-demo walkthrough complete."* ]]
  grep -Fqx "basectl run base-demo hello" "$state_file"
  grep -Fqx "basectl test base-demo" "$state_file"
  grep -Fqx "basectl demo base-demo --dry-run -- --non-interactive" "$state_file"
}
