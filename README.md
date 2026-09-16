myproject-go
---

## Project layout

```
.
├── .github/    GitHub configuration: composite actions (.github/actions),
│               the ci and pr-title workflows, and the branch ruleset that
│               declares which checks are required to merge.
│
├── adapters/   Hexagonal architecture: Adapters, App (domain logic), Ports
├── app/
├── ports/
│
├── cmd/        Cobra command implementations. Holds the root command and
│               its subcommands; main.go only calls cmd.Execute().
├── config/     Viper-based configuration loading and the application's
│               default values
├── telemetry/  Telemetry package, holds logger.
│
├── deploy/     Deployment manifests (e.g. Helm, Podman quadlet)
├── hack/       Developer and CI tooling that is not part of the shipped
│               binary. hooks/ holds the Conventional Commits validator
│               shared by the local commit-msg hook and the pr-title
│               workflow.
└── docs/       Documentation for humans.
```
