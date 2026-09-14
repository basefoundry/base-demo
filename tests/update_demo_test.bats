#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-update-test.XXXXXX")"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

new_git_repo() {
  local repo="$1"

  git init --quiet "$repo"
  git -C "$repo" config user.email test@example.invalid
  git -C "$repo" config user.name 'Base Demo Test'
  printf 'fixture\n' > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit --quiet -m fixture
  git -C "$repo" branch -M main
  git -C "$repo" remote add origin "$repo"
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
}

run_update_preview_reason() {
  local repo="$1"

  run env \
    DEMO_SCRIPT_ROOT="$TEST_ROOT" \
    TEST_UPDATE_ROOT="$repo" \
    bash -c "source \"\$DEMO_SCRIPT_ROOT/demo/demo.sh\"; BASE_DEMO_ROOT=\"\$TEST_UPDATE_ROOT\"; update_preview_reason"
}

@test "update preview is eligible on a clean default branch" {
  local repo="$TEST_TMPDIR/default-branch"

  new_git_repo "$repo"
  run_update_preview_reason "$repo"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "update preview is skipped from a detached checkout" {
  local repo="$TEST_TMPDIR/detached"

  new_git_repo "$repo"
  git -C "$repo" checkout --quiet --detach HEAD
  run_update_preview_reason "$repo"

  [ "$status" -eq 1 ]
  [[ "$output" == *"not provably on its default branch"* ]]
}

@test "update preview is skipped when tracked files are modified" {
  local repo="$TEST_TMPDIR/dirty"

  new_git_repo "$repo"
  printf 'modified\n' >> "$repo/README.md"
  run_update_preview_reason "$repo"

  [ "$status" -eq 1 ]
  [[ "$output" == *"tracked files are modified"* ]]
}
