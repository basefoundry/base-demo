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

resolve_release_commit() {
  local repo_dir="$1"
  local repo_url="$2"
  local release_ref="$3"
  local commit

  if commit="$(git -C "$repo_dir" rev-parse --verify "${release_ref}^{commit}" 2>/dev/null)"; then
    printf '%s\n' "$commit"
    return 0
  fi

  # A peeled tag ref returns the commit targeted by an annotated tag, while
  # an unpeeled tag ref returns the tag object SHA. This keeps the check valid
  # in shallow CI checkouts that do not contain the historical release tag.
  git ls-remote "$repo_url" "refs/tags/${release_ref}^{}" \
    | awk 'NR == 1 { print $1; found = 1 } END { if (!found) exit 1 }'
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

@test "install release pins resolve refs to their target commits" {
  project_ref="$(sed -n 's/^PROJECT_RELEASE_REF="${PROJECT_RELEASE_REF:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"
  project_pin="$(sed -n 's/^PROJECT_RELEASE_COMMIT="${PROJECT_RELEASE_COMMIT:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"
  base_ref="$(sed -n 's/^BASE_RELEASE_REF="${BASE_RELEASE_REF:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"
  base_pin="$(sed -n 's/^BASE_RELEASE_COMMIT="${BASE_RELEASE_COMMIT:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"

  [ -n "$project_ref" ]
  [ -n "$project_pin" ]
  [ -n "$base_ref" ]
  [ -n "$base_pin" ]

  run resolve_release_commit "$TEST_ROOT" "${PROJECT_REPO_URL:-https://github.com/basefoundry/base-demo.git}" "$project_ref"
  [ "$status" -eq 0 ]
  [ "$output" = "$project_pin" ]

  run resolve_release_commit "$TEST_ROOT/../base" "${BASE_REPO_URL:-https://github.com/basefoundry/base.git}" "$base_ref"
  [ "$status" -eq 0 ]
  [ "$output" = "$base_pin" ]
}
