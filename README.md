# omp-utility-skills

Two portable skills for [Oh My Pi](https://omp.sh):

- **omp-docs** safely initializes or refreshes an upstream OMP source checkout and answers questions from current documentation.
- **omp-config** inspects and changes profile-aware OMP configuration without assuming a username, provider, home directory, or dotfiles system.

## Practical use cases

Put simply, these skills let you ask OMP to configure itself in plain English, the same way you would ask an LLM to update some code, explain an error, or set up a tool. Tell it what you want. It looks up the current way to do it, checks how your OMP setup works today, asks you about anything it cannot figure out, makes the change, and tests it.

That means you do not have to start by searching the web, digging through settings files, or translating docs into YAML or JSON yourself. `omp-docs` refreshes the official OMP repository and reads the docs directly, so it is less likely to follow an old blog post, a partial snippet, or instructions for a different release.

The checkout also includes OMP's source code. When the docs do not tell the whole story, `omp-docs` can follow the real code path and explain which setting, loader, priority rule, or provider made something happen.

### How the two skills differ

| Skill | What it does |
| --- | --- |
| `omp-docs` | Looks things up and explains them. It reads the current docs and source to figure out what OMP supports and why it behaves the way it does. It normally does not change anything. |
| `omp-config` | Does the hands-on work. It looks at your active profile and project, keeps the rest of your setup intact, makes the change you asked for, protects secrets, and checks that it worked. |

They are useful together: `omp-docs` figures out the right answer for the current OMP version, and `omp-config` safely applies that answer to your setup.

### Practical workflows

#### Add an MCP server from GitHub

Paste the MCP server's GitHub URL and ask OMP to add it. The skills can read that project's README alongside OMP's own MCP docs and source, work out whether it uses stdio, HTTP, or SSE, collect the command, arguments, dependencies, and environment variables, and then:

1. Ask you only for details that are actually missing.
2. Put it at project scope or in your active OMP profile.
3. Keep all your existing MCP servers intact.
4. Keep credentials out of tracked JSON.
5. Run `/mcp reload`, `/mcp list`, and `/mcp test <name>` to make sure it really connects.

#### Set up subagents around how you work

Describe the job you want a subagent to handle, such as fast file exploration, code review, security checks, design work, or a slower second opinion. The skills can check the current built-in agent types and custom-agent format, ask about the tradeoffs that matter to you, create a user or project agent definition, set up model routing when needed, and confirm that OMP can see it in `/agents`.

This is also useful when you do not know which subagents you need yet. Ask OMP to walk through your workflow, explain the available agent types in normal language, recommend a small setup, and configure it after you answer a few questions.

#### Change a model or provider

The docs skill checks the current provider id, model syntax, role storage, and credential priority. The config skill changes only the setting or `models.yml` entry you need, then tests the exact model instead of counting a fallback as success.

#### Fix a setting that seems to be ignored

The docs skill checks how user, profile, project, environment, and command-line settings are prioritized. The config skill looks at those real layers on your machine, finds the one that is winning, fixes the right scope, and checks the final value.

#### Tune tools, approvals, themes, plugins, or extensions

The docs skill finds the current options and any implementation limits. The config skill leaves the rest of your configuration alone, makes the smallest useful change, and tries the affected OMP behavior.

#### Check advice before following it

The docs skill can check whether a blog post, issue comment, copied command, or setup guide still matches the current OMP release. If it is out of date, it can show you the current replacement and explain what changed.

Example requests:

- *"Add the MCP server from https://github.com/example/server to this project and test it."*
- *"How can I set up a subagent for fast, read-only file exploration?"*
- *"How do I best use the different types of subagents? Ask me questions and help me set them up."*
- *"Set up a reviewer that uses a stronger model only when I ask for a code review."*
- *"Configure OMP to use this model for the smol role and verify the exact model."*
- *"Why does this project setting override my global setting? Fix it in the right place."*
- *"Find the current docs and source code for how OMP discovers plugins."*
- *"Enable this tool only for this project without changing my global setup."*
- *"Check whether these setup instructions still apply to the current OMP release."*

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
