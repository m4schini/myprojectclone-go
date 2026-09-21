# AGENTS.md

Guidance for AI coding assistants (Cursor, GitHub Copilot, OpenCode, Claude, etc.) contributing to this repository.

License: TODO

---

## Project Overview

A Go project template: a Cobra CLI skeleton with Viper configuration, a Zap
logger, CI (pre-commit, tests, golangci-lint, govulncheck, trivy) and
deployment manifests (Helm, Podman quadlet). See `README.md` for the layout.

Projects scaffolded from this template are expected to grow a hexagonal
layout (`app/`, `ports/`, `adapters/`); those directories do not exist yet.

---

## Architectural Rules (must follow)

- **`cmd/`** — Cobra commands; thin entry points. `main.go` only calls `cmd.Execute()`.
- **`config/`** — Viper configuration loading (`config.go`) and default values (`defaults.go`).
- **`telemetry/`** — shared logger (`telemetry.Logger("component", "sub")`). Do not call `zap.NewProduction()` ad hoc or use the global `log` package.
- **`hack/`** — developer and CI tooling that is not part of the shipped binary. `hack/hooks/` holds the Conventional Commits validator shared by the local `commit-msg` hook and the `pr-title` workflow.
- **`deploy/`** — Helm chart and Podman quadlet.

When adding the hexagonal layers:

- **`app/`** — domain core. Orchestrates services and repositories. MUST NOT import `ports/` or `adapters/`, and depends on frameworks only through interfaces.
- **`ports/`** — inbound interfaces this binary exposes: REST API, gRPC API, message consumers, etc. Handlers translate protocol ↔ domain calls and MUST NOT contain business logic. The CLI lives in `cmd/`, not here — a pure CLI project has no `ports/` at all.
- **`adapters/`** — outbound clients and connections: database connections, HTTP/gRPC clients for other services, message producers, etc. All external I/O lives here.

---

## Configuration

Config is loaded via Viper (`config.Init`, registered with `cobra.OnInitialize`):

1. Environment variables (`viper.AutomaticEnv`).
2. Config file `.<appname>.yaml` in `$HOME`, `/etc/<appname>/` (Linux only) or the current directory. A missing file is not an error.
3. Defaults in `config/defaults.go`.

`DEVELOPMENT=true` enables `config.InDevelopmentEnvironment()`, which switches the
logger to a development configuration.

When adding a setting: add the default in `config/defaults.go`, read it via
Viper, and document it in `README.md`.

---

## Tooling

- `Dockerfile` is a symlink to `Containerfile`; pre-commit enforces this. Build with `-X main.version=<version>` to set `config.Version`.
- The golangci-lint version is pinned in three places that must agree: `.pre-commit-config.yaml` (`rev:`), `.github/actions/golangci-lint/action.yml` (`version` default) and your local binary. `.golangci.yml` enables all linters and documents every exclusion with the style-guide section it contradicts — keep that convention when adding one, and prefer a `//nolint:<linter> // reason` on the specific line over a config-level exclusion.
- The Go version is defined only in `go.mod`; CI reads it via `go-version-file`.
- Integration tests are tagged `integration` and run with `make test-integration`.

---

## Go Coding Practices

