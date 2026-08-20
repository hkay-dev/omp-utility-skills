# API Key and OAuth Rules

## Inspect before changing

```sh
AGENT_DIR="$(omp config path)"
OMP_ROOT="$(dirname "$AGENT_DIR")"
omp auth-broker list --json
omp auth-broker status --json
```

Read current OMP documentation for provider-specific precedence. Depending on the provider and transport, credentials can come from:

- a runtime `--api-key` override
- the local or broker-backed credential store
- refreshed OAuth credentials
- provider environment variables
- a `models.yml` provider override

Do not assume that changing one source disables higher-precedence sources.

## OAuth operations

Use provider ids returned by OMP rather than hardcoding examples:

```sh
omp auth-broker login <provider-id>
omp auth-broker logout <provider-id>
omp auth-broker import <file-or-directory>
```

In broker mode, credential mutations target the active broker behavior described by the current CLI and docs. Confirm the destination before deleting or importing credentials.

## API-key validation

Never call provider APIs with ad hoc scripts that expose tokens or token prefixes. Validate through the exact OMP model path:

```sh
omp -p --no-session --no-tools --no-title --model <provider>/<model> "Reply with exactly: ok"
```

A failed provider response is evidence about that requested model path. Preserve the error text after redacting secrets and avoid changing unrelated configuration.
