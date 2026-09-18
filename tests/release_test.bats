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

@test "release BOM gate does not certify the historical prepared record" {
  run "$TEST_ROOT/bin/base-demo-release-bom-check"

  [ "$status" -ne 0 ]
  [[ "$output" == *"release BOM check:"* ]]
}

@test "release BOM row emits immutable demo identity" {
  output_path="$TEST_TMPDIR/demo-row.json"
  run "$TEST_ROOT/bin/base-demo-release-bom-row" \
    --version 0.2.0 \
    --commit aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
    --platform ubuntu-24.04 \
    --evidence run://base-demo/validation \
    --output "$output_path"

  [ "$status" -eq 0 ]
  run python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["repository"] == "basefoundry/base-demo"; assert d["tag"] == "v0.2.0"; assert d["required"] is True' "$output_path"
  [ "$status" -eq 0 ]
}

@test "release finalizer binds the BOM and installer to the reviewed tag target" {
  mkdir -p "$TEST_REPO/.release"
  cp "$TEST_ROOT/VERSION" "$TEST_REPO/VERSION"
  cp "$TEST_ROOT/install.sh" "$TEST_REPO/install.sh"
  cp "$TEST_ROOT/.release/release-bom.json" "$TEST_REPO/.release/release-bom.json"
  original_installer_sha="$(shasum -a 256 "$TEST_REPO/install.sh" | awk '{print $1}')"
  original_bom_sha="$(shasum -a 256 "$TEST_REPO/.release/release-bom.json" | awk '{print $1}')"
  git -C "$TEST_REPO" add VERSION install.sh .release/release-bom.json
  git -C "$TEST_REPO" commit -q -m "prepare release inputs"
  target_commit="$(git -C "$TEST_REPO" rev-parse HEAD)"
  git -C "$TEST_REPO" tag -a v0.1.0 -m "base-demo v0.1.0" "$target_commit"
  output_dir="$TEST_TMPDIR/finalized"

  run "$TEST_ROOT/bin/base-demo-release-provenance" \
    --repo "$TEST_REPO" \
    --main-ref main \
    v0.1.0 \
    "$target_commit"

  [ "$status" -eq 0 ]
  run "$TEST_ROOT/bin/base-demo-release-finalize" \
    --repo "$TEST_REPO" \
    --commit "$target_commit" \
    --output-dir "$output_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"v0.1.0"* ]]
  run python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    document = json.load(handle)
assert document["release"]["commit"] == sys.argv[2]
rows = [
    row for row in document["components"]
    if row["repository"] == "basefoundry/base-demo"
]
assert len(rows) == 1 and rows[0]["commit"] == sys.argv[2]
' "$output_dir/release-bom.json" "$target_commit"
  [ "$status" -eq 0 ]
  grep -Fq 'PROJECT_RELEASE_REF="${PROJECT_RELEASE_REF:-v0.1.0}"' "$output_dir/install.sh"
  grep -Fq "PROJECT_RELEASE_COMMIT=\"\${PROJECT_RELEASE_COMMIT:-$target_commit}\"" "$output_dir/install.sh"
  [ -x "$output_dir/install.sh" ]
  [ "$(shasum -a 256 "$TEST_REPO/install.sh" | awk '{print $1}')" = "$original_installer_sha" ]
  [ "$(shasum -a 256 "$TEST_REPO/.release/release-bom.json" | awk '{print $1}')" = "$original_bom_sha" ]

  run env \
    BASE_DEMO_RELEASE_BOM_PATH="$output_dir/release-bom.json" \
    BASE_DEMO_RELEASE_BOM_EXPECTED_COMMIT="$target_commit" \
    "$TEST_ROOT/bin/base-demo-release-bom-check"

  # Finalizing identity does not turn historical release:// placeholders into
  # fresh passing evidence. The positive finalized gate lives in the Python suite.
  [ "$status" -ne 0 ]
  [[ "$output" == *"release BOM check:"* ]]

  run bash -c 'cd "$1" && shasum -a 256 -c release-bom.sha256 install.sh.sha256' _ "$output_dir"
  [ "$status" -eq 0 ]
  run "$TEST_ROOT/bin/base-demo-release-finalize" \
    --repo "$TEST_REPO" \
    --commit "$target_commit" \
    --verify-dir "$output_dir"
  [ "$status" -eq 0 ] || { printf 'unexpected verifier output: %s\n' "$output"; false; }

  printf '# modified after verification\n' >> "$output_dir/install.sh"
  run "$TEST_ROOT/bin/base-demo-release-finalize" \
    --repo "$TEST_REPO" \
    --commit "$target_commit" \
    --verify-dir "$output_dir"
  [ "$status" -ne 0 ]
  [[ "$output" == *"does not match the reviewed tag inputs"* ]]
}

@test "release finalizer rejects an invalid target without producing assets" {
  run "$TEST_ROOT/bin/base-demo-release-finalize" \
    --repo "$TEST_ROOT" \
    --commit eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeez \
    --output-dir "$TEST_TMPDIR/invalid"

  [ "$status" -ne 0 ]
  [[ "$output" == *"full lowercase 40-character SHA"* ]]
  [ ! -e "$TEST_TMPDIR/invalid/release-bom.json" ]
}

@test "prepared installer self pin matches BOM while released Base ref resolves exactly" {
  project_ref="$(sed -n 's/^PROJECT_RELEASE_REF="${PROJECT_RELEASE_REF:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"
  project_pin="$(sed -n 's/^PROJECT_RELEASE_COMMIT="${PROJECT_RELEASE_COMMIT:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"
  base_ref="$(sed -n 's/^BASE_RELEASE_REF="${BASE_RELEASE_REF:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"
  base_pin="$(sed -n 's/^BASE_RELEASE_COMMIT="${BASE_RELEASE_COMMIT:-\([^}]*\)}"$/\1/p' "$TEST_ROOT/install.sh")"

  [ -n "$project_ref" ]
  [ -n "$project_pin" ]
  [ -n "$base_ref" ]
  [ -n "$base_pin" ]

  # The next demo tag does not exist during its version PR, and the tracked
  # self pin cannot name its own eventual merge SHA. Do not demand a published
  # tag here. Finalized artifact identity is checked by provenance + live BOM
  # evidence after merge; this test only checks the prepared input contract.
  run python3 -c '
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
bom = json.loads((root / ".release/release-bom.json").read_text())
tag = "v" + (root / "VERSION").read_text().strip()
assert sys.argv[2] == tag == bom["release"]["tag"]
assert sys.argv[3] == bom["release"]["commit"]
rows = [r for r in bom["components"] if r["repository"] == "basefoundry/base-demo"]
assert len(rows) == 1 and rows[0]["tag"] == tag and rows[0]["commit"] == sys.argv[3]
' "$TEST_ROOT" "$project_ref" "$project_pin"
  [ "$status" -eq 0 ]

  run resolve_release_commit "$TEST_ROOT/../base" "${BASE_REPO_URL:-https://github.com/basefoundry/base.git}" "$base_ref"
  [ "$status" -eq 0 ]
  [ "$output" = "$base_pin" ]
}
