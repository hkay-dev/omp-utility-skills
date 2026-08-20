# Model Configuration Rules

Resolve the active model configuration path first:

```sh
AGENT_DIR="$(omp config path)"
MODELS_FILE="$AGENT_DIR/models.yml"
```

## Provider overrides

A generic provider override uses the provider and model ids documented by OMP or supplied by the user:

```yaml
providers:
  <provider-id>:
    apiKey: <ENV_VAR_NAME>
```

`apiKey` may identify an environment variable or, where supported, contain a literal token. Prefer environment-variable or credential-store indirection so the tracked model configuration does not contain secrets.

Do not assume one provider's key precedence applies to another. Confirm current resolution behavior through `omp-docs` when the distinction affects a change.

## Common model tasks

```sh
omp config get modelRoles --json
omp models find <provider-or-model-query>
```

`modelRoles` is a record-valued setting. To change one role without replacing its siblings, edit the resolved `config.yml` mapping narrowly or use OMP's model selector. Use `omp config list --json` to discover the current schema before changing role overrides, provider order, or disabled providers.

## Validation

After editing `models.yml`:

```sh
omp models find <provider-or-model-query>
omp -p --no-session --no-tools --no-title --model <provider>/<model> "Reply with exactly: ok"
```

The smoke check must return the expected text and exit successfully. A different fallback model does not validate the requested model, so inspect the command output for the selected provider/model when failures occur.
