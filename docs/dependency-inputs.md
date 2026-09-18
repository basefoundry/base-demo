# Supported inputs and compatibility proof

`.release/supported-dependencies.json` is the reviewed input selection shared
with Base's downstream updater (#2289). Version 1 names exactly Base, base-cli
and base-bash-libs by stable version and full commit, plus Base's installer
SHA-256. The initial supported selection is Base 1.9.0 / base-cli 0.4.3 /
base-bash-libs 2.1.0. Tags are independently resolved to their commits in CI.
The validator is an immutable snapshot of Base's dependency-input contract.

```bash
python3 bin/base-demo-dependencies --check --verify-refs
python3 bin/base-demo-dependencies --get base.commit
```

The standalone installer materializes the Base defaults so it can bootstrap
without Python or another configuration download. The project requirement and
uv lock materialize the Python wheel selection. Consistency checks reject any
mismatch with supported inputs or the prepared BOM. CI reads the record for
all Base and Bash-library checkouts, and for the explicit base-cli source
checkout; it verifies actual checked-out commits and prints the input record.
The locked-wheel lane checks installed package metadata separately from the
explicit source-provider lane. Neither silently substitutes a sibling provider.

CI uses macOS 14 for the full demo and Ubuntu 24.04 for Base setup/read-only
health. This does not expand the Linux support boundary. The three named jobs
are stable evidence interfaces for the release gate. A run is evidence only
when its repository, exact demo commit, successful jobs, runner labels and
tested input record are independently verified by `base-demo-release-bom-check`.

## Preparing a release without circular evidence

The tracked BOM is **prepared input**, with `not_tested` results. Its self SHA
is a placeholder until the final reviewed commit exists. The previous prepared
record is retained under `.release/historical/`; it is not a current passing run.
Updating input pins invalidates prepared results; no updater invents success.

After the final reviewed commit's normal main-branch CI succeeds, the finalizer
can verify and bind that run into external artifacts:

```bash
bin/base-demo-release-finalize --commit <reviewed-full-sha> \
  --evidence-run <successful-tests-run-id> --output-dir <empty-external-directory>
```

It assigns candidate results only in memory, verifies live evidence, and writes
nothing if the proof fails. It never edits the tracked inputs after learning
the commit. The tag workflow resolves a successful `tests.yml` push run for
the exact tagged commit and passes the same run ID to the publisher's recheck.
No successful run, wrong input, failed job, or unavailable GitHub lookup means
no publication. Finalizing without `--evidence-run` remains useful for identity
fixtures but does not certify the artifacts for publication.

The README interim installer remains deliberately pinned to older reviewed
script bytes, which consume Base 1.8.0 and demo 0.1.0. Current source inputs do
not change that historical script. #303 owns the new public release-asset URL.

## Candidate boundary

Stable input selection remains Base 1.9.0. The implemented v1.10 trust/workspace
scenarios (#298/#297) must be invoked in a separate exact-commit candidate lane,
with its revision recorded. Candidate evidence is advisory and cannot satisfy
or overwrite the stable release gate. Publication is a separate human decision.
