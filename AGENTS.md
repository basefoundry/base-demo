# Agent Instructions for base-demo

Use this file for repository-local agent guidance. User instructions still take
precedence over this baseline.

## Workflow

1. Create or choose a GitHub issue before implementation work.
2. Use one standard issue label: `bug`, `enhancement`, `documentation`,
   `ci`, or `security`.
3. Check whether the issue is ready for agentic implementation:

   ```text
   basectl gh issue readiness <issue-number> --repo basefoundry/base-demo --project-owner basefoundry --project-number 9 --format json
   ```

   Treat `ready` as the green path. If Base reports `partial`, `not_ready`, or
   missing Project fields, refine the issue or make the intended exception
   explicit before implementation.
4. Branch from the issue with:

   ```text
   <category>/<issue>-<YYYYMMDD>-<slug>
   ```

5. Use a dedicated worktree for each pull request:

   ```bash
   git fetch origin
   git worktree add -b <branch> ../base-demo-worktrees/<slug> origin/main
   ```

6. Keep the pull request scoped to the issue and link it with
   `Fixes #<issue>` or `Closes #<issue>` when merge should close the issue.
7. Review stale local and origin branches during cleanup:

   ```text
   basectl gh branch stale --days 14 --format json
   ```

   Use the report as a review aid before pruning; do not delete unrelated user
   branches just because they are old.
8. Preserve existing user changes. Do not overwrite project-owned files unless
   the user explicitly asks for that edit.

## Validation

Run the project validation command before publishing changes:

   ```bash
   ./tests/validate.sh
   ```

Also run narrower tests for the files changed when available.

## Documentation

Update docs when behavior, commands, setup, or workflow expectations change.
Update `CHANGELOG.md` only for notable user-visible or release-worthy changes.

## Finish

After merge, sync main, remove the worktree, and delete merged local
and remote branches when safe.
