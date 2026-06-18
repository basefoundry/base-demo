# Representative Environment Design

`base-demo` is the compact representative environment for Base-managed
projects.

It should sit between a toy sample and Banyan Labs. It borrows the shape of a
medium-sized engineering organization, but keeps each service intentionally
small so the focus stays on Base orchestration, build tools, runtime diversity,
and operational workflow.

## Product Boundary

The three repos have distinct roles:

| Repo | Role |
| --- | --- |
| `base` | Workspace and tooling control plane. Base owns setup, activation, project commands, checks, build/test delegation, and repo workflow support. |
| `base-demo` | Reduced-scale representative environment. It shows how Base manages a credible multi-language, infrastructure-backed project without deep product behavior. |
| `banyanlabs` | Full platform engineering lab. It is where product behavior, operational depth, observability, delivery, Kubernetes, IaC, and cloud patterns earn their complexity. |

`base-demo` should build confidence for Banyan Labs without becoming Banyan
Labs. Its services should be boring on purpose: health checks, hello responses,
metadata, documented ports, and simple build/test paths.

## Target Stack

The target stack is broad enough to feel real and small enough to inspect:

| Area | Representative choice | Intent |
| --- | --- | --- |
| Python | Tiny Python HTTP API plus the existing Python CLI | Demonstrate Python as both project command and app service runtime. |
| Go | Tiny Go HTTP API | Demonstrate Go service development and native test/build flow. |
| Docker | Dockerized Go service | Make Docker first-class without containerizing every app service. |
| Java | One Gradle service and one Maven service | Demonstrate common Java build tools without Spring-scale complexity. |
| C | Tiny native service | Represent lower-level compiled components. |
| C++ | Tiny native service | Represent C++ service/tooling presence in a mixed environment. |
| JavaScript UI | React + Vite demo console | Provide a common frontend framework and human-facing operational surface. |
| Databases | Postgres and MySQL through Compose | Represent common data dependencies without cross-service dependency complexity. |
| Cache | Redis through Compose | Represent cache infrastructure as a local dependency pattern. |

Each app service should expose the same small HTTP surface when practical:

- `/healthz`
- `/hello`
- `/info`

The point is not business logic. The point is that Base can see, run, test,
build, and explain a realistic mix of tools.

## Services Command

The main operator surface should be one manifest command:

```bash
basectl run base-demo services status
basectl run base-demo services start
basectl run base-demo services stop
basectl run base-demo services restart
basectl run base-demo services check
basectl run base-demo services logs
```

The command should read a catalog rather than hard-code each service in the
script. The catalog should be the source of truth for service name, kind,
runtime/tooling, port, health URL, start/stop behavior, and whether the service
is required for a given environment.

The status view should answer the practical local questions:

- what is supposed to exist
- what is running
- where it is listening
- what runtime or tool it represents
- how health is checked
- where logs live, or how to find them
- when available, since when it has been running

## Infrastructure Scope

Postgres, MySQL, and Redis should be representative dependencies, not a
cross-service architecture exercise.

Only one or two later services may demonstrate a tiny database or cache probe if
that makes the infrastructure visible. Most services should remain independent
health/hello/info fixtures. This keeps the environment credible while avoiding a
fake distributed-system dependency graph.

Compose should manage local infrastructure. The language build tools should
still remain visible through native build and test commands.

## Environment Model

`base-demo` should model three environments:

```text
environments/
  dev.yaml
  staging.yaml
  prod.yaml
```

Only `dev` is operational by default. `staging` and `prod` are checked-in
configuration examples that demonstrate separation of ports, URLs, image tags,
database/cache names, and logging mode.

This is deliberate. A real deployable staging/prod story belongs in Banyan Labs.
`base-demo` should teach the shape of environment-aware configuration without
requiring cloud accounts, Kubernetes, Terraform, or secret management.

## Main Demo Shape

The representative stack should be part of the main demo, not hidden behind an
advanced path.

The completed walkthrough should show:

1. Base project discovery and setup.
2. Manifest-declared commands.
3. Environment configuration.
4. Service catalog status.
5. Build/test delegation across runtimes.
6. Local infrastructure lifecycle through Compose.
7. App-service health checks.
8. React/Vite console as the human-facing view.
9. Clean teardown.

The default validation path should remain stable. Heavy checks can be skipped
with a clear message when Docker or a language toolchain is unavailable, but the
repo shape and command contracts should always be validated.

## Implementation Train

The implementation should move one issue at a time:

| Issue | Slice |
| --- | --- |
| #62 | Define and publish this representative environment direction. |
| #63 | Add the service catalog and `services` lifecycle command. |
| #64 | Add the `dev`, `staging`, and `prod` environment model. |
| #65 | Add Compose-backed Postgres, MySQL, and Redis. |
| #66 | Add the Go API service and Docker image fixture. |
| #67 | Add the Python API service fixture. |
| #68 | Add Java Gradle and Maven service fixtures. |
| #69 | Add C and C++ service fixtures. |
| #70 | Add the React/Vite service console UI. |
| #71 | Integrate the representative environment into demo validation and CI. |

Each PR should keep the demo runnable, update docs when command behavior
changes, and preserve the issue-first workflow from `AGENTS.md`.
