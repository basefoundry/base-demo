# Reference Multi-Repo Tooling

These examples show how external multi-repo tools can describe the same peer
repository set as `workspace.yaml.example` without making Base import or
synchronize those formats.

The examples are read-only references. Base discovers opted-in projects from
the local workspace and Base manifests; it does not read `mani`, `gita`,
`vcs2l`, or `west` configuration today.

## Repository Set

The examples model this local checkout shape:

| Name | Path | Role |
| --- | --- | --- |
| `base` | `../base` | Base CLI and framework repository |
| `base-demo` | `.` | Reference project |
| `base-platform-tools` | `../base-platform-tools` | Optional companion repository |
| `base-bash-libs` | `../base-bash-libs` | Optional shell library companion |

Use `basectl workspace status --manifest workspace.yaml.example` for the
Base-owned view of that expected set.

## Tool Notes

- `mani/mani.yaml.example` is a task-oriented workspace inventory for
  read-only status commands.
- `gita/gita-commands.example` is a command transcript for registering the same
  repositories with gita from a user-owned shell.
- `vcs2l/vcs2l.yaml.example` is a simple repository list that can be adapted to
  a vcs2l workflow.
- `west/west.yml.example` is a west manifest-style view of the Base Foundry
  repository set.

Keep these examples outside the repository root unless Base gains a deliberate
adapter contract for one of these formats.
