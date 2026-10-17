# API Key and OAuth Rules

## Inspect before changing

Resolve directories and filenames with the [common path recipe](common-tasks.md). Keep the same target cwd, environment, and explicit `--profile` on every command. The agent directory is not a universal root: an independent default-profile `PI_CODING_AGENT_DIR` does not move the config root, and initialized XDG data directories can place `agent.db` elsewhere.

The commands below are authorized operational inspection, not strict no-mutation auditing. `config list` uses writable settings initialization and can migrate/quarantine files or write database/marker state. For a static audit use [static path discovery](common-tasks.md#static-path-discovery) and bounded non-secret file inspection instead.

```sh
omp auth-broker list --json
omp config list --json
```

The broker list is the registered sign-in provider catalog, not stored accounts or proof of valid auth. Config list exposes redacted credential metadata. **`omp config get <credential-key>` returns secrets unmasked, including JSON; `config set` prints the saved value.** Do not inspect credentials with get or pass literal secrets in command arguments.

## Credential precedence

First matching source wins:

1. Runtime API-key override, such as `--api-key` (never put literal secrets in its command arguments).
2. Explicit provider `apiKey` in the selected model registry.
3. Stored OAuth credentials, refreshed when needed.
4. Login-sourced stored API key.
5. Extension config fallback for a provider with its own login flow.
6. Provider environment-variable mapping.
7. Other stored API key, such as a migrated copy.

Broker mode replaces only stored layers 3, 4, and 7. Explicit model-registry keys remain tier 2; an extension login fallback is not the same kind of pin. Changing one source does not disable higher-precedence sources or prove which account a later request uses.

Provider mappings differ. Anthropic prefers `ANTHROPIC_OAUTH_TOKEN` over `ANTHROPIC_API_KEY`; with Foundry enabled, its Foundry key takes precedence. Consult the current provider documentation for the selected provider, not another provider's variable names.

## Environment and secret references

OMP dotenv precedence is first nonempty value: inherited process environment, then launch-cwd `.env`, active agent `.env`, active profile config-root `.env`, and home `.env`. Empty inherited values can be filled; nonempty ones are not overwritten. Bun may preload dotenv variants before this loader. The OMP parser leaves variable references literal; parsed `OMP_*` keys mirror to `PI_*` and replace the same-file alias.

Model `apiKey` and broker config references accept a bare exact-case variable name, not `$NAME`. A missing or empty variable falls back to the name as a literal value. Check presence without exposing it, for example for an already-loaded launch environment:

```sh
if [ -n "${MY_PROVIDER_API_KEY:-}" ]; then
  printf '%s\n' 'credential variable present'
else
  printf '%s\n' 'credential variable missing or empty'
fi
```

This checks the current shell only, not OMP's later dotenv loading. Do not source dotenv files as shell scripts or print their contents. `!<command>` references execute a shell command at credential resolution; review them before any request or online status probe.

## OAuth operations

Choose provider ids from the sign-in catalog and confirm the destination before a requested mutation:

```sh
omp login <provider-id>
omp auth-broker login <provider-id>
omp auth-broker login <provider-id> --via=user@host
omp auth-broker logout <provider-id>
omp auth-broker import <file-or-directory>
```

- Session `/login [provider]` and terminal `omp login [provider]` save to the active session store: local `agent.db` or the configured broker. Login may refresh the catalog online.
- `auth-broker login` administers the local vault on the host running it, even if a remote broker URL is configured. `--via=user@host` runs that login on the selected host. Its `--dry-run` applies only with `--via`, not a local login.
- `auth-broker logout` disables that local host's active provider rows, retaining tombstones; it does not delete them or generically log out of a configured remote store.
- Import destination is an upstream discrepancy. The dedicated broker doc says local SQLite. **[INFERENCE]** Its linked `packages/coding-agent/src/cli/auth-broker-cli.ts` implementation resolves broker configuration and uploads there when configured, otherwise importing locally. Verify the installed implementation before importing; never assume always-local behavior. `--dry-run` still reads credential files and is not secret-free inspection.

Do not run login, logout, import, migration, or token commands as an auth inspection step.

## API-key validation

Never call provider APIs with scripts that expose tokens, prefixes, or authorization headers. For an authorized request against the intended concrete model, follow [identity-aware smoke validation](validation.md), projecting only safe terminal response fields and exit status rather than full JSON events.

A successful response proves that model request worked with some resolved credential, not that a newly changed source or account was used. Retry fallback can also change the model; require identity evidence on success. The canonical smoke's flags do not provide full process/tool/network isolation. Preserve redacted provider errors without rewriting unrelated configuration. Do not run a model smoke for skill edits.
