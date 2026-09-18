# base-demo Release Policy

`base-demo` publishes versioned releases using Semantic Versioning. The first
formal release is `0.1.0`; the repository's `VERSION` file is the authoritative
identity, and duplicated metadata is checked against it.

`base-demo` releases are independent of Base, `base-cli`, and
`base-bash-libs` releases. The shared provider, platform, license, and
release-artifact rules are summarized in the [Base ecosystem platform, license,
and release policy](https://github.com/basefoundry/base/blob/main/docs/ecosystem-policy.md).

## Governed identity

The following values must agree with `VERSION`:

- `pyproject.toml` and the matching `uv.lock` project entry;
- `services/demo-console/package.json` and its lockfile root entry;
- the Base-style top-of-page tests, platform, and version badges plus the
  current-release and release-policy links in `README.md`; and
- the dated version heading in `CHANGELOG.md`.

`base-cli` and `base-bash-libs` versions are independent compatibility pins.
They do not change merely because base-demo publishes a release.

`.release/release-bom.json` is the coordinated release record. It captures the
exact Base, base-cli, base-bash-libs, and base-demo commits, contract identities,
supported platforms, required/advisory status, and compatibility result.
Moving development sources are advisory and do not block a release. In a release
PR, this tracked file is the prepared input: its base-demo self-commit values
cannot identify the eventual merge commit because editing them would change
that commit. The tag workflow finalizes both self-commit values from the
annotated tag target into an external BOM asset; it does not rewrite the reviewed
source tree or retag a release.

## Bootstrap provenance

`bin/base-demo-release-bom-check` is a strict publication check, not an input
preparation check. It runs Base's governed validator plus the demo policy in
`lib/release_contract/`. It requires all four immutable participants, supported
dependency-input identity, coherent platforms, and passing required combinations
for **both macos-14 and ubuntu-24.04**. Duplicate rows/participants, scalar type
errors, unknown source modes, stale pins, and any failed required row fail closed.

Evidence must name a concrete
`https://github.com/basefoundry/base-demo/actions/runs/<id>` run. The checker uses
authenticated, read-only `gh api` calls to verify the repository, exact release
commit, trusted `tests.yml` push/manual workflow, completed successful result,
unique passing platform job on its exact runner label, and passing
`validate-base-cli-source` job. It also retrieves the supported-input JSON at
that exact commit and compares it with the release input. Component evidence
must point to a verified combination run. A syntactically valid URL alone is
not proof; unavailable or mismatched GitHub evidence blocks publication.

The trust root is the reviewed workflow at the reviewed commit: CI must consume
the structured pins and assert resolved inputs. This verifies repository-owned
compatibility evidence, not a third-party or cryptographic build attestation.
macOS proves the full demo; Ubuntu retains its documented setup/read-only scope.

The historical checked-in v0.1.0 BOM is not fresh compatibility evidence and is
intentionally rejected. Do not rewrite published history or mark new rows passed
just to satisfy this gate. #293 supplies coherent supported inputs and #303
binds actual final-candidate evidence. Tests use isolated synthetic records and
mock server responses; those fixtures are never release proof.

The default inputs are `.release/release-bom.json` and
`.release/supported-dependencies.json`. Artifact inspection can use
`BASE_DEMO_RELEASE_BOM_PATH` and `BASE_DEMO_RELEASE_INPUTS_PATH`;
`BASE_DEMO_RELEASE_BOM_EXPECTED_COMMIT` binds the result to the reviewed target.
There is no offline bypass for publication. GitHub Actions grants only read
access to Actions evidence during verification.

### Installer inputs

The current source `install.sh` release path is pinned to reviewed immutable
inputs. These guarantees do **not** apply to the historical v0.1.0 installer.
The README temporarily downloads the checksum-verified script from commit
`96f8e6d0c016aaf73e1a8c448ac92c9222a5aced`; it still installs the older release
Base v1.8.0/demo v0.1.0 checkouts, not the current supported input selection
or that source commit as the demo checkout.
Before closing [#303](https://github.com/basefoundry/base-demo/issues/303), replace
the README's interim script URL and digest with the new verified release asset,
update the stated consumed versions, and rerun `bash tests/public_install_test.sh`.

The consumed inputs are:

- Base installer: the version, full commit and SHA-256 selected by
  `.release/supported-dependencies.json`, materialized in current `install.sh`;
- base-demo checkout: release ref `v0.1.0` and commit
  `b8ac2ae490e4965b8131195a11377fd0bd787daf`.

When preparing a release, update `PROJECT_RELEASE_REF` in the reviewed
`install.sh` source to the new release tag. Keep `PROJECT_RELEASE_COMMIT` as a
valid full commit pin; the tag workflow replaces it in the external installer
asset with the reviewed tag target. Do not try to embed the future merge SHA in
the commit that must have that identity. Update the Base release ref, commit,
installer URL, and checksum together whenever the supported Base release
changes. Verify the Base installer content with:

```bash
curl -fsSL https://raw.githubusercontent.com/basefoundry/base/<base-ref>/install.sh \
  | shasum -a 256
```

Release mode never pulls, resets, detaches, or switches an existing checkout.
If `~/work/base` or `~/work/base-demo` is a contributor checkout at another
revision, the command stops without changing it. Contributors should opt into
the local workspace explicitly:

```bash
./install.sh --dev
BASE_DEMO_DEV_MODE=1 ./install.sh
```

Developer mode reuses existing sibling checkouts exactly as they are, without
automatic pulls or branch changes. A developer may set `BASE_INSTALL_URL`,
`PROJECT_REPO_URL`, or related pin variables for an explicit local override;
missing checksum verification is warned about in this mode and is never
silently accepted by the release path.

## Release procedure

1. Keep post-release work under `## [Unreleased]` in `CHANGELOG.md`.
2. In a release PR, choose the next SemVer version, update `VERSION` and all
   governed metadata, promote `Unreleased` into a dated version section, and
   update the README badge strip, release links, and bootstrap pins in
   `install.sh`.
3. Generate or update the demo component row with
   `bin/base-demo-release-bom-row`, update `.release/release-bom.json` from the
   coordinated release inputs, then run `bin/base-demo-release-check`,
   `bin/base-demo-release-bom-check`, `mise run validate`, and the normal hosted
   pull-request checks. Do not try to pin the final merge SHA in this commit.
4. After the release PR is merged to `main`, create an annotated tag from the
   clean merge commit: `git tag -a vX.Y.Z -m "base-demo vX.Y.Z"`.
5. Push the tag. The read-only `verify` job in the `Release Demo` workflow
   requires an annotated tag and verifies its reviewed ancestry, then generates
   an external BOM and installer pinned to the exact tag target. It checks both
   files and their SHA-256 manifests and uploads that verified artifact for the
   separate `release` job. The write-enabled job downloads and rechecks the same
   artifact before attaching `release-bom.json`, `release-bom.sha256`,
   `install.sh`, and `install.sh.sha256` to the GitHub Release.
6. Treat published tags and releases as immutable. Corrections require a new
   patch release; do not retag a published version or replace its release
   assets.

The provenance helper can be dry-run against a local fixture with
`bin/base-demo-release-provenance --repo PATH --main-ref REF vX.Y.Z COMMIT`.
The workflow does not publish from ordinary branch or pull-request events. A
release is therefore reproducible from a reviewed merge commit and an explicit
annotated tag push.

## SemVer journey

Before `1.0.0`, patch releases contain fixes and documentation while minor
releases add meaningful demo contracts or capabilities. SemVer technically
allows breaking changes in `0.x`, but base-demo requires an explicit migration
note for any contract change and avoids silent breaks.

`1.0.0` is appropriate once the operator journey, CLI/demo output contracts,
service and environment schemas, supported-platform boundaries, release
automation, provenance, and upgrade guidance are stable and documented.
