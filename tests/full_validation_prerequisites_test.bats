#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
}

@test "full validation fails clearly when Go and Java are absent" {
  run env PATH="$BATS_TEST_TMPDIR" /bin/bash "$TEST_ROOT/tests/full_validation_prerequisites.sh"

  [ "$status" -eq 1 ]
  [[ "$output" == *"missing: go javac"* ]]
}
