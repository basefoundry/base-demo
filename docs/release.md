# base-demo Release Policy

`base-demo` publishes versioned releases using Semantic Versioning. The first
formal release is `0.1.0`; the repository's `VERSION` file is the authoritative
identity, and duplicated metadata is checked against it.

## Governed identity

The following values must agree with `VERSION`:

- `pyproject.toml` and the matching `uv.lock` project entry;
- `services/demo-console/package.json` and its lockfile root entry;
- the Base-style top-of-page tests, platform, and version badges plus the
  current-release and release-policy links in `README.md`; and
- the dated version heading in `CHANGELOG.md`.

`base-cli` and `base-bash-libs` versions are independent compatibility pins.
They do not change merely because base-demo publishes a release.

## Bootstrap provenance

The release path in `install.sh` is pinned to reviewed immutable inputs:

- Base installer: the versioned `v1.8.0` URL, SHA-256
  `492dd06eee86223c780f011b545cdef8e11964489c8a2d54c9da426f55ed9980`, and
  Base commit `26b9af5dee16efcb47e652513ce734b3ae9bc920`;
- base-demo checkout: release ref `v0.1.0` and commit
  `b74521c85d410cb67e497560976e0d95fc53fd41`.

When preparing a release, update the `PROJECT_RELEASE_REF` and
`PROJECT_RELEASE_COMMIT` values in `install.sh` to the new release tag and
reviewed merge commit. Update the Base release ref, commit, installer URL, and
checksum together whenever the supported Base release changes. Verify the
installer content with:

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
3. Run `bin/base-demo-release-check`, `mise run validate`, and the normal hosted
   pull-request checks.
4. After the release PR is merged to `main`, create an annotated tag from the
   clean merge commit: `git tag -a vX.Y.Z -m "base-demo vX.Y.Z"`.
5. Push the tag. The read-only `verify` job in the `Release Demo` workflow
   verifies the version identity, requires an annotated tag, and checks that
   the tag target (`GITHUB_SHA`) is reachable from `origin/main`. Only after
   those checks pass does the separate `release` job receive `contents: write`
   and create the GitHub Release from the changelog section.
6. Treat published tags and releases as immutable. Corrections require a new
   patch release.

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
