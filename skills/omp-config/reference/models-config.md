# Model Configuration Rules

Use the [common path recipe](common-tasks.md) to resolve the active agent directory and existing files. Select `models.yml` first, or existing `models.yaml` when it is absent; preserve an existing alternate filename. Keep the target cwd, environment, and explicit `--profile` selection for every command below.

CLI config/model discovery below is for authorized operational inspection or changes and can initialize settings, migrate/quarantine files, or discover providers. For strict no-mutation auditing use [static path discovery](common-tasks.md#static-path-discovery) and existing non-secret structures, not these commands.

## Provider overrides

A generic provider override uses the provider and model ids documented by OMP or supplied by the user:

```yaml
providers:
  <provider-id>:
    apiKey: <ENV_VAR_NAME>
```

Use a bare, exact-case environment-variable name, not `$ENV_VAR_NAME`. If that variable is missing or empty, OMP uses the configured name as the literal token; indirection does not fail closed. Check nonemptiness without printing the value before launching. See [auth resolution](auth-resolution.md) for source precedence and dotenv loading.

`!<command>` is also supported, but executes a shell command when credentials resolve. Do not execute command-backed secrets as an inspection shortcut. Prefer reviewed secret references or the credential store over literal tokens in tracked YAML.

## Common model tasks

```sh
omp config get modelRoles --json
omp models find <provider-or-model-query>
```

Roles live under `modelRoles` in the resolved global `config.yml`/`config.yaml` or `<cwd>/.omp/config.yml`, not in the model registry. Legacy project `.omp/settings.json` remains lower priority than project YAML.

`modelRoles` is a record-valued setting, not a set of individually registered CLI keys. Preserve sibling entries with a narrow edit of the intended layer or `/model` Roles assignment. Do not copy an effective merged record into global settings: project and overlay entries can leak into that write. Ordinary `omp config set/reset` writes global settings; reset removes that override, not every higher-priority value.

Picker role writes follow `modelRoleStorage`: `global` saves in the active profile, while `project` updates only affected roles in cwd `.omp/config.yml`. Missing project roles fall back to global roles. Assigning a nondefault role normally does not switch the active conversation; assigning `default` normally does, unless a higher layer wins. The session-only picker does not rewrite roles.

Quote YAML aliases such as `plan: "@slow"`. Chat selectors support `:off|minimal|low|medium|high|xhigh|max|auto|inherit`. Ordered comma-separated primary candidates select the first available match; request-failure fallbacks belong separately in `retry.fallbackChains`. Preserve siblings in both records and distinguish saved scope from effective overlay values.

## Workload kinds

Ordinary `omp models` lists chat models. Inspect nonchat workloads by catalog kind:

```sh
omp models --kind all --json
omp models --kind image --json
```

Kinds are `chat`, `tiny`, `image`, `tts`, `stt`, `search`, and `judge`. Roles `image`, `speech`, `dictation`, `web`, and `judge` select their corresponding runners, without chat thinking suffixes. `tiny` and `memory` accept tiny or chat models; `judge` also accepts tiny/chat. `vision` is chat image analysis, not image generation, and requires image-input support. Custom roles are chat roles. Use `modelRoles` and role-specific fallback chains, not retired `providers` backend selectors.

## Model presets

`modelPresets` stores named `{ modelRoles, defaultThinkingLevel }` snapshots:

```text
/modelpreset save <name>
/modelpreset switch <name>
/modelpreset list
/modelpreset delete <name>
```

Save writes only the named entry globally, capturing effective roles, including session model overrides, plus the configured default thinking level, not the live session level. Same-name presets resolve whole from the highest layer, never by merging their roles.

Switch writes roles in `modelRoleStorage` scope, clears omitted roles there, replaces session model overrides, and writes `defaultThinkingLevel` globally. Other layers can still win; read the switch's overriding-layer notice. An unavailable preset default leaves state unchanged. The session selects the resulting default and its suffix or preset thinking level; a project/overlay thinking override can return on restart. A null overlay/runtime preset hides the name; a null project entry does not hide the global preset.

## Service tiers

Discover registered keys with `omp config list --json`. Use `tier.openai`, `tier.anthropic`, `tier.google`, `tier.subagent`, `tier.advisor`, and the sparse record `task.agentServiceTierOverrides`, not retired `serviceTier` keys. Preserve sibling agent overrides.

```sh
omp config get tier.openai --json
omp config set tier.openai ultrafast
```

These are nonsecret global-setting commands; higher layers can still override the saved tier. In a session, `/fast ultra` selects Ultrafast only for supported models: direct OpenAI API models and Codex models whose discovery advertises it. Do not assume OpenRouter, another provider family, or every Codex model supports it. `--service-tier ultrafast` is a one-session OpenAI override, not a persistent write.

## Validation

After an authorized model-registry edit, inspect the exact catalog entry with `omp models find <provider-or-model-query>`, adding the relevant `--kind` for nonchat models. This is not an authentication check.

For an authorized provider request, follow the canonical [identity-aware smoke procedure](validation.md). Successful exit and `ok` alone are insufficient: terminal provider/model identity and successful `stopReason` must match. Do not duplicate the recipe here or run a model request merely to edit this skill. The smoke does not prove which credential source or stored account was used.
