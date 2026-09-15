# Default-branch validation gate

The `main` branch is protected by the repository ruleset `Base default branch
protection` (ruleset `17625058`). Its required status checks are the GitHub
Actions job contexts below:

| Context | Purpose |
| --- | --- |
| `base/issue-branch-policy` | Enforce issue-backed branch naming and linkage. |
| `validate` | Run the supported macOS validation lane. |
| `validate-ubuntu` | Verify the Ubuntu validation boundary. |
| `validate-base-cli-source` | Exercise the pinned Base CLI source route. |
| `Security scanners` | Run the repository security and quality scanners. |

All five contexts use the GitHub Actions integration (`15368`). The ruleset
still permits squash merges, keeps the existing deletion and non-fast-forward
protections, and does not add a mandatory human review for this solo-maintainer
repository.

To inspect the effective configuration, read the repository ruleset directly:

```bash
gh api repos/basefoundry/base-demo/rulesets/17625058
```

When a workflow job is renamed, update the ruleset and this table together.
Resolve the context and integration ID from a successful check run before
changing the required-check list; do not rely on a workflow file's display
name alone.
