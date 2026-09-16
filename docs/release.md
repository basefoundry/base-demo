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

The release path in `install.sh` is pinned to reviewed immutable inputs:

- Base installer: the versioned `v1.8.0` URL, SHA-256
  `492dd06eee86223c780f011b545cdef8e11964489c8a2d54c9da426f55ed9980`, and
  Base commit `26b9af5dee16efcb47e652513ce734b3ae9bc920`;
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
