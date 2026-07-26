# Base Demo Tooling Test Bed Train

Goal: keep `base-demo` in lockstep with Base while making it a practical test
bed for external development tools.

Architecture: Base stays the operator-facing surface. Tools that are already
part of the Base path can be active in the baseline. Tools that alter shell
state, dotfiles, checkout synchronization, or package-manager behavior stay
reference-only until a separate issue promotes them.

## Issue And PR Order

| Order | Issue | PR intent | Notes |
| --- | --- | --- | --- |
| 1 | #178 Define base-demo tooling adapter matrix | Document the policy, register the contract, and add validation guards. | Foundation for the rest of the train. |
| 2 | #182 Demonstrate devcontainer and devenv-report against base-demo | Add CI-safe `basectl devcontainer` and `basectl devenv-report` examples. | Should not make containers or Nix/devenv the baseline runtime. |
| 3 | #180 Add optional just and Taskfile wrappers for Base commands | Add optional wrappers that delegate to `basectl`. | Keep Base commands authoritative. |
| 4 | #179 Add reference-only direnv asdf and dotfile tooling examples | Add inactive examples for `direnv`, `asdf`, `chezmoi`, and `dotbot`. | Avoid root-level files that mutate developer shell or home state. |
| 5 | #181 Add read-only multi-repo manager examples | Add inactive examples for `mani`, `gita`, `vcs2l`, and `west`. | Align examples to `workspace.yaml.example`. |
| Hold | #163 Track future Base docker-service adoption in base-demo | Adopt the future Base Docker service contract. | Blocked by basefoundry/base#124. |

## Validation Pattern

Each PR should update only the files needed for its slice and run:

```bash
./tests/validate.sh
git diff --check
```

Add focused BATS or command-level validation when a slice changes demo behavior
or executable wrappers.
