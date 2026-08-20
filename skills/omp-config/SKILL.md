---
name: omp-config
description: Use to inspect and modify Oh My Pi user or project configuration, models, credentials, auth broker settings, themes, tools, and provider preferences.
---

# Oh My Pi Configuration

## Purpose

Manage OMP configuration through its current CLI and profile-aware paths without assuming a username, home directory, provider, or dotfiles system.

## Prerequisites

`omp` must be installed and available on `PATH`.

Health check:

```sh
omp --version >/dev/null && omp config path >/dev/null
```

## Resolve paths first

File tools do not reliably expand `~`. Resolve the active profile-aware directories before reading or editing files:

```sh
AGENT_DIR="$(omp config path)"
OMP_ROOT="$(dirname "$AGENT_DIR")"
```

Build absolute paths from those values:

| Data | Path |
| --- | --- |
| User settings | `$AGENT_DIR/config.yml` |
| Model registry overrides | `$AGENT_DIR/models.yml` |
| OMP environment file | `$AGENT_DIR/.env` |
| Local credential database | `$AGENT_DIR/agent.db` |
| Broker token file | `$OMP_ROOT/auth-broker.token` |
| Gateway token file | `$OMP_ROOT/auth-gateway.token` |
| Project settings | `<project>/.omp/settings.json` |

Never substitute a literal home-directory path. Re-run `omp config path` when the active profile or environment changes.

## Deterministic workflow

Run the narrow OMP command before manually interpreting files:

- Locate active config: `omp config path`
- List settings and types: `omp config list --json`
- Read a setting: `omp config get <key>`
- Set a schema-backed setting: `omp config set <key> <value>`
- Reset a setting: `omp config reset <key>`
- Inspect models: `omp models --json` or `omp models find <query>`
- Inspect OAuth providers: `omp auth-broker list --json`
- Inspect broker state: `omp auth-broker status --json`

Use direct YAML edits only for `models.yml`, structures the CLI cannot express, or settings not exposed by `omp config`.

## Operating modes

- **Read-only requests**: inspect CLI output and relevant files without modifying state.
- **Change requests**: read current state, create a timestamped sibling backup for every directly edited file, apply the smallest change, then validate the exact setting or behavior.

Treat unexpected file changes as user-owned. Never replace whole configuration files to change one field.

## Persistent settings

1. Discover valid keys and types with `omp config list --json`.
2. Read the current value with `omp config get <key>`.
3. Prefer `omp config set` or `omp config reset`.
4. If a direct edit is required, back up `$AGENT_DIR/config.yml`, preserve unrelated YAML, and edit only the intended structure.
5. Validate with `omp config get <key>` or `omp config list --json`.

## Models and providers

Read [models config](reference/models-config.md) before editing `models.yml`. Keep provider ids, model ids, and environment-variable names supplied by the user's actual configuration or current OMP docs. Do not invent provider-specific defaults.

## Credentials and OAuth

Read [auth resolution](reference/auth-resolution.md) before changing credentials. Never print, log, commit, or include key prefixes in output.

When authentication is in doubt, use an OMP-native end-to-end smoke check against the exact configured model:

```sh
omp -p --no-session --no-tools --no-title --model <provider>/<model> "Reply with exactly: ok"
```

A provider rejection from this command is an authentication or provider issue. Do not rewrite unrelated configuration to suppress it. Use `omp-docs` when current provider behavior or command syntax needs confirmation.

## Auth broker and gateway

Read [broker and gateway](reference/broker-gateway.md) before changing broker URLs, tokens, or gateway behavior. Prefer environment-variable or token-file indirection over literal secrets in YAML.

## Mandatory validation

After a change, run the narrowest matching check:

- Setting: `omp config get <key>`
- Settings structure: `omp config list --json`
- Model registry: `omp models find <query>`
- Model authentication: the exact-model smoke command above
- OAuth providers: `omp auth-broker list --json`
- Broker mode: `omp auth-broker status --json`

If behavior changed, exercise that exact path once. Do not claim validation from unrelated commands.

## Safety rules

- Read current state before every edit.
- Back up existing files before direct edits.
- Keep secrets out of tracked files, documentation, command output, and chat responses.
- Do not inspect raw request dumps that may contain authorization headers unless the user explicitly requests a security-sensitive investigation and output is redacted.
- Do not delete unrelated providers, roles, tools, themes, extensions, or credentials.
- Do not edit generated OMP source registries to change user configuration.
- Preserve project settings separately from user settings.

## Reference

- [Common tasks](reference/common-tasks.md)
- [Models config](reference/models-config.md)
- [Auth resolution](reference/auth-resolution.md)
- [Broker and gateway](reference/broker-gateway.md)
- [Validation](reference/validation.md)