All Go code follows [Effective Go](https://go.dev/doc/effective_go) and
[Go Code Review Comments](https://go.dev/wiki/CodeReviewComments). The linter
config is derived from those documents; if it complains, the code is usually
wrong, not the linter. The rules below are the subset AI assistants must apply
to every change.

### Formatting & Tooling

- Code MUST be formatted with `gofmt`/`goimports` and pass `go vet ./...` and `golangci-lint run ./...`.
- Run `go mod tidy` after dependency changes; commit `go.mod` and `go.sum` together.

### Naming

- Package names: short, lowercase, single word. Do not stutter (`config.Init`, not `config.ConfigInit`).
- Exported identifiers MUST have a doc comment beginning with the identifier name.
- Acronyms keep consistent case: `userID`, `parseURL`, `HTTPClient`.
- Getters drop the `Get` prefix. Single-method interfaces end in `-er`. Define interfaces on the consumer side.
- Receiver names: short (1–2 letters), consistent across a type. Never `self` or `this`.

### Error Handling

- Always handle errors. `_ = f()` needs a comment explaining why.
- Wrap with `%w`: `fmt.Errorf("read config: %w", err)`.
- Error strings: lowercase, no trailing punctuation.
- Sentinel errors are exported `Err...` variables; compare with `errors.Is`/`errors.As`.
- Do not log **and** return the same error. Avoid `panic` outside unrecoverable initialization.

### Control Flow, Context, Concurrency

- Early returns; no `else` after `return`/`continue`/`break`; `switch` over long `if-else` chains.
- `context.Context` is always the first parameter, named `ctx`; never stored in a struct, never `nil`.
- Every goroutine needs a termination story (context, channel close, `sync.WaitGroup`). Pass `sync.Mutex`/`WaitGroup` by pointer.

### Variables, Types & APIs

- Narrowest scope possible. A nil slice is a valid empty slice; check `len(s) == 0`.
- Use `any`, not `interface{}`. Accept interfaces, return concrete types.
- Do not introduce an interface purely as a unit-test seam for an infrastructure dependency — cover it with an integration test instead.
- Do not export what is not part of the package's public contract.

### Comments & Documentation

- Comments explain **why**, not **what**.
- Package comments live in one file per package.
- `TODO(name): ...` / `FIXME(name): ...` include an owner.

### Testing

- Table-driven tests with `t.Run`; `t.Helper()` in helpers; `t.Cleanup` over `defer` for teardown.
- `make test` runs with `-race -shuffle=on`; keep tests order-independent.
- Integration tests use build tag `integration` and testcontainers — a container runtime must be running.
- Never commit fixtures with real credentials or personal data.

### Imports

- Three groups: standard library, third-party, local (`myproject/...`). `goimports` enforces this.
- No dot imports; no blank imports outside `main` or driver-registration files.

---

## Attribution

### For AI-assisted commits

AI assistants MUST NOT add `Signed-off-by` tags — only a human can certify the DCO. The human committer is responsible for:

- Reviewing all AI-generated code.
- Ensuring licensing compliance.
- Adding their own `Signed-off-by`.
- Taking full responsibility for the contribution.

AI assistants MUST NOT add `Co-authored-by` tags.

When AI assistance materially shaped a commit, add an attribution trailer:

```
Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]
```

Examples:

```
Assisted-by: Cursor:claude-sonnet-4.5
Assisted-by: Copilot:gpt-5
Assisted-by: Claude:claude-opus-4
```

Do not list basic tools (git, go, make, editors).

### Commit messages and PR titles

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
`type(scope)!: description`, description lowercase, no trailing period,
subject ≤ 72 characters. Allowed types are `feat`, `fix`, `chore` only —
`docs`, `refactor`, `test`, `ci`, etc. are rejected. Mark breaking changes with
`!` or a `BREAKING CHANGE:` footer.

`hack/hooks/conventional-commit.sh` validates both the local `commit-msg` hook
and PR titles (`.github/workflows/pr-title.yml`), so a local commit and a
squash-merge title are never judged differently. Always pass `--title` in this
format to `gh pr create`.

---

## Things to Avoid

- ❌ Adding `Signed-off-by` or `Co-authored-by` on behalf of a human.
- ❌ Skipping commit hooks with `--no-verify` or bypassing signing (`--no-gpg-sign`, `-c commit.gpgsign=false`).
- ❌ Replacing the `Dockerfile` symlink with a regular file.
- ❌ Bumping golangci-lint in only one of its pinned locations.
- ❌ Committing secrets or tokens.
- ❌ Goroutines without a defined termination path.
- ❌ Swallowing errors silently or capitalizing error strings.
- ❌ `interface{}` in new code (use `any`).

---

## Quick Reference

| Task | Command |
|---|---|
| Build | `go build ./...` |
| Format | `golangci-lint fmt` |
| Lint | `golangci-lint run ./...` |
| Vet | `go vet ./...` |
| Test | `make test` (`-race -shuffle=on`) |
| Test (integration) | `make test-integration` (needs a container runtime) |
| Tidy deps | `go mod tidy` |
| Run | `go run .` |
| Install hooks | `pre-commit install` |
