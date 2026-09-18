# Workspace validation and targeted recovery

This compact scenario creates disposable healthy, failing, untrusted, no-test,
missing-required and undeclared peers. It uses the same isolated HOME, cache,
provider checks and cleanup as the [trust scenario](trust-scenarios.md). No
clone, setup, repository initialization or learner-state mutation is performed.
Generated recovery commands are inspected; only a reviewed fixture-local trust
command is executed. Expected failures are assertions, not repair requests.

Run with clean exact-provider checkouts and an existing Base-compatible Python:

```bash
python3 tests/scenarios/workspace.py \
  --base /path/to/base-v1.9.0 \
  --base-commit ac8d294421e1bfc14afa8c6a2a12f1affb5268ee \
  --base-cli /path/to/base-cli-v0.4.3 \
  --bash-libs /path/to/base-bash-libs-v2.1.0 \
  --python /path/to/base-compatible-venv/bin/python
```

Base 1.9 checks the existing status, onboarding and agent-brief reports, their
workspace identity, missing-peer reporting and read-only behavior. It prints
an explicit supported-version boundary without invoking newer flags.

For the implemented 1.10 candidate, select its checkout and exact commit
`5f316aeddc3680b92bd209fcfe652eac020d02d0`, and add `--candidate`.
[Scenario CI](../.github/workflows/scenarios.yml) runs both lanes. This is
advisory candidate evidence, not a stable-release compatibility claim.

The candidate asserts:

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

Each completed assertion group prints `PASS`; fixtures are removed on success
or exception. There is no second application stack and no host-readiness claim.
See the exact candidate's [workspace contract](https://github.com/basefoundry/base/blob/5f316aeddc3680b92bd209fcfe652eac020d02d0/docs/workspace-manifest.md)
for the authoritative API.
