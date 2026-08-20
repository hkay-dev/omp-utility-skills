# omp-utility-skills

Two portable skills for [Oh My Pi](https://omp.sh):

- **omp-docs** safely initializes or refreshes an upstream OMP source checkout and answers questions from current documentation.
- **omp-config** inspects and changes profile-aware OMP configuration without assuming a username, provider, home directory, or dotfiles system.

## Practical use cases

Use these skills together whenever you want to configure, customize, troubleshoot, or understand OMP. Instead of starting with a web search, `omp-docs` refreshes the official OMP repository and reads its documentation directly. This avoids stale search results, incomplete snippets, and instructions written for older versions.

Because the checkout also contains OMP's source code, `omp-docs` can trace documented behavior into the implementation. It can identify the setting, precedence rule, discovery provider, loader, or code path responsible for a behavior and explain why OMP works that way.

### How the two skills differ

| Skill | Role |
| --- | --- |
| `omp-docs` | Research and explanation. It establishes what the current OMP version supports and why by reading upstream docs and source. It is read-only by default. |
| `omp-config` | Safe action on the user's real installation. It resolves the active profile and project, inspects existing state, preserves unrelated configuration, makes the requested change, protects secrets, and runs the matching OMP validation. |

`omp-config` does not duplicate `omp-docs`. It turns the behavior established by `omp-docs` into a controlled change against the actual machine and verifies the result.

### Practical workflows

#### Add an MCP server from a GitHub repository

Give the agent the MCP server's GitHub URL. It can read that repository's README alongside OMP's current MCP documentation and source, determine whether the server uses stdio, HTTP, or SSE, identify its command, arguments, dependencies, and environment variables, then:

1. Ask only for information that is missing from the repository.
2. Choose project scope or the active OMP profile's user scope.
3. Preserve existing servers while updating `.omp/mcp.json` or the active agent directory's `mcp.json`.
4. Keep credentials out of tracked JSON by using environment or managed-auth references.
5. Run `/mcp reload`, `/mcp list`, and `/mcp test <name>` to prove OMP discovered and connected to the server.

#### Make a model or provider change

The docs skill confirms the current provider id, model syntax, role storage, and credential precedence. The config skill resolves the active profile, edits only the required setting or `models.yml` entry, and tests the exact requested model instead of treating a fallback as success.

#### Explain and fix an ignored setting

The docs skill traces user, profile, project, environment, and CLI precedence through the loader. The config skill inspects those real layers on the machine, identifies which one wins, changes the intended scope, and confirms the effective value.

#### Customize tools, approvals, themes, plugins, or extensions

The docs skill finds the current schema and implementation constraints. The config skill preserves the rest of the configuration, applies the smallest valid change, and exercises the affected OMP path.

#### Check advice before following it

The docs skill can determine whether a blog post, issue comment, or copied command still matches the installed OMP version. If it does not, it can show the current documented replacement and the source change that explains the difference.

Example requests:

```text
Add the MCP server from https://github.com/example/server to this project and test it.
Configure OMP to use this model for the smol role and verify the exact model.
Why does this project-level setting override my global setting? Fix it at the right scope.
Find the current docs and source code for how OMP discovers plugins.
Enable this tool only for this project without changing my global configuration.
Check whether these setup instructions still apply to the current OMP release.
```

## Install with OMP

OMP's Git plugin installer requires [Bun](https://bun.sh) on `PATH`.

```sh
omp plugin install github:hkay-dev/omp-utility-skills
```

Restart OMP or run `/reload-plugins` after installation. Re-run the same command to update both skills.

## Manual installation

Clone the repository, then copy either or both skill directories into a skill directory supported by your agent harness:

```sh
git clone https://github.com/hkay-dev/omp-utility-skills.git
cp -R omp-utility-skills/skills/omp-docs "$SKILLS_DIR/"
cp -R omp-utility-skills/skills/omp-config "$SKILLS_DIR/"
```

Set `SKILLS_DIR` to the harness's user skill directory. For OMP-native user skills, use the active agent directory reported by `omp config path` with a `skills` child.

## omp-docs checkout behavior

The docs skill stores upstream source in a dedicated `omp-source` child beneath a parent directory. By default, the parent is derived from the active OMP agent directory.

```text
<OMP root>/omp-source
```

An existing parent such as `~/.omp` is safe: the skill never initializes that runtime directory as the Git checkout. It creates or updates only the `omp-source` child and rejects a non-empty unrelated child directory.

Override the parent when needed:

```sh
OMP_DOCS_PARENT=/path/to/parent <skill-directory>/scripts/ensure-checkout.sh
```

## Local development

```sh
git clone https://github.com/hkay-dev/omp-utility-skills.git
cd omp-utility-skills
omp plugin link .
```

Restart OMP or run `/reload-plugins` after linking.

## Security

These skills never require credentials in the repository. `omp-config` uses OMP-native model checks and instructs agents not to print API keys, authorization headers, or token prefixes. `omp-docs` treats its upstream checkout as read-only and refuses to replace unrelated directories.

## License

MIT
