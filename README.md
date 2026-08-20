# omp-utility-skills

Two portable skills for [Oh My Pi](https://omp.sh):

- **omp-docs** safely initializes or refreshes an upstream OMP source checkout and answers questions from current documentation.
- **omp-config** inspects and changes profile-aware OMP configuration without assuming a username, provider, home directory, or dotfiles system.

## Practical use cases

Use these skills together whenever you want to configure, customize, or understand OMP. Instead of relying on a web search, `omp-docs` refreshes the official OMP repository and reads its documentation files directly. This avoids stale search results, incomplete snippets, and advice for older versions.

Because the checkout also contains OMP's source code, the skill can trace documented behavior into the implementation. It can explain exactly which setting, precedence rule, loader, or code path produces a behavior and why it works that way. `omp-config` can then make the corresponding profile-aware change and verify it through OMP itself.

Practical examples include:

- Finding the current setting name and valid value before changing a theme, tool, model role, provider, extension, or approval policy.
- Explaining why a project setting overrides a user setting by tracing configuration loading and merge order.
- Diagnosing model, credential, plugin, MCP, or provider behavior from the docs and the code that implements it.
- Checking whether an online answer still applies to the installed OMP version.
- Making a configuration change, then running the exact OMP command that proves the new behavior works.

Example requests:

```text
Configure OMP to use this model for the smol role and verify it.
Why does this project-level setting override my global setting?
Find the current docs and source code for how OMP discovers plugins.
Explain why OMP selected this provider instead of the one I configured.
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
