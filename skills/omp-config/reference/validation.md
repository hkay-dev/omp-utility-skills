# OMP Config Validation

## Resolve paths

Choose the operating mode before path discovery. Strict no-mutation audits use [static path discovery](common-tasks.md#static-path-discovery), existing files, and current path documentation; do not invoke ordinary `config path/list/get` or session/model/auth discovery. The CLI currently enters writable `Settings.init()` even for `path`, while `Settings.loadReadOnly()` is a source API rather than a CLI option.

For authorized operational inspection or changes, use the [common path recipe](common-tasks.md#operational-path-discovery) to select existing `config.yaml`/`models.yaml` when their `.yml` counterparts are absent. Keep the same target cwd, environment, and explicit profile on every command and session below; `omp_target` is the profile-preserving wrapper defined there. Agent, config-root, and XDG data paths are distinct.

These checks are for authorized configuration changes, not static skill audits. Metadata loads can write database/marker state, migrate legacy settings, or quarantine invalid files. Do not run model requests, MCP reload/test, login, or credential mutations merely to validate documentation.

## Settings

For non-secret registered settings after a write or direct edit:

```sh
omp_target config get <registered-key> --json
omp_target config list --json
```

Credential `get` output is unmasked, including JSON; `set` prints its saved value. Use redacted `list --json` metadata and a bounded behavior check instead. Never put literal secrets in command arguments.

Verify persistence separately from effective behavior. `set/reset` writes global config; project, overlays, runtime, and setting env can still win. Read write notices and `overriddenBy`/`fallbackEnv` metadata. Reset removes the global override, not every layer. See [common settings tasks](common-tasks.md#change-persistent-settings) for precedence and record-preserving writes.

Inspect warnings and stderr, not just exit status: ordinary wrong-typed values can warn and read as defaults; explicit validators can reject them. Writable startup can quarantine malformed/non-mapping persistent YAML to a `.broken-*` sibling and fail. Live reload instead keeps the last-good invalid layer and warns, so successful `list/get` does not prove the edit was accepted. Preserve the invalid file/diagnostic evidence, restore only the intended known-good backup, and reapply a narrower change. Startup-only work requires a fresh target session; live reload does not rerun it.

## Models and credentials

First confirm the exact concrete `<provider>/<model>` exists with `omp_target models find <query>` or catalog JSON. A qualified selector can still fall through to provider-scoped fuzzy matching if there is no exact match. Registry discovery alone does not exercise credentials.

The shared smoke uses `-p --mode json --no-session --no-tools --no-title --model <provider>/<model> "Reply with exactly: ok"`. Preserve explicit `--profile` via `omp_target` and project stdout as below; never display the raw event stream.

For an authorized model/auth change, this Bash example requires `jq`; replace both placeholders with the confirmed concrete provider and model ids:

```bash
(
  command -v jq >/dev/null || { printf 'jq is required\n' >&2; exit 127; }
  set +e
  set -o pipefail
  provider='<provider>'
  model='<model>'
  omp_target -p --mode json --no-session --no-tools --no-title \
    --model "$provider/$model" "Reply with exactly: ok" |
    jq -n --arg provider "$provider" --arg model "$model" '
      reduce inputs as $e (null;
        if $e.type == "message_end" and $e.message.role == "assistant"
        then $e.message else . end)
      | if . == null then null else
          {provider, model, stopReason,
           text: ([.content[] | select(.type == "text") | .text] | join(""))}
        end
      | . as $result
      | $result, (if $result.provider == $provider and $result.model == $model
                     and $result.text == "ok" and $result.stopReason == "stop"
                  then empty else error("model smoke acceptance failed") end)'
  statuses=("$?" "${PIPESTATUS[@]}")
  printf 'exit=%s omp_exit=%s projection_exit=%s\n' \
    "${statuses[0]}" "${statuses[1]}" "${statuses[2]}"
  exit "${statuses[0]}"
)
```

Require exit 0, successful projection, a terminal assistant message with text exactly `ok`, the intended provider AND concrete model on success, and normal successful `stopReason: "stop"`. Missing identity, a different fallback identity, `length`, `toolUse`, `error`, or `aborted` is not exact-model proof. Report only exit/projection status and those four terminal fields; do not print full events, thinking, credentials, headers, token prefixes, or raw failure dumps.

`--no-tools` disables built-in tools only; `--no-session` disables transcript persistence; `--no-title` disables title generation. They do not promise no hooks/custom capabilities, no MCP startup, no config/cache writes, no auxiliary requests, or a single model call.

For a deliberately narrower auth smoke, an optional temporary launch `--config <file>` overlay can set:

```yaml
advisor:
  enabled: false
retry:
  modelFallback: false
```

Add `--no-prewalk` to prevent the top-level handoff. Preserve any required provider extension: `--no-extensions` disables ambient discovery but explicit `-e` paths still work, and it is not whole-process isolation. Extensions, MCP, and other discovery have separate controls. Do not disable the provider being tested or claim these controls eliminate all side effects.

A successful request proves the observed model path accepted some effective credential, not that the intended new credential/account was used. A higher-precedence source or another stored account can mask the changed source. Read [auth resolution](auth-resolution.md) before making credential-source claims; do not rewrite unrelated settings to hide provider rejection.

## OAuth and broker state

`omp_target auth-broker list --json` lists registered sign-in providers, not stored accounts or credential health. See [auth resolution](auth-resolution.md) for command-specific mutation destinations and logout tombstones.

Read [broker and gateway](broker-gateway.md) before status checks. Broker status is an unauthenticated health ping, not bearer authorization or provider-credential proof; status can also resolve command-backed configuration. Gateway status/check have different scopes and are not interchangeable listener tests. Use the authorized exact-model smoke above for model behavior, with its credential-source limitation.

## MCP servers

After an authorized MCP change, use the same target-profile/cwd session:

```text
/mcp reload
/mcp list
/mcp test <name>
```

Reload disconnects all managed servers, rediscovers with startup filters, and refreshes session tools. It can leave slower connections pending after its bounded window; pending is not automatically failure. Test connects to the named server and can launch its executable or contact its endpoint. Neither command is read-only.

Confirm the intended winning source and resolved transport in `/mcp list`; account for imported sources, duplicate winners, user enable/disable lists, provider gates, and the project switch in [common MCP tasks](common-tasks.md#add-an-mcp-server-from-a-repository). Valid JSON does not prove dependencies, endpoint reachability, or auth. A successful test establishes that connection at that time, not correctness of every server tool or credential source.

## Agents and subagents

After an agent change, open `/agents` in the target session and confirm:

- The expected winning user/project/extension/bundled definition, not merely its file.
- Model/thinking/tool access and `task.agentModelOverrides` versus frontmatter resolution.
- Effective per-agent prewalk/advisor overrides and separate top-level controls.
- Source gating through `enabledProviders`/`disabledProviders`.

See [common agent tasks](common-tasks.md#set-up-a-subagent) for bundled names, exact-name precedence, and nearest-ancestor discovery versus cwd settings. Discovery does not establish runnability: disabled-agent settings, parent spawn policy, blocked recursion, depth limits, plan mode, and extension dispatch hooks can restrict or change execution. When execution behavior is the requested change, exercise an authorized minimal task with that selected agent; `/agents` alone is metadata evidence.

## Packaged-extension installed-runtime proof

This is an authorized runtime check, not a strict no-mutation audit. Use [omp-docs](../../omp-docs/SKILL.md#packaged-extension-release-proof) to select contracts matching the installed executable. Reuse the active package owner's capture helper rather than introducing another test framework.

1. Supply the real reviewed package archive, its hash/name/version, and the installed compiled executable with an expected version. Don't replace either with a source launcher, a worktree extension, a fixture, or a different version.
2. Before imports or subprocesses, bind a unique private fixture's HOME, cwd, temporary, agent and XDG roots. Whitelist environment values; exclude inherited profiles, overlays, provider keys, broker settings and session variables. In OMP 18.6.0, precreate `omp` under XDG data/state/cache roots; an agent-dir override alone doesn't isolate plugins. Never copy live config, models, auth or stashes. Local UI commands still require a selected catalog entry, so a no-inference fixture may declare synthetic metadata with no credentials and a reserved `.invalid` endpoint. This isn't backend or inference evidence.
3. Install the reviewed archive and exact matching SDK peers into a disposable consumer with lifecycle scripts disabled, record installed peer versions, then register that installed directory with `omp plugin link`. Linking extracted bytes alone doesn't provide runtime dependencies such as `pi-tui`. OMP 18.6.0 `plugin install` routes local paths to directory linking, not tarball installation. Don't substitute worktree imports when loading fails.
4. Do not pass `-e <source>` or `--no-extensions`: those bypass the installed registry-loader path being checked. Supported 18.6.0 startup flags are `--no-session --no-tools --no-lsp --no-title --no-prewalk --no-skills --no-rules`. They reduce activity but are not a filesystem/network sandbox. Use no positional prompt or print request.
5. Use [tui-recording's consumer proof](../../tui-recording/reference/recipe.md#packaged-omp-consumer-proof) to exercise the changed shortcuts, TUI and isolated state, then close OMP before removing only that run's fixture. No provider/model call is needed for local stash/restore/settings behavior. Queue submission or inference requires a separately authorized check.

Keep setup **prepared** until compiled consumer assertions pass. Successful linking or a settings manifest doesn't establish startup. Report exercised shortcuts, TUI and storage separately from physical OS key delivery, inference, publication, upgrades and restart durability. Record dependency installation when exercised; don't imply that linking alone supplied it. Private roots aren't an OS/network sandbox.

## Backups

Before directly editing an existing file, create a timestamped sibling backup of the actual selected filename, including `.yaml` when that is loaded. Preserve permissions and unrelated content. Backups containing secrets remain local and untracked; never print their contents during validation.

## Behavior checks

Report only the check actually exercised and its bounded result. Settings metadata is not proof that every value was accepted; model discovery is not auth; exact-model success is not credential-source proof; broker liveness is not authorization; MCP connection is not tool correctness; agent discovery is not execution availability. Skill-only edits require documentation/static validation, not provider calls or credential mutations.
