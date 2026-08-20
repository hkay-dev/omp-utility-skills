# Auth Broker and Gateway Rules

Resolve the active OMP root before inspecting token files:

```sh
AGENT_DIR="$(omp config path)"
OMP_ROOT="$(dirname "$AGENT_DIR")"
```

Broker mode is enabled only when its URL is configured through the current OMP environment or settings. Token resolution may use environment variables, hidden settings, or `$OMP_ROOT/auth-broker.token`; confirm current precedence with `omp-docs` before migrating credentials.

Validate broker state with:

```sh
omp auth-broker status --json
```

Use environment-variable or token-file indirection for secrets. Never commit broker or gateway tokens, and never print their values while diagnosing connectivity.
