# OMP Config Common Tasks

## Resolve the active paths

### Static path discovery

For a strict no-mutation audit, do not call `omp config path/list/get`: all currently enter writable settings initialization. Consult version-matched `docs/config-usage.md` and `packages/utils/src/dirs.ts` through `omp-docs`, using an already-present checkout or a separately authorized refresh.

Preserve the target cwd and its known path-selection environment. Select the explicit launch `--profile` first; otherwise `OMP_PROFILE` wins when defined (even empty), then legacy `PI_PROFILE`. Empty/whitespace or `default` selects the default profile. Current documented layout:

| Directory | Static selection |
| --- | --- |
| Base config root | `<home>/<PI_CONFIG_DIR or .omp>`; `PI_CONFIG_DIR` is a home-relative directory name |
| Named profile config root | `<base>/profiles/<name>` |
| Agent settings directory | `<active config root>/agent`; default profile alone can use the resolved `PI_CODING_AGENT_DIR` override |
| Data/state/cache | Existing XDG category roots can differ; check documented category/profile existence without creating them |
| Project settings | `<target cwd>/.omp/config.yml` and existing legacy `.omp/settings.json`; no ancestor settings search |

Directory-affecting variables may already have been loaded by the target process. Do not source dotenv files, execute command-backed values, initialize XDG, open credential databases/token files, or start a session to discover paths. If the effective environment or version-specific resolver is unknown, report the path ambiguity instead of guessing or calling writable CLI metadata commands.

Select an existing `config.yml` before `config.yaml`, and `models.yml` before `models.yaml`. Inspect only the relevant non-secret structure in those already-existing files with bounded file tools. A malformed file is diagnostic evidence: preserve it in place, do not invoke startup to quarantine it. Static inspection does not prove effective merged settings, runtime discovery, auth, or provider behavior.

### Operational path discovery

The recipe below is for authorized operational reads or changes, not strict static audits. `config path` can migrate settings, write markers/database state, or quarantine malformed files before returning a path.

Preserve the target session's cwd, environment, and explicit profile for every command. In the same shell, define `omp_target` as follows; if the session used `--profile`, use the second definition instead and set `PROFILE` to that known name:

```sh
omp_target() { command omp "$@"; }
# Explicit-profile alternative:
# omp_target() { command omp --profile "$PROFILE" "$@"; }

AGENT_DIR="$(omp_target config path)"
CONFIG_FILE="$AGENT_DIR/config.yml"
if [ ! -e "$CONFIG_FILE" ] && [ -e "$AGENT_DIR/config.yaml" ]; then
  CONFIG_FILE="$AGENT_DIR/config.yaml"
fi
MODELS_FILE="$AGENT_DIR/models.yml"
if [ ! -e "$MODELS_FILE" ] && [ -e "$AGENT_DIR/models.yaml" ]; then
  MODELS_FILE="$AGENT_DIR/models.yaml"
fi
ENV_FILE="$AGENT_DIR/.env"
```

Use these absolute paths with file tools. An independent `PI_CODING_AGENT_DIR` is not the config root; named profiles ignore that override. Data such as `agent.db` may be in an initialized XDG data directory. Resolve token roots through [broker and gateway](broker-gateway.md), not `dirname "$AGENT_DIR"`. Re-resolve after a profile, cwd, or environment change.

## Inspect current state

For authorized operational inspection only (settings/discovery side effects are permitted):

```sh
omp_target config list --json
omp_target models find <provider-or-model-query>
```

Read the selected configuration files only when CLI metadata is insufficient. Credential fields are redacted in `list --json`; explicit `get`, including JSON, is unmasked. `set` also prints the saved value. Never get credential values or pass literal secrets as command arguments. For broker diagnostics, see [broker and gateway](broker-gateway.md); status is a network operation, not a credential test.

## Change persistent settings

Discover exact registered setting ids and types with `omp_target config list --json`. For non-secret values:

```sh
omp_target config get theme.dark --json
omp_target config set compaction.enabled false
omp_target config get compaction.enabled --json
omp_target config reset compaction.enabled
```

`theme.dark` is a registered leaf; `theme` is not shorthand. Array settings accept quoted JSON arrays, for example `omp_target config set enabledProviders '["codex"]'`; record settings accept quoted JSON objects, for example `omp_target config set tools.approval '{"bash":"prompt"}'`. These replace the whole global setting: preserve intended global array members and record siblings, not a copied effective value containing project or overlay entries. `tools.approval.bash` is not a separate setting id. Unknown handwritten keys do not become settings.

