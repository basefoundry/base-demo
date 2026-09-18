# Three short paths to first success

This is a curated representative subset of Base, not an exhaustive framework
certification. The [capability matrix](base-capability-matrix.md) separates
demonstrated contracts, intentional omissions and future work.

For these **current-source** paths, use the exact stable versions in
[supported inputs](../.release/supported-dependencies.json): Base 1.9.0,
base-cli 0.4.3 and base-bash-libs 2.1.0. Start in your reviewed base-demo checkout
with Base already configured and its `basectl` on PATH. Full setup, activation,
build, test and demo paths require macOS. Bash must be 4.2 or newer. Contributors
need the toolchains declared by the manifest/mise configuration; setup may
install tools and change the project environment, so preview it first.

Need Base first? Follow the canonical [adopter golden path](https://github.com/basefoundry/base/blob/5f316aeddc3680b92bd209fcfe652eac020d02d0/docs/adopter-golden-path.md)
for install and consent decisions, then select the stable inputs above. That
document is pinned for reference, not an instruction to substitute its candidate
for the stable runtime. The README's checksum-verified [Quick Start](../README.md#quick-start)
is a separate historical Base 1.8/demo 0.1 route until v0.2.0 is published; do not
mix its results with current-source evidence or reset a divergent checkout.

Ubuntu/Debian (including WSL2 on its native filesystem) supports Base setup and
the CI-safe read-only project-health path, not the full demo loop. Native Windows
is not supported by these journeys. Candidate 1.10 examples are explicitly
separate in the [workspace](workspace-scenarios.md) and [trust](trust-scenarios.md)
scenario guides; their success is not stable-release evidence.

## Evaluate Base

**Prerequisite:** macOS, the configured stable Base runtime above, and a reviewed
source checkout. No project build or service startup is needed for this path.

```bash
basectl run --list
basectl test --dry-run
basectl trust status base-demo --workspace "$(dirname "$PWD")"
# Inspect base_manifest.yaml and src/hello.sh before approving this checkout.
basectl trust allow base-demo --workspace "$(dirname "$PWD")"
BASE_DEMO_ENV=baseline basectl run hello
basectl export-context --format markdown --print
```

**Done:** the command prints `hello from base-demo`, `BASE_PROJECT=base-demo`
and `BASE_DEMO_ENV=baseline`; context export produces the handoff Markdown.
This proves discovery/routing and one reviewed command, not full environment
readiness. Review the exported content before sharing it.

**Safe failure/recovery:** if execution says the manifest is untrusted, stop and
review the named manifest and command. Use the explicit `trust allow` only after
review; changing manifest bytes invalidates approval. Do not approve to suppress
an unexplained error. `--yes` does not grant command trust or IDE consent.

## Adopt Base in a project

**Prerequisite:** complete the evaluator path, then use a disposable branch or
new project under a separate workspace. Choose one existing, harmless project
validation command; do not copy the demo's entire toolchain or service graph.

Follow [the adopter golden path's project recipe](https://github.com/basefoundry/base/blob/5f316aeddc3680b92bd209fcfe652eac020d02d0/docs/adopter-golden-path.md#adopt-an-external-style-project)
to declare that command in your own manifest, preview setup, inspect command
surfaces, approve the reviewed digest, and run your project's test. Keep command
approval, runtime inspection and IDE mutation as separate decisions. The demo's
`test: mise: validate` is an example, not a requirement for adopters.

**Done:** your declared test passes in the intended checkout and a handoff PR
contains the manifest, test output, version/provider identities and remaining
warnings. Use [JSON quickstart](https://github.com/basefoundry/base/blob/5f316aeddc3680b92bd209fcfe652eac020d02d0/docs/json-output-quickstart.md)
for machine-readable evidence; check both JSON status and process exit.

**Safe failure/recovery:** preview setup with `basectl setup --dry-run` before
applying it. A missing prerequisite or stale environment is a diagnostic, not
permission to grant more trust. Use [first-run troubleshooting](https://github.com/basefoundry/base/blob/5f316aeddc3680b92bd209fcfe652eac020d02d0/docs/first-run-troubleshooting.md)
to repair the specific finding and rerun validation. Review any proposed IDE or
shell-profile changes separately. This internal rehearsal is not independent
external-adoption evidence.

## Contribute to base-demo

**Prerequisite:** macOS, an issue-backed dedicated worktree per [AGENTS.md](../AGENTS.md),
the supported provider inputs, and the repository's declared development tools.
Use [developer mode](../README.md#quick-start) for peer checkouts; it does not
pull or switch branches. `uv` owns locked Python dependencies; source-provider
testing is an explicit separate CI lane, never a silent replacement.

```bash
basectl setup --dry-run
# Apply reviewed setup separately; do not approve unexpected IDE changes.
basectl repo check . --agent-ready
./tests/validate.sh
git diff --check
```

**Done:** focused tests and the validator pass, and the issue-linked PR has
passing hosted checks. The full hosted lane requires Go/Java and all four live
HTTP services; a local optional-tool skip is not equivalent evidence. Handoff
the PR plus check links and any explicitly unresolved local limitations.

**Safe failure/recovery:** an unset `BASE_DEMO_ENV` intentionally produces a
health finding. On macOS activation sets `baseline`; for a one-command read-only
probe use `BASE_DEMO_ENV=baseline basectl check --ci --format json`. That marker
does not select a service environment or fix other readiness findings. Inspect
each remaining finding; do not declare success from the marker alone. Services
use `services --env dev` separately; staging/prod are non-operational examples.

For release work, use the canonical [downstream release smoke test](https://github.com/basefoundry/base/blob/5f316aeddc3680b92bd209fcfe652eac020d02d0/docs/downstream-release-smoke-test.md)
and the demo's [release policy](release.md). A contributor PR is not permission
to tag or publish. The [complete command reference](../README.md#complete-command-reference)
remains available after these short paths.
