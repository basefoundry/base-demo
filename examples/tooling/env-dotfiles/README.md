# Reference Shell And Dotfile Tooling

These examples show how adjacent shell and dotfile tools can coexist with Base
without becoming part of the default `base-demo` contract.

The files in this directory are reference-only. They are not loaded by Base,
CI, setup, activation, or the default demo. Copy one into an active location
only after reviewing the behavior for your own machine.

## direnv

`direnv/envrc.example` demonstrates a minimal `.envrc` shape that watches
Base-owned files and sets `BASE_DEMO_ENV=baseline` for local checks. The full
interactive shell path remains `basectl activate base-demo`.

Do not commit a root `.envrc` to `base-demo` without a separate issue. A root
`.envrc` changes developer shell state as soon as `direnv allow` is run.

## asdf

`asdf/tool-versions.example` mirrors the Python version currently declared in
`.mise.toml` and `base_manifest.yaml`. Base currently demonstrates mise as the
active tool-version manager, so the asdf file remains an inactive migration
reference.

Do not commit a root `.tool-versions` file without choosing to make asdf part
of the baseline contract.

## chezmoi

`chezmoi/dot_config/base-demo/base-demo.env.tmpl` shows a tiny managed dotfile
that could expose Base demo environment defaults from a user's dotfile system.
Base does not read chezmoi source state today.

## dotbot

`dotbot/install.conf.yaml.example` shows a minimal link-only dotbot config that
points to the reference env template. It is intentionally not an installer and
is not invoked by setup or CI.

## Base Boundary

Base owns repository setup, activation, checks, tests, builds, and demo
execution through `basectl` and `base_manifest.yaml`. These tools can prepare a
developer shell or home directory around Base, but they should not silently
replace Base-owned commands or trust decisions.