CLI `set/reset` writes the active-profile global file. Reset removes that override; remaining layers or the default supply the effective value. Precedence is `defaults < global < project < overlays < runtime < setting env`, with setting-specific fallback-env exceptions. Objects deep-merge; arrays and scalars replace. `PI_CONFIG_FILES` overlays load before repeated launch `--config` files; later overlays win. Inspect write notices and JSON `overriddenBy`/`fallbackEnv` metadata before assuming the saved value is effective.

For project scope or structures the CLI cannot express, back up the actual selected file and make a narrow edit. Model-selector role assignments with `modelRoleStorage: project` are the project-write exception, not ordinary `config set`. Follow [validation](validation.md#settings): warnings, type errors, startup quarantine, or last-good live reload can make a successful `list/get` insufficient.

## Add an MCP server from a repository

Review repository instructions and dependencies before executing or enabling anything. Establish an explicit transport:

- `type: "stdio"` requires `command`; check arguments, cwd, and environment.
- `type: "http"` or `type: "sse"` requires `url`; check headers and authentication. Prefer HTTP for new hosted servers.
- Never set both `command` and `url`; do not rely on discovery's inferred transport to validate a raw definition.

Inspect the winning source before adding a duplicate. Native priority is project `.omp/mcp.json`, project `.omp/.mcp.json`, then the active-profile user equivalents under `$AGENT_DIR`. Native sources precede extensions and imported Claude, Codex, Gemini, OpenCode, Cursor, Windsurf, VS Code, and plugin sources; root `mcp.json`/`.mcp.json` are lowest-priority fallbacks. Names are first-wins, not merged; equivalent differently named entries can also be shadowed. OpenCode's own internal layers deep-merge.

Choose native user `$AGENT_DIR/mcp.json` or target-cwd `.omp/mcp.json`, back up an existing file, and preserve unrelated entries. Check user `disabledServers`/`enabledServers`, source `enabledProviders`/`disabledProviders`, and `mcp.enableProjectConfig` before diagnosing a missing entry. The project switch excludes all project sources before deduplication. Built-in browser/Exa integration can filter matching MCP definitions; consult current `docs/mcp-config.md` through `omp-docs` before changing those integrations.

Managed stored-credential injection is OAuth. `auth.type: "apikey"` does not load or inject a stored API key; supply API keys through stdio `env` or remote `headers` with reviewed indirection. Native `${VAR}`/`${VAR:-default}` placeholders expand at discovery; unresolved placeholders remain literal. Before connection, a whole-value environment name resolves only when nonempty, otherwise the name is sent literally. A leading `!` executes a shell command. Check presence without printing secrets; do not assume missing names fail closed. Portable Agent Plugins differ: env/header values stay literal and do not execute `!` or dereference bare names.

For HTTP/SSE OAuth, a definition-only entry plus authorized `/mcp reauth <name>` can keep refresh material out of project JSON. Binding is profile-and-URL scoped, not project scoped; another checkout with the same URL can use that profile's credential. Explicit Authorization headers disable automatic URL-keyed fallback, though a resolved explicit credential id can still supply OAuth. Review committed definitions before opening a credential-bearing profile.

After an authorized change, follow [MCP validation](validation.md#mcp-servers). Reload disconnects all managed servers; test can launch a process or contact an endpoint. Neither is a read-only audit command.

## Set up a subagent

Start with the requested outcome. Ask only material questions absent from context: role, read/edit access, user/project scope, speed/model/cost preferences, and foreground/background execution.

Prefer a bundled `scout`, `reviewer`, `security-reviewer`, `task`, or `sonic` when it fits. For a distinct custom role, use supported frontmatter and tool controls from current `docs/task-agent-discovery.md` through `omp-docs`:

- User: `$AGENT_DIR/agents/<name>.md`
- Project: nearest project ancestor's `.omp/agents/<name>.md`

Discovery is nearest native project, native user, enabled OMP extension roots, gated Claude marketplace roots, then bundled; exact case-sensitive names are first-wins. Direct `.claude/.codex/.gemini/agents` roots are not native definitions. Project agent discovery walks ancestors, unlike cwd-only native settings. Extension arrays replace rather than concatenate. `disabledProviders` gates sources; foreign user sources generally require `enabledProviders` opt-in, with documented plugin-origin exceptions.

Saved `task.agentModelOverrides` precedes frontmatter models; role aliases expand through `modelRoles`. `task.agentPrewalk` and `task.agentAdvisor` (`on`/`off`/pattern) override frontmatter. No bundled agent sets prewalk; generic `task.prewalk` defaults off, and unavailable prewalk targets are skipped. Top-level `prewalk.enabled` is separate from task prewalk; subagents default to no advisor. Confirm selected properties in `/agents`, then apply [agent validation](validation.md#agents-and-subagents): discovery alone does not establish runnability.

## Configure a custom provider

Use official provider documentation and [models config](models-config.md) for the selected `$MODELS_FILE`. A typical entry is:

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

Prefer an exact-case environment-variable name over a literal secret. Verify its resolved value is present and nonempty without printing it; otherwise OMP can send the configured name as a literal token. The active agent `.env` is not the only env source. Read the credential and dotenv precedence in [auth resolution](auth-resolution.md) before changing auth. Validate concrete catalog selection and, only when authorized, run the canonical [model smoke](validation.md#models-and-credentials).

## Manage OAuth credentials

Discover registered sign-in provider ids with `omp_target auth-broker list --json`; this is not a stored-account or credential-health list. Before login, logout, or import, read [auth resolution](auth-resolution.md) for command-specific local/session/broker destinations. `auth-broker logout` disables its host's provider rows and retains tombstones; it is not universal remote logout or credential deletion. Preserve other providers.

## Configure broker mode

Read [broker and gateway](broker-gateway.md) for URL/token precedence, active config-root token paths, and bounded status checks. Do not derive the root from an independently relocated agent directory or run token-print/create commands to discover it. Broker health does not establish provider authorization or credential validity.

## Project configuration

Native project settings are `<cwd>/.omp/config.yml`, merged over legacy `<cwd>/.omp/settings.json`. Native settings do not walk ancestors. Inspect global and project layers separately; imported tool settings can also contribute read-only layers.

Common project capability roots are `.omp/skills/` and `.omp/extensions/`; agent discovery has its separate nearest-ancestor rule above. Arbitrary project overrides require a narrow direct edit. Only model-selector role assignments with `modelRoleStorage: project` write affected project `modelRoles`; ordinary CLI setting writes remain global. Do not move the user model registry into a project without current documented support.

## Claude Swap and OpenUsage account handoff

Use the founder setup guide and host-specific Claude Swap/OpenUsage note when available. Claude Code/cswap and OMP need separate sign-ins. New native OMP logins also need an available slot in the installed account plugin; inspect its supported slots before promising new named views.

1. Confirm each saved email and organization UUID and the agreed display name. `cswap add --alias` sets a CLI alias, not the OpenUsage title. Back up `~/.claude-swap-backup/sequence.json` privately, change only the matched account's `organizationName`, and preserve account IDs, sequence, active slot, and credentials. Batch all intended label edits before restarting. Do not mark the account setup complete after registration alone.
2. Before startup or a live check, tell the user that OpenUsage may request Keychain approval more than once and that the user must enter any password in the macOS dialog, never in chat. The observed six-account setup prompted four or five times; the dialog items/requesters were not recorded, so don't infer one prompt per account or promise a fixed count. A metadata-file edit itself doesn't access Keychain.
3. Let the user inspect the requested Keychain item and executable. OpenUsage documents `Claude Safe Storage` access for Claude Desktop credentials, but not every prompt is necessarily that item. Only the user can decide whether to grant continuing access with Always Allow to a recognized requester/item. Never automate password entry, unlock the whole Keychain, change access-control lists, export tokens, or use repeated refreshes to bypass a denial.
4. Quit OpenUsage normally, confirm that its process has exited, then launch it once in the background. On macOS, `osascript -e 'tell application "OpenUsage" to quit'` can return before termination finishes. Check `pgrep -x OpenUsage` separately and only use `open -g -a OpenUsage` after exit. Do not chain quit and launch blindly; error -600 was observed with that sequence.
5. Use one verification route at a time. Prefer the app's initial refresh and dashboard titles. Let the user finish approvals before another check. Don't start a CLI refresh alongside the app refresh or repeatedly relaunch while a dialog is pending. If the UI cannot be inspected in the background, record that limit rather than activating the app or calling another credential-reading route just for visual proof.
6. The optional `openusage` CLI shares a five-minute cache. Even a normal read can refresh stale/missing entries and access credentials. `openusage claude` selects every Claude card, not just the newly added account. Old cached titles do not mean the metadata edit failed. Prefer a normal app refresh; use `--force` only for a remaining need that the user has approved after the credential-access warning. If only one account needs that check, pass its discovered exact card ID, never an alias or an ID copied from another machine. This narrows requested cards but does not guarantee one Keychain prompt.
7. Check names and live quota/auth separately. Record the changed metadata, observed titles, cache freshness, errors, human approvals and any unverified surface. Stop on denied access; do not convert it into a token-import or re-login task. Re-adding a saved account can replace local metadata, so check its `organizationName` again afterward.

Version-matched contracts: [OpenUsage Claude accounts](https://github.com/robinebers/openusage/blob/v0.7.15-beta.1/docs/providers/claude.md) and [CLI cache and selectors](https://github.com/robinebers/openusage/blob/v0.7.15-beta.1/docs/cli.md).
