# OMP Config Validation

## Resolve paths

```sh
AGENT_DIR="$(omp config path)"
OMP_ROOT="$(dirname "$AGENT_DIR")"
```

Use those absolute paths for any file-level validation.

## Settings

After `omp config set`, `omp config reset`, or a direct `config.yml` edit:

```sh
omp config get <key>
omp config list --json
```

If a direct YAML edit prevents OMP from loading settings, restore the timestamped sibling backup and reapply a smaller change.

## Models and credentials

After changing `models.yml` or authentication state:

```sh
omp models find <provider-or-model-query>
omp -p --no-session --no-tools --no-title --model <provider>/<model> "Reply with exactly: ok"
```

The smoke check is valid only when the requested model path returns exactly `ok` and the command exits successfully. Do not expose keys, authorization headers, credential records, or token prefixes while reporting failures.

## OAuth and broker state

```sh
omp auth-broker list --json
omp auth-broker status --json
```

The provider list describes supported or registered providers; it does not by itself prove that a usable credential exists. Validate the exact requested provider/model behavior when credentials change.

## MCP servers

After adding or changing an MCP server, validate it in an active OMP session:

```text
/mcp reload
/mcp list
/mcp test <name>
```

Confirm that `/mcp list` reports the intended user or project source. A valid JSON file does not prove that the server process starts, its endpoint is reachable, or authentication succeeds; `/mcp test` exercises the connection.

## Backups

Before directly editing an existing config file, create a timestamped sibling backup such as:

```text
config.yml.YYYYMMDD-HHMMSS.bak
models.yml.YYYYMMDD-HHMMSS.bak
mcp.json.YYYYMMDD-HHMMSS.bak
```

Preserve file permissions and unrelated content. Backups containing secrets remain local and untracked.

## Behavior checks

A schema check proves parsing. A model smoke proves model selection and authentication. A broker status check proves broker connectivity. `/mcp test` proves a server can connect. Run the check that matches the changed behavior rather than substituting an easier command.
