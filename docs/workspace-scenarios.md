# Workspace validation and targeted recovery

This compact scenario creates disposable healthy, failing, untrusted, no-test,
missing-required and undeclared peers. It uses the same isolated HOME, cache,
provider checks and cleanup as the [trust scenario](trust-scenarios.md). It does
not clone or set up learner repositories or mutate learner state. Candidate
coverage also creates local Git fixtures to exercise update preflight safety;
those repositories are disposable and never leave the fixture directory.
Generated recovery commands are inspected; only a reviewed fixture-local trust
command is executed. Expected failures are assertions, not repair requests.

Run with clean exact-provider checkouts and an existing Base-compatible Python:

```bash
python3 tests/scenarios/workspace.py \
  --base /path/to/base-v1.10.5 \
  --base-commit 4036bdb704fcf2e3845e588f55a606f1db4e5eaf \
  --base-cli /path/to/base-cli-v0.5.1 \
  --bash-libs /path/to/base-bash-libs-v2.2.2 \
  --python /path/to/base-compatible-venv/bin/python
```

The stable lane checks the existing status, onboarding and agent-brief reports,
their workspace identity, missing-peer reporting and read-only behavior.

The extended update fixtures use `git init --initial-branch` and `git switch`;
local runs therefore require Git 2.28 or newer, matching the hosted runner
toolchain.

For the extended v1.10 contract, select the released checkout and exact commit
`4036bdb704fcf2e3845e588f55a606f1db4e5eaf`, and add `--candidate`.
[Scenario CI](../.github/workflows/scenarios.yml) runs both lanes. This is
repository scenario evidence, not final release BOM evidence by itself.

The extended lane asserts:

- Onboarding actions are ordered clone, setup, trust, verify; final verification
  retains the workspace and workspace-manifest identity. Agent-brief actions
  instead follow repository inventory order and target each exact checkout.
- Undeclared peers are inventoried but not included in declared workspace tests.
- A generated digest-bound trust command targets its original workspace even
  when invoked from another same-named project. Changed manifest bytes reject
  that saved command with exit 2.
- `workspace test --projects healthy` executes only that selected checkout.
  Selection filters declaration order; the comma-list does not reorder tests.
- A failing command and untrusted command are failures, no test command is a
  skip, and missing required peers fail the aggregate. Aggregate failure exits
  1; successful selection exits 0. `--fail-fast` skips later selected peers.
- Two selected aliases of one manifest are rejected (exit 2); selecting one
  alias runs the intended checkout once.
- `workspace update --dry-run --format json` rejects a dirty checkout, a
  manifest path nested inside an ancestor Git checkout, and a default branch
  tracking the wrong upstream branch. The assertions verify the structured
  preflight classification and that no checkout changes are made.

Each completed assertion group prints `PASS`; fixtures are removed on success
or exception. There is no second application stack and no host-readiness claim.
See the released [workspace contract](https://github.com/basefoundry/base/blob/v1.10.5/docs/workspace-manifest.md)
for the authoritative API.
