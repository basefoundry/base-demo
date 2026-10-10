# Trust and consent, in disposable fixtures

Run the scenario against clean, exact-commit provider checkouts and an existing
Python interpreter with Base's dependencies. It creates its own home, workspace,
cache and trust store, and cleans them on success or failure. It never edits a
learner's real approval store or IDE settings. The project is deliberately a
tiny shell fixture; uv remains the dependency owner for the normal demo.

```bash
python3 tests/scenarios/trust.py \
  --base /path/to/base-v1.10.0 \
  --base-commit 167947add351b8d609b5ab17342425e9a337acbb \
  --base-cli /path/to/base-cli-v0.5.1 \
  --bash-libs /path/to/base-bash-libs-v2.2.2 \
  --python /path/to/base-compatible-venv/bin/python
```

The stable lane asserts inspection before trust, denied execution (exit 1),
explicit approval, successful execution (exit 0), manifest-change invalidation,
and revocation of a single reviewed approval. Expected failures are assertions,
not errors the learner needs to repair. Each completed boundary prints `PASS`.
Unchanged external scripts are **not** bound by command approval; this is not a
sandbox or a guarantee that every referenced executable is safe.

## Extended v1.10 guarantees

The stable lane covers the released Base v1.10 baseline. The extended lane
adds assertions for complete historical-approval revocation and
static-by-default runtime inspection.

The extended lane uses the exact released Base commit
`167947add351b8d609b5ab17342425e9a337acbb`; run the same command with that
checkout/commit and add `--candidate`. Both lanes run in [isolated scenario
CI](../.github/workflows/scenarios.yml). Extended success does not replace the
exact post-merge compatibility evidence required by the release BOM.

The extended scenario additionally approves multiple manifest versions, revokes them,
and proves that reverting to an older manifest does not restore execution.
It uses a harmless marker-producing interpreter fixture to prove static
inspection does not execute runtime code—even after command approval—and that
`--verify-project-runtime` explicitly permits the probe.

| Consent | What it permits | What it does not permit |
| --- | --- | --- |
| `trust allow` | Reviewed manifest command execution | Runtime inspection or IDE mutation |
| `--verify-project-runtime` | Project/runtime probes for that check or doctor invocation | Saved command approval or IDE mutation |
| `--allow-project-ide-mutations` | Applying a reviewed project-originated IDE plan | Command approval or runtime verification |
| `--yes` | Ordinary confirmation handling | Any of the independent approvals above |

IDE behavior is tested through public dry-run previews and an isolated consent
guard test whose mutation delegates are spies. No application install, extension
install or IDE user-settings write is performed. The guard rejects mutation
without its own consent before reaching any delegate.

Host prerequisite findings remain real and may make `check` return 1 on a
partially configured machine. The scenario asserts the project findings and the
JSON aggregate exit contract separately; a passing scenario is **not** a claim
that the host is ready. Local temporary paths are redacted from assertion
diagnostics. `tests/scenario_harness_test.py` verifies cleanup and redaction.

For the authoritative boundaries, see Base's
[command-trust policy](https://github.com/basefoundry/base/blob/v1.10.0/docs/manifest-command-trust.md).
