# base-demo Release Policy

`base-demo` publishes versioned releases using Semantic Versioning. The first
formal release is `0.1.0`; the repository's `VERSION` file is the authoritative
identity, and duplicated metadata is checked against it.

## Governed identity

The following values must agree with `VERSION`:

- `pyproject.toml` and the matching `uv.lock` project entry;
- `services/demo-console/package.json` and its lockfile root entry;
- the current-release link near the top of `README.md`; and
- the dated version heading in `CHANGELOG.md`.

`base-cli` and `base-bash-libs` versions are independent compatibility pins.
They do not change merely because base-demo publishes a release.

## Release procedure

1. Keep post-release work under `## [Unreleased]` in `CHANGELOG.md`.
2. In a release PR, choose the next SemVer version, update `VERSION` and all
   governed metadata, promote `Unreleased` into a dated version section, and
   update the README release link.
3. Run `bin/base-demo-release-check`, `mise run validate`, and the normal hosted
   pull-request checks.
4. After the release PR is merged to `main`, create an annotated tag from the
   clean merge commit: `git tag -a vX.Y.Z -m "base-demo vX.Y.Z"`.
5. Push the tag. The `Release Demo` workflow verifies that the tag matches every
   identity source and creates the GitHub Release from the changelog section.
6. Treat published tags and releases as immutable. Corrections require a new
   patch release.

The workflow does not publish from ordinary branch or pull-request events. A
release is therefore reproducible from a reviewed merge commit and an explicit
tag push.

## SemVer journey

Before `1.0.0`, patch releases contain fixes and documentation while minor
releases add meaningful demo contracts or capabilities. SemVer technically
allows breaking changes in `0.x`, but base-demo requires an explicit migration
note for any contract change and avoids silent breaks.

`1.0.0` is appropriate once the operator journey, CLI/demo output contracts,
service and environment schemas, supported-platform boundaries, release
automation, provenance, and upgrade guidance are stable and documented.
