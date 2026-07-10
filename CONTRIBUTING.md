# Contributing to base-demo

Thank you for improving this project.

## Platform Boundary

Know the macOS/Ubuntu platform boundary before running validation. macOS is the
supported platform for the full interactive setup, activation, check, doctor,
build, test, and demo loop. Ubuntu/Debian CI validates Base runtime setup, dev-profile prerequisites, and read-only project health checks through
`basectl setup base --yes --no-notify`,
`basectl setup base --profile dev --yes --no-notify`, and
`basectl ci check base-demo --format json`. Brewfile reconciliation, project
activation shells, and the full walkthrough remain macOS paths in this
repository.

## Workflow

1. Create or choose a GitHub issue before starting implementation work.
2. Use one of the standard issue labels: `bug`, `enhancement`,
   `documentation`, `ci`, or `security`.
3. Use a focused branch and pull request for each issue.
4. Update `docs/contracts.md` when adding or changing a binding invariant.
5. Run the project checks before opening or updating a pull request.

Useful commands:

```bash
basectl check base-demo  # macOS interactive path
basectl doctor base-demo  # macOS interactive path
basectl ci check base-demo --format json  # Ubuntu/Debian read-only project health
basectl test base-demo
basectl build base-demo
```
