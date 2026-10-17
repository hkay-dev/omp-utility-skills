# Auth Broker and Gateway Rules

Resolve the active profile's directories with the [common path recipe](common-tasks.md), preserving cwd, environment, and explicit `--profile` for all commands. Do not derive the config root from `dirname(AGENT_DIR)`: independent `PI_CODING_AGENT_DIR` overrides can separate them. Normal named-profile agent directories do have their profile root as parent. Initialized XDG data layouts can also place `agent.db` outside the agent directory.

These CLI recipes require authorized operational inspection or changes; config metadata can initialize/migrate/quarantine settings, and broker checks can resolve commands or contact services. Strict no-mutation audits use [static path discovery](common-tasks.md#static-path-discovery) and bounded non-secret file inspection instead.

## Broker connection and tokens

Broker storage is opt-in by URL, with this resolution order:

1. URL: `OMP_AUTH_BROKER_URL`, then `auth.broker.url` from the main global `config.yml` or existing `config.yaml`.
2. Token: `OMP_AUTH_BROKER_TOKEN`, then main-config `auth.broker.token`, then active config-root `auth-broker.token`.
3. URL configured but no resolvable token: hard error, never a silent fallback to local SQLite.

Connection values come from the main agent config, not project settings. Broker storage replaces stored credential layers only; runtime/model-registry/environment keys can still win. See [auth resolution](auth-resolution.md).

Main-config values accept a literal, a bare exact-case environment-variable name, or `!<command>`. Follow the dedicated upstream broker doc's bare-name syntax, not the contradictory `$ENV_NAME` wording in the general environment reference. **[INFERENCE]** The docs-linked `resolve-config-value.ts` looks up the exact configured string without stripping `$`. Missing/empty environment references remain literal, and command references execute at resolution; neither should be treated as a harmless inspection shortcut.

Token files belong to `getConfigRootDir()`: default `<home>/<PI_CONFIG_DIR or .omp>`, or its `profiles/<name>` directory for a named profile. Broker and gateway filenames are `auth-broker.token` and `auth-gateway.token`. Their documented mode is `0600`; new parent directories are `0700`, but existing parent permissions are not tightened.

Prefer reviewed environment or token-file references over literal tracked secrets. `config get` returns credential values unmasked and `config set` prints its saved value: inspect only redacted `omp config list --json` metadata. Never print token files or run `auth-broker token`/`auth-gateway token` to discover paths; those commands print or create tokens, and `--regenerate` rotates them.

## Status and cache limits

For an authorized network liveness check:

```sh
omp auth-broker status --json
```

Broker status health-pings unauthenticated `/v1/healthz`; success does not prove bearer authorization or provider credentials. It may resolve a command-backed connection value.

Normal broker clients can start from a fresh encrypted snapshot cache and synchronize in the background. One-shot commands may not observe recent credential changes or broker-token revocation. Cache-backed success is not live authorization proof; failed live discovery does not silently reopen local storage.

## Gateway operations

```sh
omp auth-gateway status --json
```

Gateway status checks local token-file presence and an authenticated broker snapshot, not the gateway listener or provider authentication. `omp auth-gateway check --json` constructs its own broker-backed store and probes selected credentials without calling a running gateway. Adding `--strict` also attempts suitable model completions and can consume quota; use only when explicitly authorized. Serve/check fetch live snapshots rather than the normal client snapshot cache.

For deployment, `omp auth-gateway serve` requires broker configuration. Keep inbound bearer authentication enabled. `--no-auth` disables it entirely and does not enforce a loopback bind; do not recommend it as a connectivity fix.

Logs normally identify the socket peer. Behind a reviewed, trusted reverse proxy, opt in with `--trust-proxy-headers` to accept forwarded peer identity for authenticated requests; unauthorized requests retain the socket peer. Do not enable it for untrusted direct clients. Keep tokens out of URLs and forwarded/logged/identity headers.

Treat login/logout/import/migration/serve/token commands as mutations or service operations, not inspection. See [auth resolution](auth-resolution.md) for their command-specific destinations and the import documentation/source discrepancy, and [validation](validation.md) for identity-aware model proof.

