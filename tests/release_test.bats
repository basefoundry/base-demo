#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-release-test.XXXXXX")"
  TEST_REPO="$TEST_TMPDIR/repo"
  mkdir -p "$TEST_REPO"
  git -C "$TEST_REPO" init -q -b main
  git -C "$TEST_REPO" config user.email test@example.invalid
  git -C "$TEST_REPO" config user.name "Release Test"
  printf 'reviewed\n' > "$TEST_REPO/README"
  git -C "$TEST_REPO" add README
  git -C "$TEST_REPO" commit -q -m "reviewed release commit"
  TEST_MAIN_COMMIT="$(git -C "$TEST_REPO" rev-parse HEAD)"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "accepts an annotated tag whose target is reachable from main" {
  git -C "$TEST_REPO" tag -a v1.0.0 -m "release" "$TEST_MAIN_COMMIT"

  run "$TEST_ROOT/bin/base-demo-release-provenance" --repo "$TEST_REPO" --main-ref main v1.0.0 "$TEST_MAIN_COMMIT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"release provenance is valid"* ]]
}

@test "rejects a lightweight tag" {
  git -C "$TEST_REPO" tag v1.0.1 "$TEST_MAIN_COMMIT"

  run "$TEST_ROOT/bin/base-demo-release-provenance" --repo "$TEST_REPO" --main-ref main v1.0.1 "$TEST_MAIN_COMMIT"

  [ "$status" -ne 0 ]
  [[ "$output" == *"lightweight"* ]]
}

@test "rejects an annotated tag detached from main" {
  git -C "$TEST_REPO" checkout -q --orphan unreviewed
  git -C "$TEST_REPO" rm -q -rf .
  printf 'unreviewed\n' > "$TEST_REPO/README"
  git -C "$TEST_REPO" add README
  git -C "$TEST_REPO" commit -q -m "unreviewed release commit"
  detached_commit="$(git -C "$TEST_REPO" rev-parse HEAD)"
  git -C "$TEST_REPO" tag -a v1.0.2 -m "release" "$detached_commit"

  run "$TEST_ROOT/bin/base-demo-release-provenance" --repo "$TEST_REPO" --main-ref main v1.0.2 "$detached_commit"

  [ "$status" -ne 0 ]
  [[ "$output" == *"not reachable"* ]]
}

@test "release identity check rejects a mismatched version tag" {
  run "$TEST_ROOT/bin/base-demo-release-check" v9.9.9

  [ "$status" -ne 0 ]
  [[ "$output" == *"does not match VERSION"* ]]
}
