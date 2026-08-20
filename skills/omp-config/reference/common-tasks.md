# OMP Config Common Tasks

## Resolve the active paths

```sh
AGENT_DIR="$(omp config path)"
OMP_ROOT="$(dirname "$AGENT_DIR")"
CONFIG_FILE="$AGENT_DIR/config.yml"
MODELS_FILE="$AGENT_DIR/models.yml"
ENV_FILE="$AGENT_DIR/.env"
```

Use the resulting absolute paths with file tools. This respects OMP profiles and relocated agent directories.

## Inspect current state

```sh
omp config path
omp config list --json
omp auth-broker status --json
```

Read `config.yml` or `models.yml` only when the requested information is not fully represented by the CLI.

## Change persistent settings

Prefer schema-backed CLI writes:

```sh
omp config get <key>
omp config set <key> <value>
omp config get <key>
```

Reset to the schema default with:

```sh
omp config reset <key>
```

For a structure the CLI cannot represent, create a timestamped sibling backup of `config.yml`, apply a narrow YAML edit, then run `omp config list --json`.

## Configure a custom provider

Use values from the provider's official API documentation and current OMP docs. A typical `models.yml` provider entry contains:

```yaml
providers:
  <provider-id>:
    baseUrl: https://provider.example/v1
    api: <supported-api-transport>
    apiKey: <ENV_VAR_NAME>
    models:
      - id: <model-id>
        name: <display-name>
```

Keep the secret in the active OMP environment file or credential store. Prefer an environment-variable name in `models.yml` instead of a literal token.

Validate discovery and the exact model:

```sh
omp models find <model-id>
omp -p --no-session --no-tools --no-title --model <provider-id>/<model-id> "Reply with exactly: ok"
```

## Manage OAuth credentials

Discover supported provider ids before acting:

```sh
omp auth-broker list --json
omp auth-broker status --json
```

Then use the current documented command shape:

```sh
omp auth-broker login <provider-id>
omp auth-broker logout <provider-id>
omp auth-broker import <file-or-directory>
```

Logout removes the selected provider's active stored credential. Do not delete other provider entries.

## Configure broker mode

Resolve `$OMP_ROOT` first. Broker configuration may come from environment variables, hidden `config.yml` keys, or token files under the OMP root. Prefer secret indirection and validate with:

```sh
omp auth-broker status --json
```

## Project configuration

Project settings live at `<project>/.omp/settings.json`. Inspect user settings and project settings separately because project discovery can override or merge user-visible behavior.

Common project capability roots include:

- `<project>/.omp/skills/`
- `<project>/.omp/extensions/`
- `<project>/.omp/settings.json`

Do not move a user-wide model registry into a project unless current OMP documentation explicitly supports it.
